use magnus::{class, IntoValue, RArray, TryConvert, Value};
use polars::prelude::*;
use polars_core::frame::row::{rows_to_schema_first_non_null, Row};
use polars_core::series::SeriesIter;

use super::*;
use crate::{RbDataFrame, RbPolarsErr, RbSeries, Wrap};

fn get_iters(df: &DataFrame) -> Vec<SeriesIter> {
    df.get_columns().iter().map(|s| s.iter()).collect()
}

fn get_iters_skip(df: &DataFrame, skip: usize) -> Vec<std::iter::Skip<SeriesIter>> {
    df.get_columns()
        .iter()
        .map(|s| s.iter().skip(skip))
        .collect()
}

pub fn apply_lambda_unknown<'a>(
    df: &'a DataFrame,
    lambda: Value,
    inference_size: usize,
) -> RbResult<(Value, bool)> {
    let mut null_count = 0;
    let mut iters = get_iters(df);

    for _ in 0..df.height() {
        let iter = iters.iter_mut().map(|it| Wrap(it.next().unwrap()));
        let arg = (RArray::from_iter(iter),);
        let out: Value = lambda.funcall("call", arg)?;

        if out.is_nil() {
            null_count += 1;
            continue;
        } else if out.is_kind_of(class::true_class()) || out.is_kind_of(class::false_class()) {
            let first_value = out.try_convert::<bool>().ok();
            return Ok((
                RbSeries::new(
                    apply_lambda_with_bool_out_type(df, lambda, null_count, first_value)
                        .into_series(),
                )
                .into(),
                false,
            ));
        } else if out.is_kind_of(class::float()) {
            let first_value = out.try_convert::<f64>().ok();

            return Ok((
                RbSeries::new(
                    apply_lambda_with_primitive_out_type::<Float64Type>(
                        df,
                        lambda,
                        null_count,
                        first_value,
                    )
                    .into_series(),
                )
                .into(),
                false,
            ));
        } else if out.is_kind_of(class::integer()) {
            let first_value = out.try_convert::<i64>().ok();
            return Ok((
                RbSeries::new(
                    apply_lambda_with_primitive_out_type::<Int64Type>(
                        df,
                        lambda,
                        null_count,
                        first_value,
                    )
                    .into_series(),
                )
                .into(),
                false,
            ));
        // } else if out.is_kind_of(class::string()) {
        //     let first_value = out.try_convert::<String>().ok();
        //     return Ok((
        //         RbSeries::new(
        //             apply_lambda_with_utf8_out_type(df, lambda, null_count, first_value)
        //                 .into_series(),
        //         )
        //         .into(),
        //         false,
        //     ));
        } else if out.respond_to("_s", true)? {
            let rb_rbseries: Value = out.funcall("_s", ()).unwrap();
            let series = rb_rbseries
                .try_convert::<&RbSeries>()
                .unwrap()
                .series
                .borrow();
            let dt = series.dtype();
            return Ok((
                RbSeries::new(
                    apply_lambda_with_list_out_type(df, lambda, null_count, Some(&series), dt)?
                        .into_series(),
                )
                .into(),
                false,
            ));
        } else if out.try_convert::<Wrap<Row<'a>>>().is_ok() {
            let first_value = out.try_convert::<Wrap<Row<'a>>>().unwrap().0;
            return Ok((
                RbDataFrame::from(
                    apply_lambda_with_rows_output(
                        df,
                        lambda,
                        null_count,
                        first_value,
                        inference_size,
                    )
                    .map_err(RbPolarsErr::from)?,
                )
                .into(),
                true,
            ));
        } else if out.is_kind_of(class::array()) {
            return Err(RbPolarsErr::other(
                "A list output type is invalid. Do you mean to create polars List Series?\
Then return a Series object."
                    .into(),
            ));
        } else {
            return Err(RbPolarsErr::other("Could not determine output type".into()));
        }
    }
    Err(RbPolarsErr::other("Could not determine output type".into()))
}

fn apply_iter<T>(
    df: &DataFrame,
    lambda: Value,
    init_null_count: usize,
    skip: usize,
) -> impl Iterator<Item = Option<T>> + '_
where
    T: TryConvert,
{
    let mut iters = get_iters_skip(df, init_null_count + skip);
    ((init_null_count + skip)..df.height()).map(move |_| {
        let iter = iters.iter_mut().map(|it| Wrap(it.next().unwrap()));
        let tpl = (RArray::from_iter(iter),);
        match lambda.funcall::<_, _, Value>("call", tpl) {
            Ok(val) => val.try_convert::<T>().ok(),
            Err(e) => panic!("ruby function failed {}", e),
        }
    })
}

/// Apply a lambda with a primitive output type
pub fn apply_lambda_with_primitive_out_type<D>(
    df: &DataFrame,
    lambda: Value,
    init_null_count: usize,
    first_value: Option<D::Native>,
) -> ChunkedArray<D>
where
    D: RbArrowPrimitiveType,
    D::Native: IntoValue + TryConvert,
{
    let skip = usize::from(first_value.is_some());
    if init_null_count == df.height() {
        ChunkedArray::full_null("apply", df.height())
    } else {
        let iter = apply_iter(df, lambda, init_null_count, skip);
        iterator_to_primitive(iter, init_null_count, first_value, "apply", df.height())
    }
}

/// Apply a lambda with a boolean output type
pub fn apply_lambda_with_bool_out_type(
    df: &DataFrame,
    lambda: Value,
    init_null_count: usize,
    first_value: Option<bool>,
) -> ChunkedArray<BooleanType> {
    let skip = usize::from(first_value.is_some());
    if init_null_count == df.height() {
        ChunkedArray::full_null("apply", df.height())
    } else {
        let iter = apply_iter(df, lambda, init_null_count, skip);
        iterator_to_bool(iter, init_null_count, first_value, "apply", df.height())
    }
}

/// Apply a lambda with utf8 output type
pub fn apply_lambda_with_utf8_out_type(
    df: &DataFrame,
    lambda: Value,
    init_null_count: usize,
    first_value: Option<&str>,
) -> Utf8Chunked {
    let skip = usize::from(first_value.is_some());
    if init_null_count == df.height() {
        ChunkedArray::full_null("apply", df.height())
    } else {
        let iter = apply_iter::<String>(df, lambda, init_null_count, skip);
        iterator_to_utf8(iter, init_null_count, first_value, "apply", df.height())
    }
}

/// Apply a lambda with list output type
pub fn apply_lambda_with_list_out_type(
    df: &DataFrame,
    lambda: Value,
    init_null_count: usize,
    first_value: Option<&Series>,
    dt: &DataType,
) -> RbResult<ListChunked> {
    let skip = usize::from(first_value.is_some());
    if init_null_count == df.height() {
        Ok(ChunkedArray::full_null("apply", df.height()))
    } else {
        let mut iters = get_iters_skip(df, init_null_count + skip);
        let iter = ((init_null_count + skip)..df.height()).map(|_| {
            let iter = iters.iter_mut().map(|it| Wrap(it.next().unwrap()));
            let tpl = (RArray::from_iter(iter),);
            match lambda.funcall::<_, _, Value>("call", tpl) {
                Ok(val) => match val.funcall::<_, _, Value>("_s", ()) {
                    Ok(val) => val
                        .try_convert::<&RbSeries>()
                        .ok()
                        .map(|ps| ps.series.borrow().clone()),
                    Err(_) => {
                        if val.is_nil() {
                            None
                        } else {
                            panic!("should return a Series, got a {:?}", val)
                        }
                    }
                },
                Err(e) => panic!("ruby function failed {}", e),
            }
        });
        iterator_to_list(dt, iter, init_null_count, first_value, "apply", df.height())
    }
}

pub fn apply_lambda_with_rows_output<'a>(
    df: &'a DataFrame,
    lambda: Value,
    init_null_count: usize,
    first_value: Row<'a>,
    inference_size: usize,
) -> PolarsResult<DataFrame> {
    let width = first_value.0.len();
    let null_row = Row::new(vec![AnyValue::Null; width]);

    let mut row_buf = Row::default();

    let skip = 1;
    let mut iters = get_iters_skip(df, init_null_count + skip);
    let mut row_iter = ((init_null_count + skip)..df.height()).map(|_| {
        let iter = iters.iter_mut().map(|it| Wrap(it.next().unwrap()));
        let tpl = (RArray::from_iter(iter),);
        match lambda.funcall::<_, _, Value>("call", tpl) {
            Ok(val) => {
                match val.try_convert::<RArray>().ok() {
                    Some(tuple) => {
                        row_buf.0.clear();
                        for v in tuple.each() {
                            let v = v.unwrap().try_convert::<Wrap<AnyValue>>().unwrap().0;
                            row_buf.0.push(v);
                        }
                        let ptr = &row_buf as *const Row;
                        // Safety:
                        // we know that row constructor of polars dataframe does not keep a reference
                        // to the row. Before we mutate the row buf again, the reference is dropped.
                        // we only cannot prove it to the compiler.
                        // we still do this because it saves a Vec allocation in a hot loop.
                        unsafe { &*ptr }
                    }
                    None => &null_row,
                }
            }
            Err(e) => panic!("ruby function failed {}", e),
        }
    });

    // first rows for schema inference
    let mut buf = Vec::with_capacity(inference_size);
    buf.push(first_value);
    buf.extend((&mut row_iter).take(inference_size).cloned());
    let schema = rows_to_schema_first_non_null(&buf, Some(50));

    if init_null_count > 0 {
        // Safety: we know the iterators size
        let iter = unsafe {
            (0..init_null_count)
                .map(|_| &null_row)
                .chain(buf.iter())
                .chain(row_iter)
                .trust_my_length(df.height())
        };
        DataFrame::from_rows_iter_and_schema(iter, &schema)
    } else {
        // Safety: we know the iterators size
        let iter = unsafe { buf.iter().chain(row_iter).trust_my_length(df.height()) };
        DataFrame::from_rows_iter_and_schema(iter, &schema)
    }
}

module Polars
  # Namespace for string related expressions.
  class StringExpr
    # @private
    attr_accessor :_rbexpr

    # @private
    def initialize(expr)
      self._rbexpr = expr._rbexpr
    end

    # Convert a Utf8 column into a Date column.
    #
    # @param format [String]
    #   Format to use for conversion. Refer to the
    #   [chrono crate documentation](https://docs.rs/chrono/latest/chrono/format/strftime/index.html)
    #   for the full specification. Example: `"%Y-%m-%d"`.
    #   If set to nil (default), the format is inferred from the data.
    # @param strict [Boolean]
    #   Raise an error if any conversion fails.
    # @param exact [Boolean]
    #   Require an exact format match. If false, allow the format to match anywhere
    #   in the target string.
    # @param cache [Boolean]
    #   Use a cache of unique, converted dates to apply the conversion.
    #
    # @return [Expr]
    #
    # @example
    #   s = Polars::Series.new(["2020/01/01", "2020/02/01", "2020/03/01"])
    #   s.str.to_date
    #   # =>
    #   # shape: (3,)
    #   # Series: '' [date]
    #   # [
    #   #         2020-01-01
    #   #         2020-02-01
    #   #         2020-03-01
    #   # ]
    def to_date(format = nil, strict: true, exact: true, cache: true)
      _validate_format_argument(format)
      Utils.wrap_expr(self._rbexpr.str_to_date(format, strict, exact, cache))
    end

    # Convert a Utf8 column into a Datetime column.
    #
    # @param format [String]
    #   Format to use for conversion. Refer to the
    #   [chrono crate documentation](https://docs.rs/chrono/latest/chrono/format/strftime/index.html)
    #   for the full specification. Example: `"%Y-%m-%d %H:%M:%S"`.
    #   If set to nil (default), the format is inferred from the data.
    # @param time_unit ["us", "ns", "ms"]
    #   Unit of time for the resulting Datetime column. If set to nil (default),
    #   the time unit is inferred from the format string if given, eg:
    #   `"%F %T%.3f"` => `Datetime("ms")`. If no fractional second component is
    #   found, the default is `"us"`.
    # @param time_zone [String]
    #   Time zone for the resulting Datetime column.
    # @param strict [Boolean]
    #   Raise an error if any conversion fails.
    # @param exact [Boolean]
    #   Require an exact format match. If false, allow the format to match anywhere
    #   in the target string.
    # @param cache [Boolean]
    #   Use a cache of unique, converted datetimes to apply the conversion.
    #
    # @return [Expr]
    #
    # @example
    #   s = Polars::Series.new(["2020-01-01 01:00Z", "2020-01-01 02:00Z"])
    #   s.str.to_datetime("%Y-%m-%d %H:%M%#z")
    #   # =>
    #   # shape: (2,)
    #   # Series: '' [datetime[μs, UTC]]
    #   # [
    #   #         2020-01-01 01:00:00 UTC
    #   #         2020-01-01 02:00:00 UTC
    #   # ]
    def to_datetime(
      format = nil,
      time_unit: nil,
      time_zone: nil,
      strict: true,
      exact: true,
      cache: true
    )
      _validate_format_argument(format)
      Utils.wrap_expr(
        self._rbexpr.str_to_datetime(
          format,
          time_unit,
          time_zone,
          strict,
          exact,
          cache
        )
      )
    end

    # Convert a Utf8 column into a Time column.
    #
    # @param format [String]
    #   Format to use for conversion. Refer to the
    #   [chrono crate documentation](https://docs.rs/chrono/latest/chrono/format/strftime/index.html)
    #   for the full specification. Example: `"%H:%M:%S"`.
    #   If set to nil (default), the format is inferred from the data.
    # @param strict [Boolean]
    #   Raise an error if any conversion fails.
    # @param cache [Boolean]
    #   Use a cache of unique, converted times to apply the conversion.
    #
    # @return [Expr]
    #
    # @example
    #   s = Polars::Series.new(["01:00", "02:00", "03:00"])
    #   s.str.to_time("%H:%M")
    #   # =>
    #   # shape: (3,)
    #   # Series: '' [time]
    #   # [
    #   #         01:00:00
    #   #         02:00:00
    #   #         03:00:00
    #   # ]
    def to_time(format = nil, strict: true, cache: true)
      _validate_format_argument(format)
      Utils.wrap_expr(_rbexpr.str_to_time(format, strict, cache))
    end

    # Parse a Utf8 expression to a Date/Datetime/Time type.
    #
    # @param dtype [Object]
    #   The data type to convert into. Can be either Date, Datetime, or Time.
    # @param format [String]
    #   Format to use, refer to the
    #   [chrono strftime documentation](https://docs.rs/chrono/latest/chrono/format/strftime/index.html)
    #   for specification. Example: `"%y-%m-%d"`.
    # @param strict [Boolean]
    #   Raise an error if any conversion fails.
    # @param exact [Boolean]
    #   - If true, require an exact format match.
    #   - If false, allow the format to match anywhere in the target string.
    # @param utc [Boolean]
    #   Parse timezone aware datetimes as UTC. This may be useful if you have data
    #   with mixed offsets.
    #
    # @return [Expr]
    #
    # @note
    #   When parsing a Datetime the column precision will be inferred from
    #   the format string, if given, eg: "%F %T%.3f" => Datetime("ms"). If
    #   no fractional second component is found then the default is "us".
    #
    # @example Dealing with a consistent format:
    #   s = Polars::Series.new(["2020-01-01 01:00Z", "2020-01-01 02:00Z"])
    #   s.str.strptime(Polars::Datetime, "%Y-%m-%d %H:%M%#z")
    #   # =>
    #   # shape: (2,)
    #   # Series: '' [datetime[μs, UTC]]
    #   # [
    #   #         2020-01-01 01:00:00 UTC
    #   #         2020-01-01 02:00:00 UTC
    #   # ]
    #
    # @example Dealing with different formats.
    #   s = Polars::Series.new(
    #     "date",
    #     [
    #       "2021-04-22",
    #       "2022-01-04 00:00:00",
    #       "01/31/22",
    #       "Sun Jul  8 00:34:60 2001",
    #     ]
    #   )
    #   s.to_frame.select(
    #     Polars.coalesce(
    #       Polars.col("date").str.strptime(Polars::Date, "%F", strict: false),
    #       Polars.col("date").str.strptime(Polars::Date, "%F %T", strict: false),
    #       Polars.col("date").str.strptime(Polars::Date, "%D", strict: false),
    #       Polars.col("date").str.strptime(Polars::Date, "%c", strict: false)
    #     )
    #   ).to_series
    #   # =>
    #   # shape: (4,)
    #   # Series: 'date' [date]
    #   # [
    #   #         2021-04-22
    #   #         2022-01-04
    #   #         2022-01-31
    #   #         2001-07-08
    #   # ]
    def strptime(dtype, format = nil, strict: true, exact: true, cache: true, utc: false)
      _validate_format_argument(format)

      if dtype == Date
        to_date(format, strict: strict, exact: exact, cache: cache)
      elsif dtype == Datetime || dtype.is_a?(Datetime)
        dtype = Datetime.new if dtype == Datetime
        time_unit = dtype.time_unit
        time_zone = dtype.time_zone
        to_datetime(format, time_unit: time_unit, time_zone: time_zone, strict: strict, exact: exact, cache: cache)
      elsif dtype == Time
        to_time(format, strict: strict, cache: cache)
      else
        raise ArgumentError, "dtype should be of type {Date, Datetime, Time}"
      end
    end

    # Get length of the strings as `:u32` (as number of bytes).
    #
    # @return [Expr]
    #
    # @note
    #   The returned lengths are equal to the number of bytes in the UTF8 string. If you
    #   need the length in terms of the number of characters, use `n_chars` instead.
    #
    # @example
    #   df = Polars::DataFrame.new({"s" => ["Café", nil, "345", "東京"]}).with_columns(
    #     [
    #       Polars.col("s").str.lengths.alias("length"),
    #       Polars.col("s").str.n_chars.alias("nchars")
    #     ]
    #   )
    #   df
    #   # =>
    #   # shape: (4, 3)
    #   # ┌──────┬────────┬────────┐
    #   # │ s    ┆ length ┆ nchars │
    #   # │ ---  ┆ ---    ┆ ---    │
    #   # │ str  ┆ u32    ┆ u32    │
    #   # ╞══════╪════════╪════════╡
    #   # │ Café ┆ 5      ┆ 4      │
    #   # │ null ┆ null   ┆ null   │
    #   # │ 345  ┆ 3      ┆ 3      │
    #   # │ 東京 ┆ 6      ┆ 2      │
    #   # └──────┴────────┴────────┘
    def lengths
      Utils.wrap_expr(_rbexpr.str_lengths)
    end

    # Get length of the strings as `:u32` (as number of chars).
    #
    # @return [Expr]
    #
    # @note
    #   If you know that you are working with ASCII text, `lengths` will be
    #   equivalent, and faster (returns length in terms of the number of bytes).
    #
    # @example
    #   df = Polars::DataFrame.new({"s" => ["Café", nil, "345", "東京"]}).with_columns(
    #     [
    #       Polars.col("s").str.lengths.alias("length"),
    #       Polars.col("s").str.n_chars.alias("nchars")
    #     ]
    #   )
    #   df
    #   # =>
    #   # shape: (4, 3)
    #   # ┌──────┬────────┬────────┐
    #   # │ s    ┆ length ┆ nchars │
    #   # │ ---  ┆ ---    ┆ ---    │
    #   # │ str  ┆ u32    ┆ u32    │
    #   # ╞══════╪════════╪════════╡
    #   # │ Café ┆ 5      ┆ 4      │
    #   # │ null ┆ null   ┆ null   │
    #   # │ 345  ┆ 3      ┆ 3      │
    #   # │ 東京 ┆ 6      ┆ 2      │
    #   # └──────┴────────┴────────┘
    def n_chars
      Utils.wrap_expr(_rbexpr.str_n_chars)
    end

    # Vertically concat the values in the Series to a single string value.
    #
    # @param delimiter [String]
    #   The delimiter to insert between consecutive string values.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => [1, nil, 2]})
    #   df.select(Polars.col("foo").str.concat("-"))
    #   # =>
    #   # shape: (1, 1)
    #   # ┌──────────┐
    #   # │ foo      │
    #   # │ ---      │
    #   # │ str      │
    #   # ╞══════════╡
    #   # │ 1-null-2 │
    #   # └──────────┘
    def concat(delimiter = "-")
      Utils.wrap_expr(_rbexpr.str_concat(delimiter))
    end

    # Transform to uppercase variant.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => ["cat", "dog"]})
    #   df.select(Polars.col("foo").str.to_uppercase)
    #   # =>
    #   # shape: (2, 1)
    #   # ┌─────┐
    #   # │ foo │
    #   # │ --- │
    #   # │ str │
    #   # ╞═════╡
    #   # │ CAT │
    #   # │ DOG │
    #   # └─────┘
    def to_uppercase
      Utils.wrap_expr(_rbexpr.str_to_uppercase)
    end

    # Transform to lowercase variant.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => ["CAT", "DOG"]})
    #   df.select(Polars.col("foo").str.to_lowercase)
    #   # =>
    #   # shape: (2, 1)
    #   # ┌─────┐
    #   # │ foo │
    #   # │ --- │
    #   # │ str │
    #   # ╞═════╡
    #   # │ cat │
    #   # │ dog │
    #   # └─────┘
    def to_lowercase
      Utils.wrap_expr(_rbexpr.str_to_lowercase)
    end

    # Remove leading and trailing whitespace.
    #
    # @param matches [String, nil]
    #   An optional single character that should be trimmed.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => [" lead", "trail ", " both "]})
    #   df.select(Polars.col("foo").str.strip)
    #   # =>
    #   # shape: (3, 1)
    #   # ┌───────┐
    #   # │ foo   │
    #   # │ ---   │
    #   # │ str   │
    #   # ╞═══════╡
    #   # │ lead  │
    #   # │ trail │
    #   # │ both  │
    #   # └───────┘
    def strip(matches = nil)
      if !matches.nil? && matches.length > 1
        raise ArgumentError, "matches should contain a single character"
      end
      Utils.wrap_expr(_rbexpr.str_strip(matches))
    end

    # Remove leading whitespace.
    #
    # @param matches [String, nil]
    #   An optional single character that should be trimmed.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => [" lead", "trail ", " both "]})
    #   df.select(Polars.col("foo").str.lstrip)
    #   # =>
    #   # shape: (3, 1)
    #   # ┌────────┐
    #   # │ foo    │
    #   # │ ---    │
    #   # │ str    │
    #   # ╞════════╡
    #   # │ lead   │
    #   # │ trail  │
    #   # │ both   │
    #   # └────────┘
    def lstrip(matches = nil)
      if !matches.nil? && matches.length > 1
        raise ArgumentError, "matches should contain a single character"
      end
      Utils.wrap_expr(_rbexpr.str_lstrip(matches))
    end

    # Remove trailing whitespace.
    #
    # @param matches [String, nil]
    #   An optional single character that should be trimmed.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => [" lead", "trail ", " both "]})
    #   df.select(Polars.col("foo").str.rstrip)
    #   # =>
    #   # shape: (3, 1)
    #   # ┌───────┐
    #   # │ foo   │
    #   # │ ---   │
    #   # │ str   │
    #   # ╞═══════╡
    #   # │  lead │
    #   # │ trail │
    #   # │  both │
    #   # └───────┘
    def rstrip(matches = nil)
      if !matches.nil? && matches.length > 1
        raise ArgumentError, "matches should contain a single character"
      end
      Utils.wrap_expr(_rbexpr.str_rstrip(matches))
    end

    # Fills the string with zeroes.
    #
    # Return a copy of the string left filled with ASCII '0' digits to make a string
    # of length width.
    #
    # A leading sign prefix ('+'/'-') is handled by inserting the padding after the
    # sign character rather than before. The original string is returned if width is
    # less than or equal to `s.length`.
    #
    # @param alignment [Integer]
    #   Fill the value up to this length
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new(
    #     {
    #       "num" => [-10, -1, 0, 1, 10, 100, 1000, 10000, 100000, 1000000, nil]
    #     }
    #   )
    #   df.with_column(Polars.col("num").cast(String).str.zfill(5))
    #   # =>
    #   # shape: (11, 1)
    #   # ┌─────────┐
    #   # │ num     │
    #   # │ ---     │
    #   # │ str     │
    #   # ╞═════════╡
    #   # │ -0010   │
    #   # │ -0001   │
    #   # │ 00000   │
    #   # │ 00001   │
    #   # │ …       │
    #   # │ 10000   │
    #   # │ 100000  │
    #   # │ 1000000 │
    #   # │ null    │
    #   # └─────────┘
    def zfill(alignment)
      Utils.wrap_expr(_rbexpr.str_zfill(alignment))
    end

    # Return the string left justified in a string of length `width`.
    #
    # Padding is done using the specified `fillchar`.
    # The original string is returned if `width` is less than or equal to
    # `s.length`.
    #
    # @param width [Integer]
    #   Justify left to this length.
    # @param fillchar [String]
    #   Fill with this ASCII character.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"a" => ["cow", "monkey", nil, "hippopotamus"]})
    #   df.select(Polars.col("a").str.ljust(8, "*"))
    #   # =>
    #   # shape: (4, 1)
    #   # ┌──────────────┐
    #   # │ a            │
    #   # │ ---          │
    #   # │ str          │
    #   # ╞══════════════╡
    #   # │ cow*****     │
    #   # │ monkey**     │
    #   # │ null         │
    #   # │ hippopotamus │
    #   # └──────────────┘
    def ljust(width, fillchar = " ")
      Utils.wrap_expr(_rbexpr.str_ljust(width, fillchar))
    end

    # Return the string right justified in a string of length `width`.
    #
    # Padding is done using the specified `fillchar`.
    # The original string is returned if `width` is less than or equal to
    # `s.length`.
    #
    # @param width [Integer]
    #   Justify right to this length.
    # @param fillchar [String]
    #   Fill with this ASCII character.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"a" => ["cow", "monkey", nil, "hippopotamus"]})
    #   df.select(Polars.col("a").str.rjust(8, "*"))
    #   # =>
    #   # shape: (4, 1)
    #   # ┌──────────────┐
    #   # │ a            │
    #   # │ ---          │
    #   # │ str          │
    #   # ╞══════════════╡
    #   # │ *****cow     │
    #   # │ **monkey     │
    #   # │ null         │
    #   # │ hippopotamus │
    #   # └──────────────┘
    def rjust(width, fillchar = " ")
      Utils.wrap_expr(_rbexpr.str_rjust(width, fillchar))
    end

    # Check if string contains a substring that matches a regex.
    #
    # @param pattern [String]
    #   A valid regex pattern.
    # @param literal [Boolean]
    #   Treat pattern as a literal string.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"a" => ["Crab", "cat and dog", "rab$bit", nil]})
    #   df.select(
    #     [
    #       Polars.col("a"),
    #       Polars.col("a").str.contains("cat|bit").alias("regex"),
    #       Polars.col("a").str.contains("rab$", literal: true).alias("literal")
    #     ]
    #   )
    #   # =>
    #   # shape: (4, 3)
    #   # ┌─────────────┬───────┬─────────┐
    #   # │ a           ┆ regex ┆ literal │
    #   # │ ---         ┆ ---   ┆ ---     │
    #   # │ str         ┆ bool  ┆ bool    │
    #   # ╞═════════════╪═══════╪═════════╡
    #   # │ Crab        ┆ false ┆ false   │
    #   # │ cat and dog ┆ true  ┆ false   │
    #   # │ rab$bit     ┆ true  ┆ true    │
    #   # │ null        ┆ null  ┆ null    │
    #   # └─────────────┴───────┴─────────┘
    def contains(pattern, literal: false, strict: true)
      pattern = Utils.expr_to_lit_or_expr(pattern, str_to_lit: true)._rbexpr
      Utils.wrap_expr(_rbexpr.str_contains(pattern, literal, strict))
    end

    # Check if string values end with a substring.
    #
    # @param sub [String]
    #   Suffix substring.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"fruits" => ["apple", "mango", nil]})
    #   df.with_column(
    #     Polars.col("fruits").str.ends_with("go").alias("has_suffix")
    #   )
    #   # =>
    #   # shape: (3, 2)
    #   # ┌────────┬────────────┐
    #   # │ fruits ┆ has_suffix │
    #   # │ ---    ┆ ---        │
    #   # │ str    ┆ bool       │
    #   # ╞════════╪════════════╡
    #   # │ apple  ┆ false      │
    #   # │ mango  ┆ true       │
    #   # │ null   ┆ null       │
    #   # └────────┴────────────┘
    #
    # @example Using `ends_with` as a filter condition:
    #   df.filter(Polars.col("fruits").str.ends_with("go"))
    #   # =>
    #   # shape: (1, 1)
    #   # ┌────────┐
    #   # │ fruits │
    #   # │ ---    │
    #   # │ str    │
    #   # ╞════════╡
    #   # │ mango  │
    #   # └────────┘
    def ends_with(sub)
      sub = Utils.expr_to_lit_or_expr(sub, str_to_lit: true)._rbexpr
      Utils.wrap_expr(_rbexpr.str_ends_with(sub))
    end

    # Check if string values start with a substring.
    #
    # @param sub [String]
    #   Prefix substring.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"fruits" => ["apple", "mango", nil]})
    #   df.with_column(
    #     Polars.col("fruits").str.starts_with("app").alias("has_prefix")
    #   )
    #   # =>
    #   # shape: (3, 2)
    #   # ┌────────┬────────────┐
    #   # │ fruits ┆ has_prefix │
    #   # │ ---    ┆ ---        │
    #   # │ str    ┆ bool       │
    #   # ╞════════╪════════════╡
    #   # │ apple  ┆ true       │
    #   # │ mango  ┆ false      │
    #   # │ null   ┆ null       │
    #   # └────────┴────────────┘
    #
    # @example Using `starts_with` as a filter condition:
    #   df.filter(Polars.col("fruits").str.starts_with("app"))
    #   # =>
    #   # shape: (1, 1)
    #   # ┌────────┐
    #   # │ fruits │
    #   # │ ---    │
    #   # │ str    │
    #   # ╞════════╡
    #   # │ apple  │
    #   # └────────┘
    def starts_with(sub)
      sub = Utils.expr_to_lit_or_expr(sub, str_to_lit: true)._rbexpr
      Utils.wrap_expr(_rbexpr.str_starts_with(sub))
    end

    # Parse string values as JSON.
    #
    # Throw errors if encounter invalid JSON strings.
    #
    # @param dtype [Object]
    #   The dtype to cast the extracted value to. If nil, the dtype will be
    #   inferred from the JSON value.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new(
    #     {"json" => ['{"a":1, "b": true}', nil, '{"a":2, "b": false}']}
    #   )
    #   dtype = Polars::Struct.new([Polars::Field.new("a", Polars::Int64), Polars::Field.new("b", Polars::Boolean)])
    #   df.select(Polars.col("json").str.json_extract(dtype))
    #   # =>
    #   # shape: (3, 1)
    #   # ┌─────────────┐
    #   # │ json        │
    #   # │ ---         │
    #   # │ struct[2]   │
    #   # ╞═════════════╡
    #   # │ {1,true}    │
    #   # │ {null,null} │
    #   # │ {2,false}   │
    #   # └─────────────┘
    def json_extract(dtype = nil)
      if !dtype.nil?
        dtype = Utils.rb_type_to_dtype(dtype)
      end
      Utils.wrap_expr(_rbexpr.str_json_extract(dtype))
    end

    # Extract the first match of json string with provided JSONPath expression.
    #
    # Throw errors if encounter invalid json strings.
    # All return value will be casted to Utf8 regardless of the original value.
    #
    # Documentation on JSONPath standard can be found
    # [here](https://goessner.net/articles/JsonPath/).
    #
    # @param json_path [String]
    #   A valid JSON path query string.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new(
    #     {"json_val" => ['{"a":"1"}', nil, '{"a":2}', '{"a":2.1}', '{"a":true}']}
    #   )
    #   df.select(Polars.col("json_val").str.json_path_match("$.a"))
    #   # =>
    #   # shape: (5, 1)
    #   # ┌──────────┐
    #   # │ json_val │
    #   # │ ---      │
    #   # │ str      │
    #   # ╞══════════╡
    #   # │ 1        │
    #   # │ null     │
    #   # │ 2        │
    #   # │ 2.1      │
    #   # │ true     │
    #   # └──────────┘
    def json_path_match(json_path)
      Utils.wrap_expr(_rbexpr.str_json_path_match(json_path))
    end

    # Decode a value using the provided encoding.
    #
    # @param encoding ["hex", "base64"]
    #   The encoding to use.
    # @param strict [Boolean]
    #   How to handle invalid inputs:
    #
    #   - `true`: An error will be thrown if unable to decode a value.
    #   - `false`: Unhandled values will be replaced with `nil`.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"encoded" => ["666f6f", "626172", nil]})
    #   df.select(Polars.col("encoded").str.decode("hex"))
    #   # =>
    #   # shape: (3, 1)
    #   # ┌───────────────┐
    #   # │ encoded       │
    #   # │ ---           │
    #   # │ binary        │
    #   # ╞═══════════════╡
    #   # │ [binary data] │
    #   # │ [binary data] │
    #   # │ null          │
    #   # └───────────────┘
    def decode(encoding, strict: true)
      if encoding == "hex"
        Utils.wrap_expr(_rbexpr.str_hex_decode(strict))
      elsif encoding == "base64"
        Utils.wrap_expr(_rbexpr.str_base64_decode(strict))
      else
        raise ArgumentError, "encoding must be one of {{'hex', 'base64'}}, got #{encoding}"
      end
    end

    # Encode a value using the provided encoding.
    #
    # @param encoding ["hex", "base64"]
    #   The encoding to use.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"strings" => ["foo", "bar", nil]})
    #   df.select(Polars.col("strings").str.encode("hex"))
    #   # =>
    #   # shape: (3, 1)
    #   # ┌─────────┐
    #   # │ strings │
    #   # │ ---     │
    #   # │ str     │
    #   # ╞═════════╡
    #   # │ 666f6f  │
    #   # │ 626172  │
    #   # │ null    │
    #   # └─────────┘
    def encode(encoding)
      if encoding == "hex"
        Utils.wrap_expr(_rbexpr.str_hex_encode)
      elsif encoding == "base64"
        Utils.wrap_expr(_rbexpr.str_base64_encode)
      else
        raise ArgumentError, "encoding must be one of {{'hex', 'base64'}}, got #{encoding}"
      end
    end

    # Extract the target capture group from provided patterns.
    #
    # @param pattern [String]
    #   A valid regex pattern
    # @param group_index [Integer]
    #   Index of the targeted capture group.
    #   Group 0 mean the whole pattern, first group begin at index 1
    #   Default to the first capture group
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => ["123 bla 45 asd", "xyz 678 910t"]})
    #   df.select(
    #     [
    #       Polars.col("foo").str.extract('(\d+)')
    #     ]
    #   )
    #   # =>
    #   # shape: (2, 1)
    #   # ┌─────┐
    #   # │ foo │
    #   # │ --- │
    #   # │ str │
    #   # ╞═════╡
    #   # │ 123 │
    #   # │ 678 │
    #   # └─────┘
    def extract(pattern, group_index: 1)
      Utils.wrap_expr(_rbexpr.str_extract(pattern, group_index))
    end

    # Extracts all matches for the given regex pattern.
    #
    # Extracts each successive non-overlapping regex match in an individual string as
    # an array.
    #
    # @param pattern [String]
    #   A valid regex pattern
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => ["123 bla 45 asd", "xyz 678 910t"]})
    #   df.select(
    #     [
    #       Polars.col("foo").str.extract_all('(\d+)').alias("extracted_nrs")
    #     ]
    #   )
    #   # =>
    #   # shape: (2, 1)
    #   # ┌────────────────┐
    #   # │ extracted_nrs  │
    #   # │ ---            │
    #   # │ list[str]      │
    #   # ╞════════════════╡
    #   # │ ["123", "45"]  │
    #   # │ ["678", "910"] │
    #   # └────────────────┘
    def extract_all(pattern)
      pattern = Utils.expr_to_lit_or_expr(pattern, str_to_lit: true)
      Utils.wrap_expr(_rbexpr.str_extract_all(pattern._rbexpr))
    end

    # Count all successive non-overlapping regex matches.
    #
    # @param pattern [String]
    #   A valid regex pattern
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"foo" => ["123 bla 45 asd", "xyz 678 910t"]})
    #   df.select(
    #     [
    #       Polars.col("foo").str.count_match('\d').alias("count_digits")
    #     ]
    #   )
    #   # =>
    #   # shape: (2, 1)
    #   # ┌──────────────┐
    #   # │ count_digits │
    #   # │ ---          │
    #   # │ u32          │
    #   # ╞══════════════╡
    #   # │ 5            │
    #   # │ 6            │
    #   # └──────────────┘
    def count_match(pattern)
      Utils.wrap_expr(_rbexpr.count_match(pattern))
    end

    # Split the string by a substring.
    #
    # @param by [String]
    #   Substring to split by.
    # @param inclusive [Boolean]
    #   If true, include the split character/string in the results.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"s" => ["foo bar", "foo-bar", "foo bar baz"]})
    #   df.select(Polars.col("s").str.split(" "))
    #   # =>
    #   # shape: (3, 1)
    #   # ┌───────────────────────┐
    #   # │ s                     │
    #   # │ ---                   │
    #   # │ list[str]             │
    #   # ╞═══════════════════════╡
    #   # │ ["foo", "bar"]        │
    #   # │ ["foo-bar"]           │
    #   # │ ["foo", "bar", "baz"] │
    #   # └───────────────────────┘
    def split(by, inclusive: false)
      if inclusive
        Utils.wrap_expr(_rbexpr.str_split_inclusive(by))
      else
        Utils.wrap_expr(_rbexpr.str_split(by))
      end
    end

    # Split the string by a substring using `n` splits.
    #
    # Results in a struct of `n+1` fields.
    #
    # If it cannot make `n` splits, the remaining field elements will be null.
    #
    # @param by [String]
    #   Substring to split by.
    # @param n [Integer]
    #   Number of splits to make.
    # @param inclusive [Boolean]
    #   If true, include the split character/string in the results.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"x" => ["a_1", nil, "c", "d_4"]})
    #   df.select(
    #     [
    #       Polars.col("x").str.split_exact("_", 1).alias("fields")
    #     ]
    #   )
    #   # =>
    #   # shape: (4, 1)
    #   # ┌─────────────┐
    #   # │ fields      │
    #   # │ ---         │
    #   # │ struct[2]   │
    #   # ╞═════════════╡
    #   # │ {"a","1"}   │
    #   # │ {null,null} │
    #   # │ {"c",null}  │
    #   # │ {"d","4"}   │
    #   # └─────────────┘
    def split_exact(by, n, inclusive: false)
      if inclusive
        Utils.wrap_expr(_rbexpr.str_split_exact_inclusive(by, n))
      else
        Utils.wrap_expr(_rbexpr.str_split_exact(by, n))
      end
    end

    # Split the string by a substring, restricted to returning at most `n` items.
    #
    # If the number of possible splits is less than `n-1`, the remaining field
    # elements will be null. If the number of possible splits is `n-1` or greater,
    # the last (nth) substring will contain the remainder of the string.
    #
    # @param by [String]
    #   Substring to split by.
    # @param n [Integer]
    #   Max number of items to return.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"s" => ["foo bar", nil, "foo-bar", "foo bar baz"]})
    #   df.select(Polars.col("s").str.splitn(" ", 2).alias("fields"))
    #   # =>
    #   # shape: (4, 1)
    #   # ┌───────────────────┐
    #   # │ fields            │
    #   # │ ---               │
    #   # │ struct[2]         │
    #   # ╞═══════════════════╡
    #   # │ {"foo","bar"}     │
    #   # │ {null,null}       │
    #   # │ {"foo-bar",null}  │
    #   # │ {"foo","bar baz"} │
    #   # └───────────────────┘
    def splitn(by, n)
      Utils.wrap_expr(_rbexpr.str_splitn(by, n))
    end

    # Replace first matching regex/literal substring with a new string value.
    #
    # @param pattern [String]
    #   Regex pattern.
    # @param value [String]
    #   Replacement string.
    # @param literal [Boolean]
    #   Treat pattern as a literal string.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"id" => [1, 2], "text" => ["123abc", "abc456"]})
    #   df.with_column(
    #     Polars.col("text").str.replace('abc\b', "ABC")
    #   )
    #   # =>
    #   # shape: (2, 2)
    #   # ┌─────┬────────┐
    #   # │ id  ┆ text   │
    #   # │ --- ┆ ---    │
    #   # │ i64 ┆ str    │
    #   # ╞═════╪════════╡
    #   # │ 1   ┆ 123ABC │
    #   # │ 2   ┆ abc456 │
    #   # └─────┴────────┘
    def replace(pattern, value, literal: false, n: 1)
      pattern = Utils.expr_to_lit_or_expr(pattern, str_to_lit: true)
      value = Utils.expr_to_lit_or_expr(value, str_to_lit: true)
      Utils.wrap_expr(_rbexpr.str_replace_n(pattern._rbexpr, value._rbexpr, literal, n))
    end

    # Replace all matching regex/literal substrings with a new string value.
    #
    # @param pattern [String]
    #   Regex pattern.
    # @param value [String]
    #   Replacement string.
    # @param literal [Boolean]
    #   Treat pattern as a literal string.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"id" => [1, 2], "text" => ["abcabc", "123a123"]})
    #   df.with_column(Polars.col("text").str.replace_all("a", "-"))
    #   # =>
    #   # shape: (2, 2)
    #   # ┌─────┬─────────┐
    #   # │ id  ┆ text    │
    #   # │ --- ┆ ---     │
    #   # │ i64 ┆ str     │
    #   # ╞═════╪═════════╡
    #   # │ 1   ┆ -bc-bc  │
    #   # │ 2   ┆ 123-123 │
    #   # └─────┴─────────┘
    def replace_all(pattern, value, literal: false)
      pattern = Utils.expr_to_lit_or_expr(pattern, str_to_lit: true)
      value = Utils.expr_to_lit_or_expr(value, str_to_lit: true)
      Utils.wrap_expr(_rbexpr.str_replace_all(pattern._rbexpr, value._rbexpr, literal))
    end

    # Create subslices of the string values of a Utf8 Series.
    #
    # @param offset [Integer]
    #   Start index. Negative indexing is supported.
    # @param length [Integer]
    #   Length of the slice. If set to `nil` (default), the slice is taken to the
    #   end of the string.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"s" => ["pear", nil, "papaya", "dragonfruit"]})
    #   df.with_column(
    #     Polars.col("s").str.slice(-3).alias("s_sliced")
    #   )
    #   # =>
    #   # shape: (4, 2)
    #   # ┌─────────────┬──────────┐
    #   # │ s           ┆ s_sliced │
    #   # │ ---         ┆ ---      │
    #   # │ str         ┆ str      │
    #   # ╞═════════════╪══════════╡
    #   # │ pear        ┆ ear      │
    #   # │ null        ┆ null     │
    #   # │ papaya      ┆ aya      │
    #   # │ dragonfruit ┆ uit      │
    #   # └─────────────┴──────────┘
    def slice(offset, length = nil)
      Utils.wrap_expr(_rbexpr.str_slice(offset, length))
    end

    # Returns a column with a separate row for every string character.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"a": ["foo", "bar"]})
    #   df.select(Polars.col("a").str.explode)
    #   # =>
    #   # shape: (6, 1)
    #   # ┌─────┐
    #   # │ a   │
    #   # │ --- │
    #   # │ str │
    #   # ╞═════╡
    #   # │ f   │
    #   # │ o   │
    #   # │ o   │
    #   # │ b   │
    #   # │ a   │
    #   # │ r   │
    #   # └─────┘
    def explode
      Utils.wrap_expr(_rbexpr.str_explode)
    end

    # Parse integers with base radix from strings.
    #
    # By default base 2. ParseError/Overflows become Nulls.
    #
    # @param radix [Integer]
    #   Positive integer which is the base of the string we are parsing.
    #   Default: 2.
    # @param strict [Boolean]
    #   Bool, Default=true will raise any ParseError or overflow as ComputeError.
    #   False silently convert to Null.
    #
    # @return [Expr]
    #
    # @example
    #   df = Polars::DataFrame.new({"bin" => ["110", "101", "010", "invalid"]})
    #   df.select(Polars.col("bin").str.parse_int(2, strict: false))
    #   # =>
    #   # shape: (4, 1)
    #   # ┌──────┐
    #   # │ bin  │
    #   # │ ---  │
    #   # │ i32  │
    #   # ╞══════╡
    #   # │ 6    │
    #   # │ 5    │
    #   # │ 2    │
    #   # │ null │
    #   # └──────┘
    #
    # @example
    #   df = Polars::DataFrame.new({"hex" => ["fa1e", "ff00", "cafe", nil]})
    #   df.select(Polars.col("hex").str.parse_int(16, strict: true))
    #   # =>
    #   # shape: (4, 1)
    #   # ┌───────┐
    #   # │ hex   │
    #   # │ ---   │
    #   # │ i32   │
    #   # ╞═══════╡
    #   # │ 64030 │
    #   # │ 65280 │
    #   # │ 51966 │
    #   # │ null  │
    #   # └───────┘
    def parse_int(radix = 2, strict: true)
      Utils.wrap_expr(_rbexpr.str_parse_int(radix, strict))
    end

    private

    def _validate_format_argument(format)
      # TODO
    end
  end
end

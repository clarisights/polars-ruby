require_relative "test_helper"

class TypesTest < Minitest::Test
  def test_dtypes
    df = Polars::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal [Polars::Int64, Polars::Utf8], df.dtypes
  end

  def test_dtypes_hashes
    row = {
      b: true,
      i: 1,
      f: 1.5,
      c: BigDecimal("1.5"),
      s: "one",
      n: "two".b,
      d: Date.today,
      t: Time.now,
      z: Time.now.in_time_zone("Eastern Time (US & Canada)"),
      h: {"f" => 1},
      a: [1, 2, 3]
    }
    df = Polars::DataFrame.new([row])
    schema = df.schema
    assert_equal Polars::Boolean, schema["b"]
    assert_equal Polars::Int64, schema["i"]
    assert_equal Polars::Float64, schema["f"]
    # TODO fix
    assert_equal Polars::Float64, schema["c"]
    assert_equal Polars::Utf8, schema["s"]
    assert_equal Polars::Binary, schema["n"]
    assert_equal Polars::Date, schema["d"]
    assert_equal Polars::Datetime.new("ns"), schema["t"]
    assert_equal Polars::Datetime.new("ns"), schema["z"]
    assert_equal Polars::Struct.new([Polars::Field.new("f", Polars::Int64)]), schema["h"]
    assert_equal Polars::List.new(Polars::Int64), schema["a"]
  end

  def test_series_dtype_int
    [Polars::Int8, Polars::Int16, Polars::Int32, Polars::Int64].each do |dtype|
      s = Polars::Series.new([1, nil, 3], dtype: dtype)
      assert_series [1, nil, 3], s, dtype: dtype
    end
  end

  def test_series_dtype_uint
    [Polars::UInt8, Polars::UInt16, Polars::UInt32, Polars::UInt64].each do |dtype|
      s = Polars::Series.new([1, nil, 3], dtype: dtype)
      assert_series [1, nil, 3], s, dtype: dtype
    end
  end

  def test_series_dtype_float
    [Polars::Float32, Polars::Float64].each do |dtype|
      s = Polars::Series.new([1.5, nil, 3.5], dtype: dtype)
      assert_series [1.5, nil, 3.5], s, dtype: dtype
    end
  end

  def test_series_dtype_decimal
    s = Polars::Series.new([BigDecimal("12.3456"), nil, BigDecimal("-0.000078")], dtype: Polars::Decimal)
    assert_series [BigDecimal("12.3456"), nil, BigDecimal("-0.000078")], s, dtype: Polars::Decimal
    assert_equal BigDecimal("12.3456"), s[0]
  end

  def test_series_dtype_boolean
    s = Polars::Series.new([true, nil, false], dtype: Polars::Boolean)
    assert_series [true, nil, false], s, dtype: Polars::Boolean
  end

  def test_series_dtype_utf8
    s = Polars::Series.new(["a", nil, "c"], dtype: Polars::Utf8)
    assert_series ["a", nil, "c"], s, dtype: Polars::Utf8
    assert_equal [Encoding::UTF_8, nil, Encoding::UTF_8], s.to_a.map { |v| v&.encoding }
    assert_equal Encoding::UTF_8, s[0].encoding
  end

  def test_series_dtype_binary
    s = Polars::Series.new(["a", nil, "c"], dtype: Polars::Binary)
    assert_series ["a", nil, "c"], s, dtype: Polars::Binary
    assert_equal [Encoding::BINARY, nil, Encoding::BINARY], s.to_a.map { |v| v&.encoding }
    assert_equal Encoding::BINARY, s[0].encoding
  end

  def test_series_dtype_datetime
    s = Polars::Series.new([DateTime.new(2022, 1, 1)], dtype: Polars::Datetime)
    assert_series [Time.utc(2022, 1, 1)], s, dtype: Polars::Datetime.new("ns")
  end

  def test_series_dtype_datetime_time_unit
    s = Polars::Series.new([DateTime.new(2022, 1, 1)], dtype: Polars::Datetime.new("ms"))
    assert_series [Time.utc(2022, 1, 1)], s, dtype: Polars::Datetime.new("ms")
  end

  def test_series_dtype_duration
    s = Polars::Series.new([1e6, 2e6, 3e6], dtype: Polars::Duration)
    assert_series [1, 2, 3], s, dtype: Polars::Duration.new("us")
  end

  def test_series_dtype_duration_time_unit
    s = Polars::Series.new([1e3, 2e3, 3e3], dtype: Polars::Duration.new("ms"))
    assert_series [1, 2, 3], s, dtype: Polars::Duration.new("ms")
  end

  def test_series_dtype_time
    s = Polars::Series.new([DateTime.new(2022, 1, 1, 12, 34, 56)], dtype: Polars::Time)
    assert_series [Time.utc(2000, 1, 1, 12, 34, 56)], s, dtype: Polars::Time
  end

  def test_series_dtype_categorical
    s = Polars::Series.new(["one", "one", "two"], dtype: Polars::Categorical)
    assert_series ["one", "one", "two"], s, dtype: Polars::Categorical
  end
end

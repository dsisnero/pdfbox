require "../spec_helper"

def assert_java_sort_parity(input : Array(Int32), expected : Array(Int32))
  list = input.dup
  Pdfbox::Util::IterativeMergeSort.sort(list) { |a, b| a <=> b }
  list.should eq(expected)
end

def assert_matrix_values_equal_to(values : Array(Float32), matrix : Pdfbox::Util::Matrix)
  values.each_with_index do |value, i|
    row = i // 3
    column = i % 3
    matrix.get_value(row, column).should be_close(value, 0.00001_f32)
  end
end

describe "Porting parity pdfbox-lxq" do
  # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/util ● P3
  # Ported from StringUtilTest.java
  it "StringUtilTest#testSplitOnSpace_happyPath" do
    Pdfbox::Util::StringUtil.split_on_space("a b c").should eq(["a", "b", "c"])
  end

  it "StringUtilTest#testSplitOnSpace_emptyString" do
    Pdfbox::Util::StringUtil.split_on_space("").should eq([""])
  end

  it "StringUtilTest#testSplitOnSpace_onlySpaces" do
    Pdfbox::Util::StringUtil.split_on_space("   ").should eq([] of String)
  end

  it "StringUtilTest#testTokenizeOnSpace_happyPath" do
    Pdfbox::Util::StringUtil.tokenize_on_space("a b c").should eq(["a", " ", "b", " ", "c"])
  end

  it "StringUtilTest#testTokenizeOnSpace_emptyString" do
    Pdfbox::Util::StringUtil.tokenize_on_space("").should eq([""])
  end

  it "StringUtilTest#testTokenizeOnSpace_onlySpaces" do
    Pdfbox::Util::StringUtil.tokenize_on_space("   ").should eq([" ", " ", " "])
  end

  it "StringUtilTest#testTokenizeOnSpace_onlySpacesWithText" do
    Pdfbox::Util::StringUtil.tokenize_on_space("  a  ").should eq([" ", " ", "a", " ", " "])
  end

  # Ported from TestHexUtil.java
  it "TestHexUtil#testGetCharsFromShortWithoutPassingInABuffer" do
    Pdfbox::Util::Hex.get_chars(0x0000_i16).should eq(['0', '0', '0', '0'])
    Pdfbox::Util::Hex.get_chars(0x000F_i16).should eq(['0', '0', '0', 'F'])
    Pdfbox::Util::Hex.get_chars(-21_555_i16).should eq(['A', 'B', 'C', 'D']) # 0xABCD as signed short
    Pdfbox::Util::Hex.get_chars(-17_730_i16).should eq(['B', 'A', 'B', 'E']) # 0xBABE from 0xCAFEBABE
  end

  it "TestHexUtil#testGetCharsUTF16BE" do
    Pdfbox::Util::Hex.get_chars_utf16be("ab").should eq(['0', '0', '6', '1', '0', '0', '6', '2'])
    Pdfbox::Util::Hex.get_chars_utf16be("帮助").should eq(['5', 'E', '2', 'E', '5', '2', 'A', '9'])
  end

  it "TestHexUtil#testMisc" do
    byte_src = Bytes.new(256) { |i| i.to_u8 }

    byte_src.each_with_index do |_, i|
      bytes = Pdfbox::Util::Hex.get_bytes(i.to_u8)
      bytes.size.should eq(2)
      expected = i.to_s(16, upcase: true).rjust(2, '0').to_slice
      bytes.should eq(expected)
      Pdfbox::Util::Hex.get_string(i.to_u8).to_slice.should eq(bytes)
      Pdfbox::Util::Hex.decode_hex(Pdfbox::Util::Hex.get_string(i.to_u8)).should eq(Bytes[i.to_u8])
    end

    byte_dst = Pdfbox::Util::Hex.get_bytes(byte_src)
    byte_dst.size.should eq(byte_src.size * 2)

    dst_string = Pdfbox::Util::Hex.get_string(byte_src)
    dst_string.size.should eq(byte_src.size * 2)
    dst_string.to_slice.should eq(byte_dst)
    Pdfbox::Util::Hex.decode_hex(dst_string).should eq(byte_src)
  end

  it "TestHexUtil#testGetHexValue" do
    valid_hex = Set(Char).new

    ('0'..'9').each do |c|
      valid_hex << c
      Pdfbox::Util::Hex.get_hex_value(c).should eq(c.to_s.to_i(16))
    end
    ('a'..'f').each do |c|
      valid_hex << c
      Pdfbox::Util::Hex.get_hex_value(c).should eq(c.to_s.to_i(16))
    end
    ('A'..'F').each do |c|
      valid_hex << c
      Pdfbox::Util::Hex.get_hex_value(c).should eq(c.to_s.to_i(16))
    end
    valid_hex.size.should eq(22)

    (0..255).each do |c|
      char = c.chr
      unless valid_hex.includes?(char)
        Pdfbox::Util::Hex.get_hex_value(char).should eq(-256)
      end
    end
  end

  # Ported from TestNumberFormatUtil.java
  it "TestNumberFormatUtil#testFormatOfIntegerValues" do
    buffer = Bytes.new(64)

    Pdfbox::Util::NumberFormatUtil.format_float_fast(51.0_f32, 5, buffer).should eq(2)
    buffer[0, 2].should eq(Bytes['5'.ord.to_u8, '1'.ord.to_u8])

    Pdfbox::Util::NumberFormatUtil.format_float_fast(-51.0_f32, 5, buffer).should eq(3)
    buffer[0, 3].should eq(Bytes['-'.ord.to_u8, '5'.ord.to_u8, '1'.ord.to_u8])

    Pdfbox::Util::NumberFormatUtil.format_float_fast(0.0_f32, 5, buffer).should eq(1)
    buffer[0, 1].should eq(Bytes['0'.ord.to_u8])
  end

  it "TestNumberFormatUtil#testFormatOfRealValues" do
    buffer = Bytes.new(64)

    Pdfbox::Util::NumberFormatUtil.format_float_fast(0.7_f32, 5, buffer).should eq(3)
    buffer[0, 3].should eq(Bytes['0'.ord.to_u8, '.'.ord.to_u8, '7'.ord.to_u8])

    Pdfbox::Util::NumberFormatUtil.format_float_fast(-0.7_f32, 5, buffer).should eq(4)
    buffer[0, 4].should eq(Bytes['-'.ord.to_u8, '0'.ord.to_u8, '.'.ord.to_u8, '7'.ord.to_u8])

    Pdfbox::Util::NumberFormatUtil.format_float_fast(0.003_f32, 5, buffer).should eq(5)
    buffer[0, 5].should eq(Bytes['0'.ord.to_u8, '.'.ord.to_u8, '0'.ord.to_u8, '0'.ord.to_u8, '3'.ord.to_u8])
  end

  it "TestNumberFormatUtil#testFormatOfRealValuesReturnsMinusOneIfItCannotBeFormatted" do
    buffer = Bytes.new(64)
    Pdfbox::Util::NumberFormatUtil.format_float_fast(Float32::NAN, 5, buffer).should eq(-1)
    Pdfbox::Util::NumberFormatUtil.format_float_fast(Float32::INFINITY, 5, buffer).should eq(-1)
    Pdfbox::Util::NumberFormatUtil.format_float_fast(-Float32::INFINITY, 5, buffer).should eq(-1)
    Pdfbox::Util::NumberFormatUtil.format_float_fast(1.0_f32, 6, buffer).should eq(-1)
  end

  it "TestNumberFormatUtil#testRoundingUp and #testRoundingDown" do
    buffer = Bytes.new(64)

    Pdfbox::Util::NumberFormatUtil.format_float_fast(0.999999_f32, 5, buffer).should eq(1)
    buffer[0, 1].should eq(Bytes['1'.ord.to_u8])

    Pdfbox::Util::NumberFormatUtil.format_float_fast(0.125_f32, 2, buffer).should eq(4)
    buffer[0, 4].should eq(Bytes['0'.ord.to_u8, '.'.ord.to_u8, '1'.ord.to_u8, '3'.ord.to_u8])

    Pdfbox::Util::NumberFormatUtil.format_float_fast(-0.999999_f32, 5, buffer).should eq(2)
    buffer[0, 2].should eq(Bytes['-'.ord.to_u8, '1'.ord.to_u8])

    Pdfbox::Util::NumberFormatUtil.format_float_fast(0.994_f32, 2, buffer).should eq(4)
    buffer[0, 4].should eq(Bytes['0'.ord.to_u8, '.'.ord.to_u8, '9'.ord.to_u8, '9'.ord.to_u8])
  end

  # Ported from TestSort.java
  it "TestSort#testSort" do
    assert_java_sort_parity([9, 8, 7, 6, 5, 4, 3, 2, 1], [1, 2, 3, 4, 5, 6, 7, 8, 9])
    assert_java_sort_parity([4, 3, 2, 1, 9, 8, 7, 6, 5], [1, 2, 3, 4, 5, 6, 7, 8, 9])
    assert_java_sort_parity([] of Int32, [] of Int32)
    assert_java_sort_parity([5], [5])
    assert_java_sort_parity([5, 6], [5, 6])
    assert_java_sort_parity([6, 5], [5, 6])

    rnd = Random.new(12_345_i64)
    100.times do
      len = rnd.rand(20_000) + 2
      input = Array(Int32).new(len) { rnd.rand(rnd.rand(100) + 1) }
      expected = input.dup
      expected.sort!
      assert_java_sort_parity(input, expected)
    end
  end

  # Ported from MatrixTest.java
  it "MatrixTest#testConstructionAndCopy" do
    m1 = Pdfbox::Util::Matrix.new
    assert_matrix_values_equal_to([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32], m1)

    m2 = m1.clone
    m1.same?(m2).should be_false
    assert_matrix_values_equal_to([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32], m2)
  end

  it "MatrixTest#testGetScalingFactor" do
    m1 = Pdfbox::Util::Matrix.new
    m1.scaling_factor_x.should eq(1.0_f32)
    m1.scaling_factor_y.should eq(1.0_f32)

    m2 = Pdfbox::Util::Matrix.new(2.0_f32, 4.0_f32, 4.0_f32, 2.0_f32, 0.0_f32, 0.0_f32)
    expected = Math.sqrt(20.0).to_f32
    m2.scaling_factor_x.should be_close(expected, 0.0_f32)
    m2.scaling_factor_y.should be_close(expected, 0.0_f32)
  end

  it "MatrixTest#testCreateMatrixUsingInvalidInput" do
    create_matrix = Pdfbox::Util::Matrix.create_matrix(Pdfbox::Cos::Name.new("A"))
    assert_matrix_values_equal_to([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32], create_matrix)

    cos_array = Pdfbox::Cos::Array.new
    cos_array.add(Pdfbox::Cos::Name.new("A"))
    create_matrix = Pdfbox::Util::Matrix.create_matrix(cos_array)
    assert_matrix_values_equal_to([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32], create_matrix)

    cos_array = Pdfbox::Cos::Array.new
    6.times { cos_array.add(Pdfbox::Cos::Name.new("A")) }
    create_matrix = Pdfbox::Util::Matrix.create_matrix(cos_array)
    assert_matrix_values_equal_to([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32], create_matrix)
  end

  it "MatrixTest#testMultiplication and #testOldMultiplication" do
    const1 = Pdfbox::Util::Matrix.new
    const2 = Pdfbox::Util::Matrix.new
    3.times do |x|
      3.times do |y|
        const1.set_value(x, y, (x + y).to_f32)
        const2.set_value(x, y, (8 + x + y).to_f32)
      end
    end

    m1_x_m1 = [5.0_f32, 8.0_f32, 11.0_f32, 8.0_f32, 14.0_f32, 20.0_f32, 11.0_f32, 20.0_f32, 29.0_f32]
    m1_x_m2 = [29.0_f32, 32.0_f32, 35.0_f32, 56.0_f32, 62.0_f32, 68.0_f32, 83.0_f32, 92.0_f32, 101.0_f32]
    m2_x_m1 = [29.0_f32, 56.0_f32, 83.0_f32, 32.0_f32, 62.0_f32, 92.0_f32, 35.0_f32, 68.0_f32, 101.0_f32]

    var1 = const1.clone
    var2 = const2.clone
    result = var1.multiply(var2)
    var1.should eq(const1)
    var2.should eq(const2)
    assert_matrix_values_equal_to(m1_x_m2, result)

    var1 = const1.clone
    var2 = const2.clone
    var1.concatenate(var2)
    var2.should eq(const2)
    assert_matrix_values_equal_to(m2_x_m1, var1)

    result = Pdfbox::Util::Matrix.concatenate(const1, const2)
    assert_matrix_values_equal_to(m2_x_m1, result)

    result = const1.clone.multiply(const1.clone)
    assert_matrix_values_equal_to(m1_x_m1, result)
  end

  it "MatrixTest#testIllegalValueNaN/Infinity" do
    m = Pdfbox::Util::Matrix.new
    m.set_value(0, 0, Float32::MAX)
    expect_raises(ArgumentError) { m.multiply(m) }

    m = Pdfbox::Util::Matrix.new
    m.set_value(0, 0, Float32::NAN)
    expect_raises(ArgumentError) { m.multiply(m) }

    m = Pdfbox::Util::Matrix.new
    m.set_value(0, 0, Float32::INFINITY)
    expect_raises(ArgumentError) { m.multiply(m) }

    m = Pdfbox::Util::Matrix.new
    m.set_value(0, 0, -Float32::INFINITY)
    expect_raises(ArgumentError) { m.multiply(m) }
  end

  it "MatrixTest#testPdfbox2872" do
    m = Pdfbox::Util::Matrix.new(2.0_f32, 4.0_f32, 5.0_f32, 8.0_f32, 2.0_f32, 0.0_f32)
    array = m.to_cos_array
    array.get(0).should eq(Pdfbox::Cos::Float.new(2.0))
    array.get(1).should eq(Pdfbox::Cos::Float.new(4.0))
    array.get(2).should eq(Pdfbox::Cos::Float.new(5.0))
    array.get(3).should eq(Pdfbox::Cos::Float.new(8.0))
    array.get(4).should eq(Pdfbox::Cos::Float.new(2.0))
    array.get(5).should eq(Pdfbox::Cos::Float::ZERO)
  end

  it "MatrixTest#testGetValues #testScaling #testTranslation" do
    m = Pdfbox::Util::Matrix.new(2.0_f32, 4.0_f32, 4.0_f32, 2.0_f32, 15.0_f32, 30.0_f32)
    values = m.values
    values[0][0].should eq(2.0_f32)
    values[0][1].should eq(4.0_f32)
    values[0][2].should eq(0.0_f32)
    values[1][0].should eq(4.0_f32)
    values[1][1].should eq(2.0_f32)
    values[1][2].should eq(0.0_f32)
    values[2][0].should eq(15.0_f32)
    values[2][1].should eq(30.0_f32)
    values[2][2].should eq(1.0_f32)

    m.scale(2.0_f32, 3.0_f32)
    m.get_value(0, 0).should eq(4.0_f32)
    m.get_value(0, 1).should eq(8.0_f32)
    m.get_value(1, 0).should eq(12.0_f32)
    m.get_value(1, 1).should eq(6.0_f32)
    m.get_value(2, 0).should eq(15.0_f32)
    m.get_value(2, 1).should eq(30.0_f32)

    m = Pdfbox::Util::Matrix.new(2.0_f32, 4.0_f32, 4.0_f32, 2.0_f32, 15.0_f32, 30.0_f32)
    m.translate(2.0_f32, 3.0_f32)
    m.get_value(2, 0).should eq(31.0_f32)
    m.get_value(2, 1).should eq(44.0_f32)
    m.get_value(2, 2).should eq(1.0_f32)
  end

  # Ported from TestDateUtil.java (targeted parity subset)
  it "TestDateUtil#testExtract and #testDateConversion" do
    c = Pdfbox::Util::DateConverter.to_calendar("D:05/12/2005")
    c.should_not be_nil
    c = c.not_nil!
    c.year.should eq(2005)
    c.month.should eq(5)
    c.day.should eq(12)
    c.hour.should eq(0)
    c.minute.should eq(0)
    c.second.should eq(0)
    c.offset.should eq(0)

    c = Pdfbox::Util::DateConverter.to_calendar("5/12/2005 15:57:16")
    c.should_not be_nil
    c = c.not_nil!
    c.year.should eq(2005)
    c.month.should eq(5)
    c.day.should eq(12)
    c.hour.should eq(15)
    c.minute.should eq(57)
    c.second.should eq(16)
    c.offset.should eq(0)

    c = Pdfbox::Util::DateConverter.to_calendar("D:20050526205258+01'00'")
    c.should_not be_nil
    c = c.not_nil!
    c.year.should eq(2005)
    c.month.should eq(5)
    c.day.should eq(26)
    c.hour.should eq(20)
    c.minute.should eq(52)
    c.second.should eq(58)
    c.nanosecond.should eq(0)
    c.offset.should eq(3600)
  end

  it "TestDateUtil#testToString null and basic toString/toISO8601 formatting" do
    Pdfbox::Util::DateConverter.to_string(nil).should be_nil
    Pdfbox::Util::DateConverter.to_calendar(nil).should be_nil
    Pdfbox::Util::DateConverter.to_calendar("D:    ").should be_nil
    Pdfbox::Util::DateConverter.to_calendar("D:").should be_nil

    time = Time.parse("2015-08-28T03:14:15+09:30", "%Y-%m-%dT%H:%M:%S%:z", Time::Location::UTC)
    Pdfbox::Util::DateConverter.to_string(time).should eq("D:20150828031415+09'30'")
    Pdfbox::Util::DateConverter.to_iso8601(time).should eq("2015-08-28T03:14:15+09:30")
  end
end

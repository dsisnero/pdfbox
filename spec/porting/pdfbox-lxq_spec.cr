require "../spec_helper"

def assert_java_sort_parity(input : Array(Int32), expected : Array(Int32))
  list = input.dup
  Pdfbox::Util::IterativeMergeSort.sort(list) { |a, b| a <=> b }
  list.should eq(expected)
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
end

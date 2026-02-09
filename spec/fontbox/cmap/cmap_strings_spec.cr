require "../../spec_helper"

describe Fontbox::CMap::CMapStrings do
  describe ".get_mapping" do
    it "returns nil for byte arrays longer than 2 bytes" do
      Fontbox::CMap::CMapStrings.get_mapping([0_u8, 0_u8, 0_u8]).should be_nil
      Fontbox::CMap::CMapStrings.get_mapping([0_u8, 0_u8, 0_u8, 0_u8]).should be_nil
    end

    it "returns cached mapping for one-byte values" do
      min_value = [0_u8]
      mapping = Fontbox::CMap::CMapStrings.get_mapping(min_value)
      mapping.should_not be_nil
      mapping = mapping.not_nil!
      mapping.should eq String.new(Slice[0_u8], "ISO-8859-1")
      # same object reference for same input - TODO: test object identity

      max_value = [0xFF_u8]
      mapping2 = Fontbox::CMap::CMapStrings.get_mapping(max_value)
      mapping2.should_not be_nil
      mapping2 = mapping2.not_nil!
      mapping2.should eq String.new(Slice[0xFF_u8], "ISO-8859-1")

      any_value = [98_u8]
      mapping3 = Fontbox::CMap::CMapStrings.get_mapping(any_value)
      mapping3.should_not be_nil
      mapping3 = mapping3.not_nil!
      mapping3.should eq String.new(Slice[98_u8], "ISO-8859-1")
    end

    it "returns cached mapping for two-byte values" do
      min_value = [0_u8, 0_u8]
      mapping = Fontbox::CMap::CMapStrings.get_mapping(min_value)
      mapping.should_not be_nil
      mapping = mapping.not_nil!
      mapping.should eq String.new(Slice[0_u8, 0_u8], "UTF-16BE")
      # same object reference for same input - TODO: test object identity

      max_value = [0xFF_u8, 0xFF_u8]
      mapping2 = Fontbox::CMap::CMapStrings.get_mapping(max_value)
      mapping2.should_not be_nil
      mapping2 = mapping2.not_nil!
      mapping2.should eq String.new(Slice[0xFF_u8, 0xFF_u8], "UTF-16BE")

      any_value = [0x12_u8, 0x34_u8]
      mapping3 = Fontbox::CMap::CMapStrings.get_mapping(any_value)
      mapping3.should_not be_nil
      mapping3 = mapping3.not_nil!
      mapping3.should eq String.new(Slice[0x12_u8, 0x34_u8], "UTF-16BE")
    end
  end

  describe ".get_index_value" do
    it "returns nil for byte arrays longer than 2 bytes" do
      Fontbox::CMap::CMapStrings.get_index_value([0_u8, 0_u8, 0_u8]).should be_nil
    end

    it "returns integer index for one-byte values" do
      Fontbox::CMap::CMapStrings.get_index_value([0_u8]).should eq 0
      Fontbox::CMap::CMapStrings.get_index_value([0xFF_u8]).should eq 0xFF
      Fontbox::CMap::CMapStrings.get_index_value([98_u8]).should eq 98
    end

    it "returns integer index for two-byte values" do
      Fontbox::CMap::CMapStrings.get_index_value([0_u8, 0_u8]).should eq 0
      Fontbox::CMap::CMapStrings.get_index_value([0xFF_u8, 0xFF_u8]).should eq 0xFFFF
      Fontbox::CMap::CMapStrings.get_index_value([0x12_u8, 0x34_u8]).should eq(0x12 * 256 + 0x34)
    end
  end

  describe ".get_byte_value" do
    it "returns nil for byte arrays longer than 2 bytes" do
      Fontbox::CMap::CMapStrings.get_byte_value([0_u8, 0_u8, 0_u8]).should be_nil
    end

    it "returns singleton byte array for one-byte values" do
      bytes = [0_u8]
      result = Fontbox::CMap::CMapStrings.get_byte_value(bytes)
      result.should_not be_nil
      result = result.not_nil!
      result.should eq Slice[0_u8]
      # same object reference - TODO: test object identity
    end

    it "returns singleton byte array for two-byte values" do
      bytes = [0x12_u8, 0x34_u8]
      result = Fontbox::CMap::CMapStrings.get_byte_value(bytes)
      result.should_not be_nil
      result = result.not_nil!
      result.should eq Slice[0x12_u8, 0x34_u8]
      # same object reference - TODO: test object identity
    end
  end
end

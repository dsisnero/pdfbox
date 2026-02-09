require "../../spec_helper"

describe Fontbox::CMap::CodespaceRange do
  describe "#initialize" do
    it "returns code length 1 for single byte range" do
      start_bytes = [0x00_u8]
      end_bytes = [0x20_u8]
      range = Fontbox::CMap::CodespaceRange.new(start_bytes, end_bytes)
      range.code_length.should eq 1
    end

    it "returns code length 2 for double byte range" do
      start_bytes = [0x00_u8, 0x00_u8]
      end_bytes = [0x01_u8, 0x20_u8]
      range = Fontbox::CMap::CodespaceRange.new(start_bytes, end_bytes)
      range.code_length.should eq 2
    end

    it "allows different lengths when start is single zero byte (PDFBOX-4923)" do
      start_bytes = [0x00_u8]
      end_bytes = [0xFF_u8, 0xFF_u8]
      range = Fontbox::CMap::CodespaceRange.new(start_bytes, end_bytes)
      range.code_length.should eq 2
    end

    it "raises ArgumentError when start and end have different lengths (general case)" do
      start_bytes = [0x01_u8]
      end_bytes = [0x01_u8, 0x20_u8]
      expect_raises(ArgumentError) do
        Fontbox::CMap::CodespaceRange.new(start_bytes, end_bytes)
      end
    end
  end

  describe "#matches" do
    it "matches single byte range" do
      start_bytes = [0x00_u8]
      end_bytes = [0xA0_u8]
      range = Fontbox::CMap::CodespaceRange.new(start_bytes, end_bytes)
      range.matches([0x00_u8]).should be_true
      range.matches([0xA0_u8]).should be_true
      range.matches([0x10_u8]).should be_true
      range.matches([0xA1_u8]).should be_false
      range.matches([0xD0_u8]).should be_false
      range.matches([0x00_u8, 0x10_u8]).should be_false
    end

    it "matches double byte rectangular range" do
      start_bytes = [0x81_u8, 0x40_u8]
      end_bytes = [0x9F_u8, 0xFC_u8]
      range = Fontbox::CMap::CodespaceRange.new(start_bytes, end_bytes)
      # check lower start and end value
      range.matches([0x81_u8, 0x40_u8]).should be_true
      range.matches([0x81_u8, 0xFC_u8]).should be_true
      # check higher start and end value
      range.matches([0x81_u8, 0x40_u8]).should be_true
      range.matches([0x9F_u8, 0x40_u8]).should be_true
      # any value within lower range
      range.matches([0x81_u8, 0x65_u8]).should be_true
      # any value within higher range
      range.matches([0x90_u8, 0x40_u8]).should be_true
      # first value out of lower range
      range.matches([0x81_u8, 0xFD_u8]).should be_false
      # first value out of higher range
      range.matches([0xA0_u8, 0x40_u8]).should be_false
      # any value out of lower range
      range.matches([0x81_u8, 0x20_u8]).should be_false
      # any value out of higher range
      range.matches([0x10_u8, 0x40_u8]).should be_false
      # value between start and end but not within rectangular
      range.matches([0x82_u8, 0x20_u8]).should be_false
      # different code length
      range.matches([0x00_u8]).should be_false
    end
  end
end
require "../../spec_helper"

module Fontbox::CFF
  describe Type2CharStringParser do
    it "parses simple numbers" do
      parser = Type2CharStringParser.new("TestFont")
      # Test number encoding: 100 is in range 32..246 => 100 + 139 = 239
      bytes = Bytes[239, 21] # 100, RMOVETO (21)
      result = parser.parse(bytes, nil, nil)
      result.size.should eq 2
      result[0].should eq 100
      result[1].should eq CharStringCommand::RMOVETO
    end

    it "parses two-byte positive numbers" do
      parser = Type2CharStringParser.new("TestFont")
      # 300 = (247-247)*256 + 192 + 108 = 300 => b0=247, b1=192
      bytes = Bytes[247, 192, 21] # 300, RMOVETO
      result = parser.parse(bytes, nil, nil)
      result.size.should eq 2
      result[0].should eq 300
      result[1].should eq CharStringCommand::RMOVETO
    end

    it "parses shortint numbers" do
      parser = Type2CharStringParser.new("TestFont")
      # 1000 as shortint: b0=28, then 0x03E8
      bytes = Bytes[28, 0x03, 0xE8, 21] # 1000, RMOVETO
      result = parser.parse(bytes, nil, nil)
      result.size.should eq 2
      result[0].should eq 1000
      result[1].should eq CharStringCommand::RMOVETO
    end

    it "parses fixed point numbers" do
      parser = Type2CharStringParser.new("TestFont")
      # 1.5 = 1 + 32768/65535 approx 1.5
      # Actually 1.5 = 1 + 0.5, fraction = 0.5 * 65535 = 32767.5 ≈ 32768
      # bytes: 255, 0x00, 0x01, 0x80, 0x00
      bytes = Bytes[255, 0x00, 0x01, 0x80, 0x00, 21]
      result = parser.parse(bytes, nil, nil)
      result.size.should eq 2
      result[0].should be_a(Float64)
      # Allow floating point approximation
      (result[0].as(Float64) - 1.5).abs.should be < 0.0001
      result[1].should eq CharStringCommand::RMOVETO
    end

    it "handles CALLSUBR with local subroutines" do
      parser = Type2CharStringParser.new("TestFont")
      # Local subr index: for index length 1 (<1240), subroutine 0 in charstring
      # maps to index 107 (107 + 0). So we need 108 entries with our test at index 107.
      local_subrs = Array.new(108) { Bytes.empty }
      local_subrs[107] = Bytes[21] # RMOVETO at index 107
      # Bytes: 0 (encoded as 139), CALLSUBR (10)
      bytes = Bytes[139, 10]
      result = parser.parse(bytes, nil, local_subrs)
      # Should call subroutine which contains RMOVETO
      result.size.should eq 1
      result[0].should eq CharStringCommand::RMOVETO
    end
  end
end

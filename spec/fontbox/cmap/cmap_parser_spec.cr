require "../../spec_helper"

module Fontbox::CMap
  describe CMapParser do
    it "test_lookup" do
      resource_dir = "spec/resources/cmap"
      in_dir = File.join(resource_dir)
      c_map = CMapParser.new.parse(Pdfbox::IO::MemoryRandomAccessRead.new(File.read(File.join(in_dir, "CMapTest")).to_slice))

      # char mappings
      bytes1 = Bytes[0, 1]
      c_map.to_unicode(bytes1).should eq "A" # bytes 00 01 from bfrange <0001> <0005> <0041>

      bytes2 = Bytes[1, 0]
      str2 = "0"
      c_map.to_unicode(bytes2).should eq str2 # bytes 01 00 from bfrange <0100> <0109> <0030>

      bytes3 = Bytes[1, 32]
      c_map.to_unicode(bytes3).should eq "P" # bytes 01 00 from bfrange <0100> <0109> <0030>

      bytes4 = Bytes[1, 33]
      c_map.to_unicode(bytes4).should eq "R" # bytes 01 00 from bfrange <0100> <0109> <0030>

      bytes5 = Bytes[0, 10]
      str5 = "*"
      c_map.to_unicode(bytes5).should eq str5 # bytes 00 0A from bfchar <000A> <002A>

      bytes6 = Bytes[1, 10]
      str6 = "+"
      c_map.to_unicode(bytes6).should eq str6 # bytes 01 0A from bfchar <010A> <002B>

      # CID mappings
      cid1 = Bytes[0, 65]
      c_map.to_cid(cid1).should eq 65 # CID 65 from cidrange <0000> <00ff> 0

      cid2 = Bytes[1, 24]
      str_cid2 = 0x0118
      c_map.to_cid(cid2).should eq str_cid2 # CID 280 from cidrange <0100> <01ff> 256

      cid3 = Bytes[2, 8]
      str_cid3 = 0x0208
      c_map.to_cid(cid3).should eq str_cid3 # CID 520 from cidchar <0208> 520

      cid4 = Bytes[1, 0x2c]
      str_cid4 = 0x12C
      c_map.to_cid(cid4).should eq str_cid4 # CID 300 from cidrange <0300> <0300> 300
    end

    it "test_identity" do
      c_map = CMapParser.new.parse_predefined("Identity-H")

      c_map.to_cid(Bytes[0, 65]).should eq 65          # Identity-H CID 65
      c_map.to_cid(Bytes[0x30, 0x39]).should eq 12345  # Identity-H CID 12345
      c_map.to_cid(Bytes[0xFF, 0xFF]).should eq 0xFFFF # Identity-H CID 0xFFFF
    end

    it "test_unijis_utf16_h" do
      c_map = CMapParser.new.parse_predefined("UniJIS-UTF16-H")

      # the next 3 cases demonstrate the issue of possible false result values of CMap.toCID(int code)
      c_map.to_cid(0xb1).should eq 694        # UniJIS-UTF16-H CID 0xb1 -> 694
      c_map.to_cid(0xb1, 1).should_not eq 694 # UniJIS-UTF16-H CID 0xb1 -> 694
      c_map.to_cid(0xb1, 2).should eq 694     # UniJIS-UTF16-H CID 0x00b1 -> 694

      # 1:1 cid char mapping
      c_map.to_cid(Bytes[0x00, 0xb1]).should eq 694               # UniJIS-UTF16-H CID 0x00b1 -> 694
      c_map.to_cid(Bytes[0xd8, 0x50, 0xdc, 0x4b]).should eq 20168 # UniJIS-UTF16-H CID 0xd850dc4b -> 20168

      # cid range mapping
      c_map.to_cid(Bytes[0x54, 0x34]).should eq 19223             # UniJIS-UTF16-H CID 0x5434 -> 19223
      c_map.to_cid(Bytes[0xd8, 0x3c, 0xdd, 0x12]).should eq 10006 # UniJIS-UTF16-H CID 0xd83cdd12 -> 10006
    end

    it "test_unijis_ucs2_h" do
      c_map = CMapParser.new.parse_predefined("UniJIS-UCS2-H")

      c_map.to_cid(Bytes[0, 65]).should eq 34 # UniJIS-UCS2-H CID 65 -> 34
    end

    it "test_adobe_gb1_ucs2" do
      c_map = CMapParser.new.parse_predefined("Adobe-GB1-UCS2")

      c_map.to_unicode(Bytes[0, 0x11]).should eq "0" # Adobe-GB1-UCS2 CID 0x11 -> "0"
    end

    it "test_parser_with_poor_whitespace" do
      c_map = CMapParser.new.parse(Pdfbox::IO::MemoryRandomAccessRead.new(File.read("spec/resources/cmap/CMapNoWhitespace").to_slice))

      c_map.should_not be_nil # Failed to parse nasty CMap file
    end

    it "test_parser_with_malformedbfrange1" do
      c_map = CMapParser.new.parse(Pdfbox::IO::MemoryRandomAccessRead.new(File.read("spec/resources/cmap/CMapMalformedbfrange1").to_slice))

      c_map.should_not be_nil # Failed to parse malformed CMap file

      bytes1 = Bytes[0, 1]
      c_map.to_unicode(bytes1).should eq "A" # bytes 00 01 from bfrange <0001> <0009> <0041>

      bytes2 = Bytes[1, 0]
      c_map.to_unicode(bytes2).should be_nil
    end

    it "test_parser_with_malformedbfrange2" do
      c_map = CMapParser.new.parse(Pdfbox::IO::MemoryRandomAccessRead.new(File.read("spec/resources/cmap/CMapMalformedbfrange2").to_slice))

      c_map.should_not be_nil # Failed to parse malformed CMap file

      c_map.to_unicode(Bytes[0, 1]).should eq "0" # bytes 00 01 from bfrange <0001> <0009> <0030>

      c_map.to_unicode(Bytes[2, 0x32]).should eq "A" # bytes 02 32 from bfrange <0232> <0432> <0041>

      # check border values for non strict mode
      c_map.to_unicode(Bytes[2, 0xF0]).should_not be_nil
      c_map.to_unicode(Bytes[2, 0xF1]).should_not be_nil

      # use strict mode
      c_map = CMapParser.new(true).parse(Pdfbox::IO::MemoryRandomAccessRead.new(File.read("spec/resources/cmap/CMapMalformedbfrange2").to_slice))
      # check border values for strict mode
      c_map.to_unicode(Bytes[2, 0xF0]).should_not be_nil
      c_map.to_unicode(Bytes[2, 0xF1]).should be_nil
    end

    it "test_predefined_map" do
      c_map = CMapParser.new.parse_predefined("Adobe-Korea1-UCS2")
      c_map.should_not be_nil # Failed to parse predefined CMap Adobe-Korea1-UCS2

      c_map.name.should eq "Adobe-Korea1-UCS2" # wrong CMap name
      c_map.wmode.should eq 0                  # wrong WMode
      c_map.has_cid_mappings?.should be_false
      c_map.has_unicode_mappings?.should be_true

      c_map = CMapParser.new.parse_predefined("Identity-V")
      c_map.should_not be_nil # Failed to parse predefined CMap Identity-V
    end

    it "test_identitybfrange" do
      # use strict mode
      c_map = CMapParser.new(true).parse(Pdfbox::IO::MemoryRandomAccessRead.new(File.read("spec/resources/cmap/Identitybfrange").to_slice))
      c_map.name.should eq "Adobe-Identity-UCS" # wrong CMap name

      bytes = Bytes[0, 65]
      c_map.to_unicode(bytes).should eq String.new(bytes, "UTF-16BE") # Identity 0x0048
      bytes = Bytes[0x30, 0x39]
      c_map.to_unicode(bytes).should eq String.new(bytes, "UTF-16BE") # Identity 0x3039
      # check border values for strict mode
      bytes = Bytes[0x30, 0xFF]
      c_map.to_unicode(bytes).should eq String.new(bytes, "UTF-16BE") # Identity 0x30FF
      # check border values for strict mode
      bytes = Bytes[0x31, 0x00]
      c_map.to_unicode(bytes).should eq String.new(bytes, "UTF-16BE") # Identity 0x3100
      bytes = Bytes[0xFF, 0xFF]
      c_map.to_unicode(bytes).should eq String.new(bytes, "UTF-16BE") # Identity 0xFFFF
    end
  end
end

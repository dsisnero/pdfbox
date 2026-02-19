# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "../../spec_helper"

module Fontbox::TTF
  def self.parse_test_font : TrueTypeFont
    font_path = File.join("vendor/pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
    parser = TTFParser.new
    parser.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))
  end

  describe CmapTable do
    it "returns a Unicode subtable for known platform/encoding" do
      font = Fontbox::TTF.parse_test_font
      cmap = font.table(CmapTable::TAG).as(CmapTable)

      unicode_bmp = cmap.subtable(CmapTable::PLATFORM_WINDOWS, CmapTable::ENCODING_WIN_UNICODE_BMP)
      unicode_bmp.should_not be_nil

      font.close
    end

    it "returns nil when no subtable exists for platform/encoding" do
      font = Fontbox::TTF.parse_test_font
      cmap = font.table(CmapTable::TAG).as(CmapTable)

      cmap.subtable(CmapTable::PLATFORM_MACINTOSH, 99).should be_nil

      font.close
    end

    it "maps character codes to glyph ids and back" do
      font = Fontbox::TTF.parse_test_font
      cmap = font.table(CmapTable::TAG).as(CmapTable)
      unicode_bmp = cmap.subtable(CmapTable::PLATFORM_WINDOWS, CmapTable::ENCODING_WIN_UNICODE_BMP)
      unicode_bmp.should_not be_nil
      subtable = unicode_bmp || raise "expected Windows Unicode BMP cmap subtable"

      trade_mark_gid = subtable.glyph_id(0x2122)
      euro_gid = subtable.glyph_id(0x20AC)

      trade_mark_gid.should be > 0
      euro_gid.should be > 0

      trade_mark_codes = subtable.char_codes(trade_mark_gid)
      euro_codes = subtable.char_codes(euro_gid)

      trade_mark_codes.should_not be_nil
      euro_codes.should_not be_nil
      if trade_mark_codes
        trade_mark_codes.should contain(0x2122)
      end
      if euro_codes
        euro_codes.should contain(0x20AC)
      end

      font.close
    end

    it "returns 0 for unknown character code" do
      font = Fontbox::TTF.parse_test_font
      cmap = font.table(CmapTable::TAG).as(CmapTable)
      unicode_bmp = cmap.subtable(CmapTable::PLATFORM_WINDOWS, CmapTable::ENCODING_WIN_UNICODE_BMP)
      unicode_bmp.should_not be_nil

      if unicode_bmp
        unicode_bmp.glyph_id(0x110000).should eq(0)
      end

      font.close
    end

    it "PDFBox-5328: gets multiple encodings from cmap table" do
      expected_char_codes = [19981, 63847]
      gid = 8712
      font_file = File.join("vendor", "pdfbox", "fontbox", "target", "fonts", "NotoSansSC-Regular.otf")
      otf = TTFParser.new(false).parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_file))

      unicode_cmap_lookup = otf.unicode_cmap_lookup
      char_codes = unicode_cmap_lookup.char_codes(gid)
      char_codes.should eq(expected_char_codes)

      cmap_table = otf.cmap
      cmap_table.should_not be_nil
      cmap = cmap_table || raise "expected cmap table"

      unicode_full_cmap_table = cmap.subtable(CmapTable::PLATFORM_UNICODE, CmapTable::ENCODING_UNICODE_2_0_FULL)
      unicode_bmp_cmap_table = cmap.subtable(CmapTable::PLATFORM_UNICODE, CmapTable::ENCODING_UNICODE_2_0_BMP)
      unicode_full_cmap_table.should_not be_nil
      unicode_bmp_cmap_table.should_not be_nil

      unicode_full = unicode_full_cmap_table || raise "expected unicode full cmap subtable"
      unicode_bmp = unicode_bmp_cmap_table || raise "expected unicode bmp cmap subtable"

      unicode_bmp_char_codes = unicode_bmp.char_codes(gid)
      unicode_full_char_codes = unicode_full.char_codes(gid)

      unicode_bmp_char_codes.should eq(expected_char_codes)
      unicode_full_char_codes.should eq(expected_char_codes)

      otf.close
    end

    it "PDFBox-4106: vertical substitution changes glyph IDs" do
      ipa_font = File.join("vendor", "pdfbox", "fontbox", "target", "fonts", "ipag00303", "ipag.ttf")
      ttf = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(ipa_font))

      unicode_cmap_lookup1 = ttf.unicode_cmap_lookup
      hgid1 = unicode_cmap_lookup1.glyph_id('「'.ord)
      hgid2 = unicode_cmap_lookup1.glyph_id('」'.ord)
      ttf.enable_vertical_substitutions
      unicode_cmap_lookup2 = ttf.unicode_cmap_lookup
      vgid1 = unicode_cmap_lookup2.glyph_id('「'.ord)
      vgid2 = unicode_cmap_lookup2.glyph_id('」'.ord)

      hgid1.should eq(441)
      hgid2.should eq(442)
      vgid1.should eq(7392)
      vgid2.should eq(7393)

      ttf.close
    end
  end
end

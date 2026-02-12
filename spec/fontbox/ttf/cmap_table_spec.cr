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
    font_path = File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
    parser = TTFParser.new
    parser.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))
  end

  describe CmapTable do
    it "returns a Unicode subtable for known platform/encoding" do
      font = Fontbox::TTF.parse_test_font
      cmap = font.get_table(CmapTable::TAG).as(CmapTable)

      unicode_bmp = cmap.get_subtable(CmapTable::PLATFORM_WINDOWS, CmapTable::ENCODING_WIN_UNICODE_BMP)
      unicode_bmp.should_not be_nil

      font.close
    end

    it "returns nil when no subtable exists for platform/encoding" do
      font = Fontbox::TTF.parse_test_font
      cmap = font.get_table(CmapTable::TAG).as(CmapTable)

      cmap.get_subtable(CmapTable::PLATFORM_MACINTOSH, 99).should be_nil

      font.close
    end

    it "maps character codes to glyph ids and back" do
      font = Fontbox::TTF.parse_test_font
      cmap = font.get_table(CmapTable::TAG).as(CmapTable)
      unicode_bmp = cmap.get_subtable(CmapTable::PLATFORM_WINDOWS, CmapTable::ENCODING_WIN_UNICODE_BMP)
      unicode_bmp.should_not be_nil
      subtable = unicode_bmp || raise "expected Windows Unicode BMP cmap subtable"

      trade_mark_gid = subtable.get_glyph_id(0x2122)
      euro_gid = subtable.get_glyph_id(0x20AC)

      trade_mark_gid.should be > 0
      euro_gid.should be > 0

      trade_mark_codes = subtable.get_char_codes(trade_mark_gid)
      euro_codes = subtable.get_char_codes(euro_gid)

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
      cmap = font.get_table(CmapTable::TAG).as(CmapTable)
      unicode_bmp = cmap.get_subtable(CmapTable::PLATFORM_WINDOWS, CmapTable::ENCODING_WIN_UNICODE_BMP)
      unicode_bmp.should_not be_nil

      if unicode_bmp
        unicode_bmp.get_glyph_id(0x110000).should eq(0)
      end

      font.close
    end

    pending "PDFBox-5328: test that we get multiple encodings from cmap table (requires NotoSansSC-Regular.otf)" do
    end

    pending "PDFBox-4106: vertical substitution changes glyph IDs (requires ipag.ttf)" do
    end
  end
end

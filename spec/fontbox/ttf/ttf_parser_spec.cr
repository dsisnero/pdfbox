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
  def self.test_font_path : String
    File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
  end

  describe TTFParser do
    it "parses header created date in UTC" do
      font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(Fontbox::TTF.test_font_path))

      header = font.get_header
      header.should_not be_nil
      created = header ? header.get_created : raise "expected header table"

      created.location.name.should eq("UTC")
      created.should eq(Time.utc(2010, 6, 18, 10, 23, 22))

      font.close
    end

    it "maps cmap glyph ids to postscript glyph names" do
      font_bytes = File.read(Fontbox::TTF.test_font_path).to_slice
      font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBuffer.new(font_bytes))

      cmap_table = font.get_table(CmapTable::TAG).as(CmapTable)
      cmap_table.should_not be_nil

      subtable = cmap_table.get_subtable(NameRecord::PLATFORM_WINDOWS, NameRecord::ENCODING_WINDOWS_UNICODE_BMP)
      subtable.should_not be_nil

      post = font.get_postscript
      post.should_not be_nil
      glyph_names = post ? post.get_glyph_names : nil
      glyph_names.should_not be_nil

      table = subtable || raise "expected Windows Unicode BMP cmap subtable"
      tm_gid = table.get_glyph_id(0x2122)
      euro_gid = table.get_glyph_id(0x20AC)

      names = glyph_names || raise "expected postscript glyph names"
      names[tm_gid].should eq("trademark")
      names[euro_gid].should eq("Euro")

      font.close
    end
  end
end

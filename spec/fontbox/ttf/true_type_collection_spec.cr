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
require "../../../src/fontbox/ttf"

describe Fontbox::TTF::TrueTypeCollection do
  # The invalid-font-count example is a direct port of
  # fontbox/src/test/java/org/apache/fontbox/ttf/TrueTypeFontCollectionTest.java.
  # The synthetic TTC round-trip below is supplemental source-derived coverage for the remaining
  # collection callbacks because upstream Java does not ship a tiny TTC fixture in test resources.
  fonts_dir = File.expand_path("../../../vendor/pdfbox/fontbox/target/fonts", __DIR__)
  ttf_path = File.join(fonts_dir, "DejaVuSansMono.ttf")

  describe "#initialize" do
    it "detects invalid number of fonts" do
      # Payload with "ttcf" header (0x74 0x74 0x63 0x66), version 0.0.0.0,
      # and invalid number of fonts 0x7FFFFFFF (2147483647 > 1024)
      payload = Bytes[0x74, 0x74, 0x63, 0x66, 0x00, 0x00, 0x00, 0x00, 0x7F, 0xFF, 0xFF, 0xFF]
      io = IO::Memory.new(payload)

      expect_raises(IO::Error, "Invalid number of fonts 2147483647") do
        Fontbox::TTF::TrueTypeCollection.new(io)
      end
    end
  end

  it "processes TTC fonts, resolves fonts by name, and scans headers" do
    unless File.exists?(ttf_path)
      pending "TTF fixture not found: #{ttf_path}"
      next
    end
    temp_dir = File.expand_path("../../../temp/ttf", __DIR__)
    Dir.mkdir_p(temp_dir)
    ttc_path = File.join(temp_dir, "single-font.ttc")
    ttf_bytes = File.open(ttf_path) do |file|
      bytes = Bytes.new(file.size)
      file.read_fully(bytes)
      bytes
    end
    ttc_font_offset = 16
    num_tables = ((ttf_bytes[4].to_i << 8) | ttf_bytes[5].to_i)
    num_tables.times do |index|
      table_offset_index = 12 + (index * 16) + 8
      table_offset = (ttf_bytes[table_offset_index].to_u32 << 24) |
                     (ttf_bytes[table_offset_index + 1].to_u32 << 16) |
                     (ttf_bytes[table_offset_index + 2].to_u32 << 8) |
                     ttf_bytes[table_offset_index + 3].to_u32
      adjusted_offset = table_offset + ttc_font_offset
      ttf_bytes[table_offset_index] = ((adjusted_offset >> 24) & 0xFF).to_u8
      ttf_bytes[table_offset_index + 1] = ((adjusted_offset >> 16) & 0xFF).to_u8
      ttf_bytes[table_offset_index + 2] = ((adjusted_offset >> 8) & 0xFF).to_u8
      ttf_bytes[table_offset_index + 3] = (adjusted_offset & 0xFF).to_u8
    end

    File.open(ttc_path, "w") do |file|
      file.write(Bytes['t'.ord.to_u8, 't'.ord.to_u8, 'c'.ord.to_u8, 'f'.ord.to_u8])
      file.write(Bytes[0x00_u8, 0x01_u8, 0x00_u8, 0x00_u8])
      file.write(Bytes[0x00_u8, 0x00_u8, 0x00_u8, 0x01_u8])
      file.write(Bytes[0x00_u8, 0x00_u8, 0x00_u8, 0x10_u8])
      file.write(ttf_bytes)
    end

    headers = [] of Fontbox::TTF::FontHeaders
    File.open(ttc_path) do |file|
      Fontbox::TTF::TrueTypeCollection.process_all_font_headers(file, ->(header : Fontbox::TTF::FontHeaders) do
        headers << header
      end)
    end
    headers.size.should eq(1)
    headers.first.error.should be_nil

    File.open(ttc_path) do |io|
      collection = Fontbox::TTF::TrueTypeCollection.new(io)
      names = [] of String
      collection.process_all_fonts(->(font : Fontbox::TTF::TrueTypeFont) do
        names << font.name
      end)
      names.size.should eq(1)

      collection.font_by_name(names.first).should_not be_nil
      collection.close
    end
  end
end

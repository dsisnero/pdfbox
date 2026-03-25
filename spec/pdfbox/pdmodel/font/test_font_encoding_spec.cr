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

require "../../../spec_helper"

describe "TestFontEncoding" do
  # Test the add method of a font encoding.
  describe "test_add" do
    it "should have space at code 32 in WinAnsiEncoding" do
      code_for_space = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE.name_to_code_map["space"]
      code_for_space.should eq 32
    end

    it "should have space at code 32 in MacRomanEncoding" do
      code_for_space = Pdfbox::Pdmodel::Font::Encoding::MacRomanEncoding::INSTANCE.name_to_code_map["space"]
      code_for_space.should eq 32
    end
  end

  describe "test_overwrite" do
    it "should overwrite space with a in DictionaryEncoding" do
      dict_encoding_dict = Pdfbox::Cos::Dictionary.new
      dict_encoding_dict.set_item(Pdfbox::Cos::Name::TYPE, Pdfbox::Cos::Name::ENCODING)
      dict_encoding_dict.set_item(Pdfbox::Cos::Name::BASE_ENCODING, Pdfbox::Cos::Name::WIN_ANSI_ENCODING)
      differences = Pdfbox::Cos::Array.new
      differences.add(Pdfbox::Cos::Integer.get(32))
      differences.add(Pdfbox::Cos::Name.new("a"))
      dict_encoding_dict.set_item(Pdfbox::Cos::Name::DIFFERENCES, differences)

      dict_encoding = Pdfbox::Pdmodel::Font::Encoding::DictionaryEncoding.new(dict_encoding_dict, false, nil)

      dict_encoding.name_to_code_map["space"]?.should be_nil
      dict_encoding.name_to_code_map["a"]?.should eq 32
    end
  end

  # PDFBOX-3826: Some unicodes are reached by several names in glyphlist.txt, e.g. tilde and
  # ilde.
  # @throws IOException
  describe "test_pdfbox_3884" do
    it "should handle multiple Unicode names for same codepoint" do
      doc = Pdfbox::Pdmodel::Document.new
      begin
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        begin
          font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
          cs.set_font(font, 20)
          cs.begin_text
          cs.new_line_at_offset(100, 700)
          # first tilde is "asciitilde" (from the keyboard), 2nd tilde is "tilde"
          # using ˜ would bring IllegalArgumentException prior to bugfix
          cs.show_text("~˜")
          cs.end_text
        ensure
          cs.close
        end

        # Save and verify the document can be written
        output = IO::Memory.new
        doc.save(output)
        output.to_slice.size.should be > 0
      ensure
        doc.close
      end
    end
  end
end

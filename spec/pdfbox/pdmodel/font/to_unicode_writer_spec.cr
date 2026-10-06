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

describe Pdfbox::Pdmodel::Font::ToUnicodeWriter do
  describe "testCMapLigatures" do
    it "writes ligatures correctly" do
      to_unicode_writer = Pdfbox::Pdmodel::Font::ToUnicodeWriter.new

      to_unicode_writer.add(0x400, "a")
      to_unicode_writer.add(0x401, "b")
      to_unicode_writer.add(0x402, "ff")
      to_unicode_writer.add(0x403, "fi")
      to_unicode_writer.add(0x404, "ffl")

      baos = IO::Memory.new
      to_unicode_writer.write_to(baos)
      output = baos.to_s

      output.should contain("4 beginbfrange")
      output.should contain("<0402> <0402> <00660066>")
      output.should contain("<0403> <0403> <00660069>")
      output.should contain("<0404> <0404> <00660066006C>")
    end
  end

  describe "testCMapCIDOverflow" do
    it "handles CID overflow correctly" do
      to_unicode_writer = Pdfbox::Pdmodel::Font::ToUnicodeWriter.new

      to_unicode_writer.add(0x3ff, "6")
      to_unicode_writer.add(0x400, "7")

      baos = IO::Memory.new
      to_unicode_writer.write_to(baos)
      output = baos.to_s

      output.should contain("2 beginbfrange")
      output.should contain("<03FF> <03FF> <0036>")
      output.should contain("<0400> <0400> <0037>")
    end
  end

  describe "testCMapStringOverflow" do
    it "handles string overflow correctly" do
      to_unicode_writer = Pdfbox::Pdmodel::Font::ToUnicodeWriter.new

      # Create strings with codepoints 0x04FF and 0x0500
      string1 = "\u04FF"
      string2 = "\u0500"

      to_unicode_writer.add(0x3ff, string1)
      to_unicode_writer.add(0x400, string2)

      baos = IO::Memory.new
      to_unicode_writer.write_to(baos)
      output = baos.to_s

      output.should contain("2 beginbfrange")
      output.should contain("<03FF> <03FF> <04FF>")
      output.should contain("<0400> <0400> <0500>")
    end
  end

  describe "testCMapSurrogates" do
    it "handles surrogate pairs correctly" do
      to_unicode_writer = Pdfbox::Pdmodel::Font::ToUnicodeWriter.new

      # Strings with supplementary plane codepoints (require UTF-16 surrogate pairs)
      string1 = "\u{2F874}"
      string2 = "\u{2F876}"
      string3 = "\u{2F884}"

      to_unicode_writer.add(0x300, string1)
      to_unicode_writer.add(0x301, string2)
      to_unicode_writer.add(0x304, string3)

      baos = IO::Memory.new
      to_unicode_writer.write_to(baos)
      output = baos.to_s

      output.should contain("3 beginbfrange")
      output.should contain("<0300> <0300> <D87EDC74>") # UTF-16BE for U+2F874
      output.should contain("<0301> <0301> <D87EDC76>") # UTF-16BE for U+2F876
      output.should contain("<0304> <0304> <D87EDC84>") # UTF-16BE for U+2F884
    end
  end

  describe "testAllowCIDToUnicodeRange" do
    it "checks CID-to-Unicode range eligibility" do
      six = {0x03FF, "6"}
      seven = {0x0400, "7"}
      eight = {0x0401, "8"}

      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_cid_to_unicode_range(nil, seven).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_cid_to_unicode_range(six, nil).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_cid_to_unicode_range(six, seven).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_cid_to_unicode_range(seven, eight).should be_true
    end
  end

  describe "testAllowCodeRange" do
    it "checks code range eligibility" do
      # Denied progressions (negative)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x000F, 0x0007).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x00FF, 0x0000).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x03FF, 0x0300).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0401, 0x0400).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0xFFFF, 0x0000).should be_false

      # Denied progressions (non sequential)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0000, 0x0000).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0000, 0x000F).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0000, 0x007F).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0000, 0x00FF).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0007, 0x000F).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x007F, 0x00FF).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x00FF, 0x00FF).should be_false

      # Denied progressions (overflow)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x00FF, 0x0100).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x01FF, 0x0200).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x03FF, 0x0400).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x07FF, 0x0800).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0FFF, 0x1000).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x1FFF, 0x2000).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x3FFF, 0x4000).should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x7FFF, 0x8000).should be_false

      # Allowed progressions (positive, sequential, and w/o overflow)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x00, 0x01).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x01, 0x02).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x03, 0x04).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x07, 0x08).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0E, 0x0F).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x1F, 0x20).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x3F, 0x40).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x7F, 0x80).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0xFE, 0xFF).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x03FE, 0x03FF).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0x0400, 0x0401).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_code_range(0xFFFE, 0xFFFF).should be_true
    end
  end

  describe "testAllowDestinationRange" do
    it "checks destination range eligibility" do
      # Denied (bogus)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("", "").should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("0", "").should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("", "0").should be_false

      # Denied (non sequential)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("0", "A").should be_false
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("A", "a").should be_false

      # Denied (overflow)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("\u00FF", "\u0100").should be_false

      # Allowed (sequential w/o surrogate)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range(" ", "!").should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("(", ")").should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("0", "1").should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("a", "b").should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("A", "B").should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("\u00C0", "\u00C1").should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("\u00FE", "\u00FF").should be_true

      # Denied (ligatures)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range("ff", "fi").should be_false
    end
  end

  describe "testAllowDestinationRangeSurrogates" do
    it "checks surrogate destination range eligibility" do
      end_of_bmp = "\uFFFF"
      beyond_bmp = "\u{10000}"
      cjk1 = "\u{2F884}"
      cjk2 = "\u{2F885}"
      cjk3 = "\u{2F886}"

      # Denied (overflow)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range(end_of_bmp, beyond_bmp).should be_false
      # Allowed (sequential surrogates)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range(cjk1, cjk2).should be_true
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range(cjk2, cjk3).should be_true
      # Denied (non sequential surrogates)
      Pdfbox::Pdmodel::Font::ToUnicodeWriter.allow_destination_range(cjk1, cjk3).should be_false
    end
  end
end

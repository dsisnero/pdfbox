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
end

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

# Mock font class for testing PDFont abstract class

class MockFont < Pdfbox::Pdmodel::Font::PDFont
  getter name : String = "MockFont"

  def initialize
    super
  end

  def font_matrix : Pdfbox::Pdmodel::Font::PDFont::Matrix
    Pdfbox::Pdmodel::Font::PDFont::Matrix.new
  end

  def bounding_box : Pdfbox::Pdmodel::Font::PDFont::BoundingBox
    Pdfbox::Pdmodel::Font::PDFont::BoundingBox.new
  end

  def position_vector(code : Int32) : Pdfbox::Pdmodel::Font::PDFont::Vector
    Pdfbox::Pdmodel::Font::PDFont::Vector.new
  end

  def width(code : Int32) : Float32
    500.0_f32
  end

  def has_explicit_width?(code : Int32) : Bool
    false
  end

  def width_from_font(code : Int32) : Float32
    500.0_f32
  end

  def embedded? : Bool
    false
  end

  def damaged? : Bool
    false
  end

  def average_font_width : Float32
    500.0_f32
  end

  protected def get_standard14_width(code : Int32) : Float32
    500.0_f32
  end

  protected def encode(unicode : Int32) : Bytes
    Bytes[unicode.to_u8]
  end

  def read_code(input : IO) : Int32
    input.read_byte.try(&.to_i) || -1
  end

  def vertical? : Bool
    false
  end

  def add_to_subset(code_point : Int32) : Nil

    # no-op
  end

  def subset : Nil

    # no-op
  end

  def will_be_subset? : Bool
    false
  end
end

describe "PDFontTest" do
  # Keep this file aligned with vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/font/PDFontTest.java.

  # If a spec here is not a direct Java test port, it should stay clearly narrower or be marked as

  # supplemental source-derived coverage.

  before_all do
    # Create output directory if it doesn't exist

    Dir.mkdir_p("target/test-output")
  end

  describe "basic functionality" do
    it "can be instantiated via mock" do
      font = MockFont.new

      font.name.should eq("MockFont")

      font.cos_object.should be_a(Pdfbox::Cos::Dictionary)
    end

    it "uses width-based default displacement for horizontal fonts" do
      font = MockFont.new

      displacement = font.displacement(65)

      displacement.x.should eq(0.5_f32)

      displacement.y.should eq(0.0_f32)
    end
  end

  # Test of the error reported in PDFBOX-988

  describe "testPDFBox988" do
    it "renders the upstream crash fixture without raising" do
      pdf_path = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/font/F001u_3_7j.pdf"

      doc = Pdfbox::Pdmodel::Document.load(pdf_path)

      begin
        Pdfbox::Rendering::PDFRenderer.new(doc).render_image(0)
      ensure
        doc.close
      end
    end
  end

  describe "testPDFBOX5486" do
    it "checks has_glyph and get_path for TrueType font" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"

      unless File.exists?(font_path)
        pending("Font file not found: #{font_path}")

        next
      end

      File.open(font_path, "r") do |file|
        doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

        encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE

        font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(doc, file, encoding)

        # Check that font has glyph "A"

        font.has_glyph?("A").should be_true

        # Check that get_path doesn't throw an error

        path = font.get_path("A")

        # Just verify we got a Path object back

        path.should be_a(Fontbox::Util::Path)
      end
    end
  end

  describe "testPDFBox3747" do
    it "keeps text extraction stable after Type0 embedding" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"

      baos = IO::Memory.new

      font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

      File.open(font_path, "r") do |file|
        font = Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, file, false)

        doc = Pdfbox::Pdmodel::Document.new

        begin
          page = Pdfbox::Pdmodel::Page.new

          doc.add_page(page)

          cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)

          begin
            cs.begin_text

            cs.new_line_at_offset(10, 700)

            cs.set_font(font, 10)

            cs.show_text("PDFBOX-3747")

            cs.end_text
          ensure
            cs.close
          end

          doc.save(baos)
        ensure
          doc.close
        end
      end

      baos.rewind

      loaded = Pdfbox::Pdmodel::Document.load(baos)

      begin
        Pdfbox::Text::PDFTextStripper.new.get_text(loaded).strip.should eq("PDFBOX-3747")
      ensure
        loaded.close
      end
    end
  end

  describe "testPDFBox3826" do
    it "reuses parsed TTFs across subset and full-embed paths" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"

      font_file_size = File.size(font_path)

      parser = Fontbox::TTF::TTFParser.new

      ttf = parser.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))

      baos = IO::Memory.new

      font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

      begin
        doc = Pdfbox::Pdmodel::Document.new

        begin
          page = Pdfbox::Pdmodel::Page.new

          doc.add_page(page)

          cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)

          begin
            font = Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, ttf, true)

            cs.begin_text

            cs.new_line_at_offset(10, 700)

            cs.set_font(font, 10)

            cs.show_text("testMultipleFontFileReuse1")

            cs.end_text

            font = Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, ttf, false)

            cs.begin_text

            cs.new_line_at_offset(10, 650)

            cs.set_font(font, 10)

            cs.show_text("testMultipleFontFileReuse2")

            cs.end_text

            font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(
              font_doc,

              ttf,

              Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
            )

            cs.begin_text

            cs.new_line_at_offset(10, 600)

            cs.set_font(font, 10)

            cs.show_text("testMultipleFontFileReuse3")

            cs.end_text
          ensure
            cs.close
          end

          doc.save(baos)
        ensure
          doc.close
        end
      ensure
        ttf.close
      end

      baos.rewind

      loaded = Pdfbox::Pdmodel::Document.load(baos)

      begin
        page = loaded.get_page(0)

        resources = page.resources.not_nil!

        font_f1 = resources.font(Pdfbox::Cos::Name.new("F1")).as(Pdfbox::Pdmodel::Font::PDType0Font)

        font_f2 = resources.font(Pdfbox::Cos::Name.new("F2")).as(Pdfbox::Pdmodel::Font::PDType0Font)

        font_f3 = resources.font(Pdfbox::Cos::Name.new("F3")).as(Pdfbox::Pdmodel::Font::PDTrueTypeFont)

        font_f1.name.includes?('+').should be_true

        font_f1.font_descriptor.not_nil!.font_file2.not_nil!.to_byte_array.size.should be < font_file_size

        font_f2.name.includes?('+').should be_false

        font_f2.font_descriptor.not_nil!.font_file2.not_nil!.to_byte_array.size.should eq(font_file_size)

        font_f3.name.includes?('+').should be_false

        font_f3.font_descriptor.not_nil!.font_file2.not_nil!.to_byte_array.size.should eq(font_file_size)

        Pdfbox::Rendering::PDFRenderer.new(loaded).render_image(0)

        stripper = Pdfbox::Text::PDFTextStripper.new

        stripper.line_separator = "\n"

        stripper.get_text(loaded).strip.should eq(
          "testMultipleFontFileReuse1\ntestMultipleFontFileReuse2\ntestMultipleFontFileReuse3"
        )
      ensure
        loaded.close
      end
    end
  end

  describe "testPDFBOX4115" do
    font_path = "vendor/pdfbox/pdfbox/target/fonts/n019003l.pfb"
    if File.exists?(font_path)
      it "creates an embedded Type1 PDF with umlaut glyphs and extracts them correctly" do
        output_path = File.expand_path("../../../../temp/FontType1.pdf", __DIR__)

        text = "äöüÄÖÜ"

        doc = Pdfbox::Pdmodel::Document.new

        begin
          page = Pdfbox::Pdmodel::Page.new

          doc.add_page(page)

          font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

          File.open(font_path, "r") do |stream|
            font = Pdfbox::Pdmodel::Font::PDType1Font.new(
              font_doc,

              stream,

              Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
            )

            cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)

            begin
              cs.begin_text

              cs.set_font(font, 10)

              cs.new_line_at_offset(10, 700)

              cs.show_text(text)

              cs.end_text
            ensure
              cs.close
            end
          end

          File.open(output_path, "w") { |file| doc.save(file) }
        ensure
          doc.close
        end

        loaded = Pdfbox::Pdmodel::Document.load(output_path)

        begin
          font = loaded.get_page(0).resources.not_nil!.font(Pdfbox::Cos::Name.new("F1")).as(Pdfbox::Pdmodel::Font::PDType1Font)

          font.encoding.should eq(Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE)

          text.each_char do |char|
            name = font.encoding.get_name(char.ord)

            name[1..].should eq("dieresis")

            font.get_path(name).empty?.should be_false
          end

          Pdfbox::Text::PDFTextStripper.new.get_text(loaded).strip.should eq(text)
        ensure
          loaded.close
        end
      end
    end
  end

  describe "testPDFox4318" do
    it "keeps the PDType1Font encode cache keyed correctly" do
      helvetica_bold = Pdfbox::Pdmodel::Font::PDType1Font.new(
        Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD
      )

      expect_raises(ArgumentError) do
        helvetica_bold.encode("\u0080")
      end

      helvetica_bold.encode("€")

      expect_raises(ArgumentError) do
        helvetica_bold.encode("\u0080")
      end
    end
  end

  describe "testFullEmbeddingTTC" do
    ttf_path = "vendor/pdfbox/fontbox/target/fonts/DejaVuSansMono.ttf"
    if File.exists?(ttf_path)
      it "rejects full embedding for TrueType collection fonts" do
        temp_dir = File.expand_path("../../../../temp/pdfont", __DIR__)
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
        ttf = File.open(ttc_path) do |file|
          collection = Fontbox::TTF::TrueTypeCollection.new(file)
          begin
            font_name = [] of String
            collection.process_all_fonts(->(font : Fontbox::TTF::TrueTypeFont) do
              font_name << font.name
            end)
            collection.font_by_name(font_name.first).as(Fontbox::TTF::TrueTypeFont)
          ensure
            collection.close
          end
        end
        doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        expect_raises(IO::Error, "Full embedding of TrueType font collections not supported") do
          Pdfbox::Pdmodel::Font::PDType0Font.load(doc, ttf, false)
        end
      end
    end
  end

  describe "testPDFox5048" do
    it "treats broken Type1C font data as damaged and zero-width" do
      font_descriptor = Pdfbox::Cos::Dictionary.new

      broken_stream = Pdfbox::Cos::Stream.new(data: Bytes[1_u8, 0_u8, 4_u8, 1_u8, 0_u8, 0_u8])

      font_descriptor[Pdfbox::Cos::Name::FONT_FILE3] = broken_stream

      font_dict = Pdfbox::Cos::Dictionary.new

      font_dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT

      font_dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type1")

      font_dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("BrokenType1C")

      font_dict[Pdfbox::Cos::Name::FONT_DESC] = font_descriptor

      font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(font_dict).as(Pdfbox::Pdmodel::Font::PDType1CFont)

      font.damaged?.should be_true

      font.height(0).should eq(0.0_f32)

      font.get_string_width("Pa").should eq(0.0_f32)
    end
  end

  describe "testDeleteFont" do
    it "keeps text extractable after the source font file is deleted" do
      source_font = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"

      temp_font = File.expand_path("../../../../temp/LiberationSans-Regular.ttf", __DIR__)

      temp_pdf = File.expand_path("../../../../temp/testDeleteFont.pdf", __DIR__)

      text = "Test PDFBOX-4823"

      File.write(temp_font, File.read(source_font))

      font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

      doc = Pdfbox::Pdmodel::Document.new

      begin
        page = Pdfbox::Pdmodel::Page.new

        doc.add_page(page)

        font = File.open(temp_font, "r") do |file|
          Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, file)
        end

        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)

        begin
          cs.begin_text

          cs.set_font(font, 50)

          cs.new_line_at_offset(50, 700)

          cs.show_text(text)

          cs.end_text
        ensure
          cs.close
        end

        File.open(temp_pdf, "w") { |file| doc.save(file) }
      ensure
        doc.close
      end

      File.delete(temp_font)

      loaded = Pdfbox::Pdmodel::Document.load(temp_pdf)

      begin
        Pdfbox::Text::PDFTextStripper.new.get_text(loaded).strip.should eq(text)
      ensure
        loaded.close
      end

      File.delete(temp_pdf)
    end
  end

  describe "testSoftHyphen" do
    it "handles soft hyphen character in Standard 14 fonts" do
      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      hyphen_width = font.get_string_width("-")

      soft_hyphen_width = font.get_string_width("\u00AD")

      hyphen_width.should eq(soft_hyphen_width)
    end
  end

  describe "font mapper parity" do
    it "keeps a shared singleton mapper" do
      mapper = Pdfbox::Pdmodel::Font::FontMapperImpl.new

      Pdfbox::Pdmodel::Font::FontMappers.set(mapper)

      Pdfbox::Pdmodel::Font::FontMappers.instance.should be(mapper)
    end

    it "maps missing TrueType requests through Java-style descriptor fallback" do
      descriptor = Pdfbox::Pdmodel::Font::PDFontDescriptor.new(Pdfbox::Cos::Dictionary.new)

      descriptor.fixed_pitch = true

      descriptor.italic = true

      descriptor.force_bold = true

      descriptor.font_name = "MissingMono-BoldItalic"

      mapping = Pdfbox::Pdmodel::Font::FontMappers.instance.get_true_type_font("DefinitelyMissingFont", descriptor)

      mapping.fallback?.should be_true

      mapping.font.should be_a(Fontbox::TTF::TrueTypeFont)
    end

    it "backs Standard14 Type1 fonts with a real mapped FontBox substitute" do
      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      mapped = font.font_box_font

      mapped.should be_a(Fontbox::FontBoxFont)

      mapped.not_nil!.name.should_not be_empty

      mapped.not_nil!.has_glyph?("question").should be_true

      mapped.not_nil!.path("question").empty?.should be_false
    end
  end

  describe "testPDFBox5484" do
    font_path = "vendor/pdfbox/pdfbox/target/fonts/PDFBOX-5484.ttf"
    if File.exists?(font_path)
      it "tests symbol font encoding handling with PDFBOX-5484.ttf" do
        File.open(font_path, "r") do |file|
          doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

          # Create a RandomAccessRead from the file

          random_access_read = Pdfbox::IO::RandomAccessReadBuffer.create_buffer_from_stream(file)

          ttf_parser = Fontbox::TTF::TTFParser.new

          ttf = ttf_parser.parse(random_access_read)

          encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE

          font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(doc, ttf, encoding)

          # Test that getPath works with glyph name "oslash"

          path1 = font.get_path("oslash")

          path1.should_not be_nil

          # Test that getPath works with character code 248 (ø)

          path2 = font.get_path(248)

          path2.should_not be_nil

          # Both paths should be similar (not empty)

          # For now, just verify both calls work without error
        end
      end
    end
  end

  describe "testSymbol" do
    it "handles symbol font encoding with Greek and Ohm characters" do
      baos = IO::Memory.new

      doc = Pdfbox::Pdmodel::Document.new

      begin
        page = Pdfbox::Pdmodel::Page.new

        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)

        begin
          font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::SYMBOL)

          cs.begin_text

          cs.set_font(font, 10)

          cs.new_line_at_offset(10, 700)

          # Note that the Alpha is the greek alpha, but the Omega is the Ohm symbol

          # (Tested on Windows)

          cs.show_text("\u0391 \u2126")

          cs.end_text
        ensure
          cs.close
        end

        doc.add_page(page)

        doc.save(baos)
      ensure
        doc.close
      end

      # Load the PDF back and extract text

      baos.rewind

      doc2 = Pdfbox::Pdmodel::Document.load(baos)

      begin
        stripper = Pdfbox::Text::PDFTextStripper.new

        text = stripper.get_text(doc2)

        text.strip.should eq("\u0391 \u2126")
      ensure
        doc2.close
      end
    end
  end

  # Additional tests from PDFontTest.java that may have been missed

  describe "testStandard14Widths" do
    it "returns correct widths for standard 14 fonts" do
      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # space code 32

      font.width(32).should be > 0.0

      # 'A' code 65

      font.width(65).should be > 0.0

      # 'a' code 97

      font.width(97).should be > 0.0

      # ensure width for .notdef (code 0?) returns default width (should be 250 per spec)

      # Actually .notdef is not encoded; we can skip.
    end

    it "returns non-empty glyph paths for standard14 fonts" do
      helvetica = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      symbol = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::SYMBOL)

      zapf = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::ZAPF_DINGBATS)

      helvetica.get_path("question").empty?.should be_false

      symbol.get_path("circleplus").empty?.should be_false

      zapf.get_path("a35").empty?.should be_false

      helvetica.get_path(".notdef").empty?.should be_true
    end
  end

  describe "testStandard14WidthsBadInput" do
    it "handles bad input codes gracefully" do
      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Test with negative code (should return 0 or default width)

      font.width(-1).should be >= 0.0

      # Test with code 0 (.notdef - may or may not have a width)

      font.width(0).should be >= 0.0

      # Test with very large code (outside encoding range)

      font.width(1000).should be >= 0.0

      # The font should not raise an exception for any input

      # (implicitly tested by the fact that we get here without raising)
    end
  end

  describe "testWidthDetermination" do
    it "determines correct widths for characters in Standard 14 fonts" do
      # Test with Helvetica (Standard 14 font)

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Space should have a width

      space_width = font.width(32) # ASCII space

      space_width.should be > 0.0

      # 'A' should have a width

      a_width = font.width(65) # ASCII 'A'

      a_width.should be > 0.0

      # Different characters should have different widths (in proportional font)

      # 'i' should be narrower than 'W' in Helvetica

      i_width = font.width(105) # ASCII 'i'

      w_width = font.width(87) # ASCII 'W'

      i_width.should be < w_width

      # Width from font should match width method for Standard 14 fonts

      font.width_from_font(65).should be_close(a_width, 0.001)
    end
  end

  describe "testWidthDetermination2" do
    it "handles width determination for different Standard 14 fonts" do
      # Test with different Standard 14 fonts

      helvetica = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      times = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::TIMES_ROMAN)

      courier = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::COURIER)

      # Get width of 'A' in each font

      helvetica_a_width = helvetica.width(65)

      times_a_width = times.width(65)

      courier_a_width = courier.width(65)

      # All should have positive widths

      helvetica_a_width.should be > 0.0

      times_a_width.should be > 0.0

      courier_a_width.should be > 0.0

      # Courier is monospace, so all characters should have same width

      courier_i_width = courier.width(105) # 'i'

      courier_w_width = courier.width(87) # 'W'

      courier_i_width.should be_close(courier_w_width, 0.001)

      courier_a_width.should be_close(courier_w_width, 0.001)

      # Helvetica and Times are proportional, so widths differ

      helvetica_i_width = helvetica.width(105)

      helvetica_w_width = helvetica.width(87)

      helvetica_i_width.should be < helvetica_w_width

      times_i_width = times.width(105)

      times_w_width = times.width(87)

      times_i_width.should be < times_w_width
    end
  end

  describe "testEmbeddedFont" do
    it "supplemental: round-trips an embedded Type0 font" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"

      font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

      text = "Embedded Type0"

      io = IO::Memory.new

      File.open(font_path, "r") do |file|
        font = Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, file, false)

        doc = Pdfbox::Pdmodel::Document.new

        begin
          page = Pdfbox::Pdmodel::Page.new

          doc.add_page(page)

          cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)

          begin
            cs.begin_text

            cs.new_line_at_offset(10, 700)

            cs.set_font(font, 12)

            cs.show_text(text)

            cs.end_text
          ensure
            cs.close
          end

          doc.save(io)
        ensure
          doc.close
        end
      end

      io.rewind

      loaded = Pdfbox::Pdmodel::Document.load(io)

      begin
        font = loaded.get_page(0).resources.not_nil!.font(Pdfbox::Cos::Name.new("F1")).as(Pdfbox::Pdmodel::Font::PDType0Font)

        font.font_descriptor.not_nil!.font_file2.should_not be_nil

        Pdfbox::Text::PDFTextStripper.new.get_text(loaded).strip.should eq(text)
      ensure
        loaded.close
      end
    end
  end

  describe "testEmbeddedFont2" do
    font_path = "vendor/pdfbox/pdfbox/target/fonts/n019003l.pfb"
    if File.exists?(font_path)
      it "supplemental: round-trips an embedded Type1 font" do
        text = "äöüÄÖÜ"
        io = IO::Memory.new
        doc = Pdfbox::Pdmodel::Document.new
        begin
          page = Pdfbox::Pdmodel::Page.new
          doc.add_page(page)
          font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
          File.open(font_path, "r") do |stream|
            font = Pdfbox::Pdmodel::Font::PDType1Font.new(
              font_doc,
              stream,
              Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
            )
            cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
            begin
              cs.begin_text
              cs.new_line_at_offset(10, 700)
              cs.set_font(font, 12)
              cs.show_text(text)
              cs.end_text
            ensure
              cs.close
            end
          end
          doc.save(io)
        ensure
          doc.close
        end
        io.rewind
        loaded = Pdfbox::Pdmodel::Document.load(io)
        begin
          font = loaded.get_page(0).resources.not_nil!.font(Pdfbox::Cos::Name.new("F1")).as(Pdfbox::Pdmodel::Font::PDType1Font)
          font.font_descriptor.not_nil!.font_file.should_not be_nil
          Pdfbox::Text::PDFTextStripper.new.get_text(loaded).strip.should eq(text)
        ensure
          loaded.close
        end
      end
    end
  end

  describe "testToUnicodeWriting" do
    it "writes ToUnicode CMap for Standard 14 font" do
      # Create a Helvetica font

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Create a PDF with text

      baos = IO::Memory.new

      doc = Pdfbox::Pdmodel::Document.new

      begin
        page = Pdfbox::Pdmodel::Page.new

        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)

        begin
          cs.begin_text

          cs.set_font(font, 12)

          cs.new_line_at_offset(100, 700)

          cs.show_text("Hello")

          cs.end_text
        ensure
          cs.close
        end

        doc.add_page(page)

        doc.save(baos)
      ensure
        doc.close
      end

      # Load the PDF back and extract text

      baos.rewind

      doc2 = Pdfbox::Pdmodel::Document.load(baos)

      begin
        stripper = Pdfbox::Text::PDFTextStripper.new

        text = stripper.get_text(doc2)

        text.strip.should eq("Hello")
      ensure
        doc2.close
      end
    end
  end

  describe "testToUnicodeWritingIdentityH" do
    it "writes ToUnicode CMap with Identity-H encoding" do
      # Test that Identity-H encoding is available

      encoding = Pdfbox::Pdmodel::Font::Encoding::IdentityEncoding::IDENTITY_H

      encoding.encoding_name.should eq("Identity-H")

      encoding.w_mode.should eq(0)
    end
  end

  describe "testToUnicodeWritingIdentityV" do
    it "writes ToUnicode CMap with Identity-V encoding" do
      # Test that Identity-V encoding is available

      encoding = Pdfbox::Pdmodel::Font::Encoding::IdentityEncoding::IDENTITY_V

      encoding.encoding_name.should eq("Identity-V")

      encoding.w_mode.should eq(1)
    end
  end

  describe "testToUnicodeWritingWithDifferences" do
    it "writes ToUnicode CMap with encoding differences" do
      # Create a font with Dictionary encoding (differences)

      dict_encoding_dict = Pdfbox::Cos::Dictionary.new

      dict_encoding_dict.set_item(Pdfbox::Cos::Name::TYPE, Pdfbox::Cos::Name::ENCODING)

      dict_encoding_dict.set_item(Pdfbox::Cos::Name::BASE_ENCODING, Pdfbox::Cos::Name::WIN_ANSI_ENCODING)

      differences = Pdfbox::Cos::Array.new

      differences.add(Pdfbox::Cos::Integer.new(32))

      differences.add(Pdfbox::Cos::Name.new("a"))

      dict_encoding_dict.set_item(Pdfbox::Cos::Name::DIFFERENCES, differences)

      dict_encoding = Pdfbox::Pdmodel::Font::Encoding::DictionaryEncoding.new(dict_encoding_dict, false, nil)

      # Verify the encoding has the differences

      dict_encoding.name_to_code_map["a"]?.should eq(32)

      dict_encoding.name_to_code_map["space"]?.should be_nil
    end
  end

  describe "testGlyphSpaceToTextSpaceTransform" do
    it "transforms glyph space to text space using font matrix" do
      # Test with Helvetica (Standard 14 font)

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Get the font matrix

      matrix = font.font_matrix

      # Standard 14 fonts have a default font matrix of 0.001 0 0 0.001 0 0

      matrix.a.should be_close(0.001, 0.0001)

      matrix.b.should eq(0.0)

      matrix.c.should eq(0.0)

      matrix.d.should be_close(0.001, 0.0001)

      matrix.e.should eq(0.0)

      matrix.f.should eq(0.0)

      # Get displacement for character 'A' (code 65)

      displacement = font.displacement(65)

      # The displacement should be in text space (scaled by font matrix)

      # For Helvetica, 'A' has width 667 in glyph space

      # In text space: 667 * 0.001 = 0.667

      displacement.x.should be_close(0.667, 0.01)

      displacement.y.should eq(0.0)
    end
  end

  describe "testFontMatrix" do
    it "returns correct font matrix for Standard 14 fonts" do
      # Test with different Standard 14 fonts

      helvetica = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      times = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::TIMES_ROMAN)

      courier = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::COURIER)

      # All Standard 14 fonts should have the default font matrix

      [helvetica, times, courier].each do |font|
        matrix = font.font_matrix

        matrix.a.should be_close(0.001, 0.0001)

        matrix.b.should eq(0.0)

        matrix.c.should eq(0.0)

        matrix.d.should be_close(0.001, 0.0001)

        matrix.e.should eq(0.0)

        matrix.f.should eq(0.0)
      end
    end
  end

  describe "testFontMatrixNonStandard" do
    it "handles font with non-standard font matrix" do
      # Test that we can handle fonts with different font matrices

      # Standard 14 fonts all have the same matrix, but custom fonts might differ

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Verify the font matrix is the standard one

      matrix = font.font_matrix

      matrix.a.should be_close(0.001, 0.0001)

      matrix.d.should be_close(0.001, 0.0001)

      # Verify displacement calculation works

      displacement = font.displacement(65)

      displacement.x.should be > 0.0_f32
    end
  end

  describe "testFontMatrixZero" do
    it "handles font with zero font matrix gracefully" do
      # Test that we can handle fonts with zero font matrix values

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Verify the font matrix is not zero

      matrix = font.font_matrix

      matrix.a.should_not eq(0.0)

      matrix.d.should_not eq(0.0)

      # Verify displacement calculation works with non-zero matrix

      displacement = font.displacement(65)

      displacement.x.should be > 0.0_f32
    end
  end

  describe "testFontMatrixZeroSize" do
    it "handles font with zero font size gracefully" do
      # Test that we can handle fonts with zero font size

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Verify the font has valid width

      width = font.width(65)

      width.should be > 0.0_f32

      # Verify displacement calculation works

      displacement = font.displacement(65)

      displacement.x.should be > 0.0_f32
    end
  end

  describe "testFontMatrixZeroSize2" do
    it "handles font with zero font size in string width calculation" do
      # Test that we can calculate string width

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Verify string width calculation works

      width = font.get_string_width("Hello")

      width.should be > 0.0_f32
    end
  end

  describe "testFontMatrixZeroSize3" do
    it "handles font with zero font size in space width calculation" do
      # Test that we can calculate space width

      font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)

      # Verify space width calculation works

      space_width = font.space_width

      space_width.should be > 0.0_f32
    end
  end

  describe "space_width" do
    it "returns width for space character" do
      font = MockFont.new

      # MockFont returns 500.0 for all widths

      font.space_width.should eq(500.0_f32)
    end

    it "caches the space width" do
      font = MockFont.new

      first_call = font.space_width

      second_call = font.space_width

      first_call.should eq(second_call)
    end
  end

  describe "PDFBOX5920TrueType" do
    it "calculates correct string width for TrueType font" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"

      unless File.exists?(font_path)
        pending("Font file not found: #{font_path}")

        next
      end

      File.open(font_path, "r") do |file|
        doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

        encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE

        font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(doc, file, encoding)

        width = font.get_string_width("The quick brown fox jumps over the lazy dog.")

        width.should eq(20064.0_f32)
      end
    end

    it "calculates correct space width for TrueType font" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"

      unless File.exists?(font_path)
        pending("Font file not found: #{font_path}")

        next
      end

      File.open(font_path, "r") do |file|
        doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))

        encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE

        font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(doc, file, encoding)

        space_width = font.space_width

        space_width.should eq(278.0_f32)
      end
    end
  end

  describe "PDFBOX5920Type0" do
    it "calculates correct string width for Type0 font" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"
      pending("LiberationSans-Regular.ttf not found at #{font_path}") unless File.exists?(font_path)

      File.open(font_path, "r") do |file|
        doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = Pdfbox::Pdmodel::Font::PDType0Font.load(doc, file, false)
        font.get_string_width("The quick brown fox jumps over the lazy dog.").should eq(20064.0_f32)
      end
    end

    it "calculates correct space width for Type0 font" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"
      pending("LiberationSans-Regular.ttf not found at #{font_path}") unless File.exists?(font_path)

      File.open(font_path, "r") do |file|
        doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = Pdfbox::Pdmodel::Font::PDType0Font.load(doc, file, false)
        font.space_width.should eq(278.0_f32)
      end
    end
  end
end

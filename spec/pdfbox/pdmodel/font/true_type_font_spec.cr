require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/true_type_font"
require "../../../../src/pdfbox/loader"

describe Pdfbox::Pdmodel::Font::PDTrueTypeFont do
  describe ".load" do
    it "embeds a simple TrueType font with the requested encoding" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"
      encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
      begin
        file = ::File.new(font_path)
        doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(doc, file, encoding)

        font.embedded?.should be_true
        font.damaged?.should be_false
        font.encoding.should eq(encoding)
        font.name.should eq("LiberationSans")
        font.true_type_font.should_not be_nil
        font.font_box_font.should eq(font.true_type_font)
        font.read_code(IO::Memory.new(Bytes[0x41_u8])).should eq(0x41)
      end
    ensure
      file.try(&.close)
      doc.try(&.close)
    end

    pending "extracts outlines from OpenType/CFF fonts through the PDTrueTypeFont surface" do
      otf_path = "vendor/pdfbox/fontbox/src/test/resources/otf/FoglihtenNo07.otf"
      unless File.exists?(otf_path)
        pending("Font fixture not found: #{otf_path}")
        next
      end

      begin
        font = Fontbox::TTF::OTFParser.new.parse(
          Pdfbox::IO::RandomAccessReadBufferedFile.new(otf_path)
        )

        doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        pd_font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(
          doc,
          font,
          Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
        )

        pd_font.true_type_font.should eq(font)
        pd_font.get_path("A").empty?.should be_false
        pd_font.get_path(0x41).empty?.should be_false
        pd_font.get_normalized_path(0x41).empty?.should be_false
        pd_font.average_font_width.should be > 0.0_f32
      ensure
        doc.try(&.close)
        font.try(&.close)
      end
    end
  end

  describe "dictionary loading" do
    it "reloads an embedded FontFile2 font from the saved dictionary" do
      font_path = "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"
      encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
      pdf_bytes = IO::Memory.new
      begin
        file = ::File.new(font_path)
        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.load(font_doc, file, encoding)
        doc = Pdfbox::Pdmodel::Document.new
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)
        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        content_stream.begin_text
        content_stream.set_font(font, 12.0_f32)
        content_stream.new_line_at_offset(72.0_f32, 720.0_f32)
        content_stream.show_text("Hello")
        content_stream.end_text
        content_stream.close
        doc.save(pdf_bytes)
      end
      file.close
      doc.close

      loaded = Pdfbox::Loader.load_pdf(pdf_bytes.to_slice)
      font_dict = loaded.get_page(0).resources.not_nil!
        .font(Pdfbox::Cos::Name.new("F1"))
        .as(Pdfbox::Pdmodel::Font::PDTrueTypeFont)
        .cos_object

      font = Pdfbox::Pdmodel::Font::PDTrueTypeFont.new(font_dict)

      font.embedded?.should be_true
      font.damaged?.should be_false
      font.true_type_font.should_not be_nil
      font.bounding_box.width.should be > 0.0_f32
      font.width_from_font(0x41).should be > 0.0_f32
      font.has_glyph(0x41).should be_true
      font.get_normalized_path(0x41).empty?.should be_false
    ensure
      file.try { |file_obj| file_obj.close unless file_obj.closed? }
      font_doc.try(&.close)
      doc.try(&.close)
      loaded.try(&.close)
    end
  end
end

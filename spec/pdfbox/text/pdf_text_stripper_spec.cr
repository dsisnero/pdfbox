require "../../spec_helper"

describe Pdfbox::Text::PDFTextStripper do
  it "extracts text from hello3.pdf using the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")
    expected_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf.txt")

    expected = File.read(expected_path, encoding: "UTF-8")
    expected = expected[1..] if expected.starts_with?('\uFEFF')
    expected = expected.strip

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      actual = Pdfbox::Text::PDFTextStripper.new.get_text(doc).strip
      actual.should eq(expected)
    ensure
      doc.close
    end
  end

  it "extracts only page 2 of eu-001.pdf like the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/eu-001.pdf")

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.start_page = 2
      stripper.end_page = 2

      text = stripper.get_text(doc).gsub('\r', "").strip
      text.starts_with?("Pesticides").should be_true
      text.ends_with?("1 000 10 10").should be_true
      text.size.should eq(1378)
    ensure
      doc.close
    end
  end

  it "ignores content-stream space glyphs like the Java fixture" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      page = Pdfbox::Pdmodel::Page.new

      content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
      begin
        font_height = 8
        x = 50
        y = page.media_box.not_nil!.height - 50
        font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
        content_stream.begin_text
        content_stream.set_font(font, font_height)
        content_stream.new_line_at_offset(x, y)
        content_stream.show_text("(                                      )")
        content_stream.end_text

        indent = 6
        overlap_x = x + indent * font.average_font_width / 1000.0_f32 * font_height
        overlap_font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::TIMES_ROMAN)
        content_stream.begin_text
        content_stream.set_font(overlap_font, font_height * 2)
        content_stream.new_line_at_offset(overlap_x, y)
        content_stream.show_text("overlap")
        content_stream.end_text
      ensure
        content_stream.close
      end

      doc.add_page(page)

      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.page_end = "\n"
      stripper.start_page = 1
      stripper.end_page = 1
      stripper.sort_by_position = true
      stripper.ignore_content_stream_space_glyphs = true

      stripper.get_text(doc).should eq("( overlap )\n")
    ensure
      doc.close
    end
  end
end

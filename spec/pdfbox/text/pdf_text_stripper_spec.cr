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

  it "extracts text by outline items like the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/with_outline.pdf")

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      outline = doc.document_catalog.not_nil!.document_outline.not_nil!
      oi0 = outline.first_child.not_nil!
      oi2 = oi0.next_sibling.not_nil!
      oi3 = oi2.next_sibling.not_nil!
      oi4 = oi3.next_sibling.not_nil!

      pages = doc.pages
      pages.index { |page| page.cos_object == oi0.find_destination_page(doc).not_nil!.cos_object }.should eq(0)
      pages.index { |page| page.cos_object == oi2.find_destination_page(doc).not_nil!.cos_object }.should eq(2)
      pages.index { |page| page.cos_object == oi3.find_destination_page(doc).not_nil!.cos_object }.should eq(3)
      pages.index { |page| page.cos_object == oi4.find_destination_page(doc).not_nil!.cos_object }.should eq(4)

      stripper = Pdfbox::Text::PDFTextStripper.new

      text_full = stripper.get_text(doc).gsub('\r', "")
      text_full.should eq("First level 1\nFirst level 2\nFist level 3\nSome content\nSome other content\nSecond at level 1\nSecond level 2\nContent\nThird level 1\nThird level 2\nThird level 3\nContent\nFourth level 1\nContent\nContent\n")

      stripper.start_bookmark = oi2
      stripper.end_bookmark = oi3
      text_oi23 = stripper.get_text(doc).gsub('\r', "")
      text_oi23.should eq("Second at level 1\nSecond level 2\nContent\nThird level 1\nThird level 2\nThird level 3\nContent\n")

      stripper.start_bookmark = nil
      stripper.end_bookmark = nil
      stripper.start_page = 3
      stripper.end_page = 4
      text_p34 = stripper.get_text(doc).gsub('\r', "")
      text_p34.should eq(text_oi23)

      stripper.start_bookmark = oi2
      stripper.end_bookmark = oi2
      text_oi2 = stripper.get_text(doc).gsub('\r', "")
      text_oi2.should eq("Second at level 1\nSecond level 2\nContent\n")

      stripper.start_bookmark = nil
      stripper.end_bookmark = nil
      stripper.start_page = 3
      stripper.end_page = 3
      text_p3 = stripper.get_text(doc).gsub('\r', "")
      text_p3.should eq(text_oi2)

      orphan = Pdfbox::Pdmodel::OutlineItem.new
      stripper.start_bookmark = orphan
      stripper.end_bookmark = orphan
      stripper.get_text(doc).should eq("")
    ensure
      doc.close
    end
  end
end

require "../spec_helper"
require "../../src/tools"

private def create_html_document(title : String, font : Pdfbox::Pdmodel::Font::PDFont, text : String) : Pdfbox::Pdmodel::Document
  trailer = Pdfbox::Cos::Dictionary.new
  info = Pdfbox::Pdmodel::DocumentInformation.new
  info.title = title
  trailer[Pdfbox::Cos::Name.new("Info")] = info.cos_object
  doc = Pdfbox::Pdmodel::Document.new(trailer: trailer)
  page = Pdfbox::Pdmodel::Page.new
  doc.add_page(page)
  content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
  begin
    content_stream.begin_text
    content_stream.set_font(font, 12)
    content_stream.new_line_at_offset(100, 700)
    content_stream.show_text(text)
    content_stream.end_text
  ensure
    content_stream.close
  end
  doc
end

describe Tools::PDFText2HTML do
  it "TestPDFText2HTML#testEscapeTitle" do
    stripper = Tools::PDFText2HTML.new
    doc = create_html_document(
      "<script>\u3042",
      Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA),
      "<foo>"
    )
    begin
      text = stripper.get_text(doc)

      text.should match(/<title>&lt;script&gt;&#12354;<\/title>/)
      text.should contain("&lt;foo&gt;")
    ensure
      doc.close
    end
  end

  it "TestPDFText2HTML#testStyle" do
    stripper = Tools::PDFText2HTML.new
    doc = create_html_document(
      "t",
      Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD),
      "<bold>"
    )
    begin
      text = stripper.get_text(doc)
      match = /<p>(.*?)<\/p>/.match(text)
      match.should_not be_nil
      match.not_nil![1].should eq("<b>&lt;bold&gt;</b>")
    ensure
      doc.close
    end
  end
end

require "../spec_helper"
require "../../src/tools"

private def create_markdown_document(title : String, font : Pdfbox::Pdmodel::Font::PDFont, text : String) : Pdfbox::Pdmodel::Document
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

describe Tools::PDFText2Markdown do
  it "escapes markdown punctuation" do
    stripper = Tools::PDFText2Markdown.new
    doc = create_markdown_document(
      "t",
      Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA),
      "*+-#"
    )
    begin
      stripper.get_text(doc).should contain("\\*\\+\\-\\#")
    ensure
      doc.close
    end
  end

  it "emits markdown emphasis from font state" do
    stripper = Tools::PDFText2Markdown.new
    doc = create_markdown_document(
      "t",
      Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD),
      "bold"
    )
    begin
      stripper.get_text(doc).should contain("**bold**")
    ensure
      doc.close
    end
  end
end

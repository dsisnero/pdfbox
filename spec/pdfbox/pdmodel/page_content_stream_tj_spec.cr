require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#     showTextWithPositioning (TJ array of String and Float).
private def tj_page_content_text(page : Pdfbox::Pdmodel::Page) : String
  contents = page.cos_object.not_nil![Pdfbox::Cos::Name.new("Contents")]
  contents = contents.object if contents.is_a?(Pdfbox::Cos::Object)
  contents.as(Pdfbox::Cos::Stream).create_input_stream.gets_to_end
end

private def tj_build : {Pdfbox::Pdmodel::Document, Pdfbox::Pdmodel::Page, Pdfbox::Pdmodel::PDPageContentStream}
  doc = Pdfbox::Pdmodel::Document.new
  page = Pdfbox::Pdmodel::Page.new
  doc.add_page(page)
  cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
  font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD)
  cs.set_font(font, 12)
  {doc, page, cs}
end

describe "PDPageContentStream#show_text_with_positioning" do
  it "writes a TJ array of strings and numbers (Java showTextWithPositioning)" do
    _, page, cs = tj_build
    cs.show_text_with_positioning(["AB", -50.0, "CD"])
    cs.close

    text = tj_page_content_text(page)
    text.should contain("[(AB)-50 (CD)] TJ")
  end

  it "raises for a non-string/non-float element (Java IllegalArgumentException)" do
    _, _, cs = tj_build
    expect_raises(ArgumentError, "Argument must consist of array of Float and String types") do
      cs.show_text_with_positioning(["A", 5])
    end
  end
end

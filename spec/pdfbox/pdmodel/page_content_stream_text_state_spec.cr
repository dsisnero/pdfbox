require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#     setCharacterSpacing/setWordSpacing/setLeading/setHorizontalScaling/
#     setTextRise/setRenderingMode/newLine, setMarkedContentPoint(+WithProperties),
#     addComment.
private def page_content_text(page : Pdfbox::Pdmodel::Page) : String
  contents = page.cos_object.not_nil![Pdfbox::Cos::Name.new("Contents")]
  contents = contents.object if contents.is_a?(Pdfbox::Cos::Object)
  contents.as(Pdfbox::Cos::Stream).create_input_stream.gets_to_end
end

private def build_page_content_stream : {Pdfbox::Pdmodel::Document, Pdfbox::Pdmodel::Page, Pdfbox::Pdmodel::PDPageContentStream}
  doc = Pdfbox::Pdmodel::Document.new
  page = Pdfbox::Pdmodel::Page.new
  doc.add_page(page)
  cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
  {doc, page, cs}
end

describe "PDPageContentStream text state" do
  it "writes the text state operators (Java setCharacterSpacing etc.)" do
    _, page, cs = build_page_content_stream
    cs.set_character_spacing(2)
    cs.set_word_spacing(3)
    cs.set_leading(14)
    cs.set_horizontal_scaling(90)
    cs.set_text_rise(5)
    cs.set_rendering_mode(Pdfbox::Pdmodel::Graphics::State::RenderingMode::Stroke)
    cs.new_line
    cs.close

    text = page_content_text(page)
    text.should contain("2 Tc")
    text.should contain("3 Tw")
    text.should contain("14 TL")
    text.should contain("90 Tz")
    text.should contain("5 Ts")
    text.should contain("1 Tr")
    text.should contain("T*")
  end

  it "writes a marked content point (Java setMarkedContentPoint)" do
    _, page, cs = build_page_content_stream
    cs.set_marked_content_point(Pdfbox::Cos::Name.new("Span"))
    cs.close

    page_content_text(page).should contain("/Span MP")
  end

  it "writes a marked content point with properties (Java setMarkedContentPointWithProperties)" do
    _, page, cs = build_page_content_stream
    ocg = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("Layer1")
    cs.set_marked_content_point_with_properties(Pdfbox::Cos::Name.new("Span"), ocg)
    cs.close

    page_content_text(page).should contain("/Span /oc")
    page_content_text(page).should contain(" DP")
  end

  it "writes a comment and rejects newlines (Java addComment)" do
    _, page, cs = build_page_content_stream
    cs.add_comment("hello")
    cs.close

    page_content_text(page).should contain("%hello")

    _, _, cs2 = build_page_content_stream
    expect_raises(ArgumentError, "comment should not include a newline") do
      cs2.add_comment("bad\nline")
    end
  end
end

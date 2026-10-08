require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/annotation/PDAnnotationFreeText.java#constructAppearances
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/annotation/handlers/PDFreeTextAppearanceHandler.java
#
# Java always builds a PDFreeTextAppearanceHandler, which clips the writing area
# and lays the contents out with PlainTextFormatter (wrapped lines). The Crystal
# port previously left construct_appearances a no-op and skipped clip/text wrap.

private def free_text_annotation : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFreeText
  ann = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFreeText.new
  ann.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(100.0_f32, 100.0_f32, 220.0_f32, 150.0_f32)
  ann.contents = "Hello FreeText annotation"
  ann.default_appearance = "/Helv 10 Tf 0 g"
  ann.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(
    [1.0_f32, 1.0_f32, 1.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
  )
  ann
end

describe "PDAnnotationFreeText appearance generation" do
  it "constructs a default normal appearance stream (Java constructAppearances)" do
    ann = free_text_annotation
    ann.construct_appearances
    ann.normal_appearance_stream.should_not be_nil
  end

  it "clips the writing area and lays out the text with PlainTextFormatter" do
    ann = free_text_annotation
    ann.construct_appearances

    stream = ann.normal_appearance_stream.not_nil!
    content = stream.content_stream
    content.should_not be_nil

    tokens = Pdfbox::Pdfparser::PDFStreamParser.new(content.not_nil!.to_byte_array).parse
    operators = tokens.compact_map(&.as?(Pdfbox::ContentStream::Operator)).map(&.name)

    operators.should contain("W") # clip non-zero
    operators.should contain("BT")
    operators.should contain("ET")
    (operators.includes?("Tj") || operators.includes?("TJ")).should be_true

    texts = tokens.compact_map(&.as?(Pdfbox::Cos::String)).map(&.value)
    joined = texts.join
    joined.should contain("Hello")
    joined.should contain("FreeText")
  end
end

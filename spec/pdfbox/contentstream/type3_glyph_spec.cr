require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/PDFStreamEngine.java
#
# Java's `PDFStreamEngine#showType3Glyph` default implementation is not a no-op:
# it looks up the character procedure for the code and hands it to
# `processType3Stream`, which switches to the charproc's resources, replaces the
# CTM with the text rendering matrix (concatenated with the font matrix from
# `PDType3CharProc#getMatrix`), starts from an empty text matrix, and processes
# the charproc's operators.

private class MarkerOperatorProcessor < Pdfbox::Contentstream::OperatorProcessor
  getter argument_counts = [] of Int32

  def name : String
    "S"
  end

  def process(arguments : Array(Pdfbox::Cos::Base)) : Nil
    @argument_counts << arguments.size
  end
end

private class MarkerEngine < Pdfbox::Contentstream::PDFStreamEngine
end

private def type3_font_dict(char_proc : String) : Pdfbox::Cos::Dictionary
  char_procs = Pdfbox::Cos::Dictionary.new
  char_procs[Pdfbox::Cos::Name.new("A")] = Pdfbox::Cos::Stream.new(data: char_proc.to_slice)

  font_dict = Pdfbox::Cos::Dictionary.new
  font_dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
  font_dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type3")
  font_dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name::STANDARD_ENCODING
  font_dict[Pdfbox::Cos::Name.new("CharProcs")] = char_procs
  font_dict[Pdfbox::Cos::Name.new("FontMatrix")] = Pdfbox::Cos::Array.new([
    Pdfbox::Cos::Float.new(0.001), Pdfbox::Cos::Integer.new(0),
    Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Float.new(0.001),
    Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Integer.new(0),
  ])
  font_dict[Pdfbox::Cos::Name.new("FirstChar")] = Pdfbox::Cos::Integer.new(65)
  font_dict[Pdfbox::Cos::Name.new("LastChar")] = Pdfbox::Cos::Integer.new(65)
  font_dict[Pdfbox::Cos::Name.new("Widths")] = Pdfbox::Cos::Array.new([
    Pdfbox::Cos::Integer.new(500),
  ])
  font_dict
end

private def type3_page(char_proc : String) : Pdfbox::Pdmodel::Page
  page = Pdfbox::Pdmodel::Page.new
  fonts = Pdfbox::Cos::Dictionary.new
  fonts[Pdfbox::Cos::Name.new("F3")] = type3_font_dict(char_proc)
  resources = Pdfbox::Cos::Dictionary.new
  resources[Pdfbox::Cos::Name.new("Font")] = fonts
  page.resources = Pdfbox::Pdmodel::Resources.new(resources)
  page.contents = Pdfbox::Cos::Stream.new(data: "BT /F3 12 Tf 10 10 Td (A) Tj ET".to_slice)
  page
end

describe "PDFStreamEngine#show_type3_glyph" do
  it "processes the character procedure stream of the shown code" do
    engine = MarkerEngine.new
    processor = MarkerOperatorProcessor.new(engine)
    engine.add_operator(processor)

    engine.process_page(type3_page("500 0 0 0 500 700 d1 1 2 3 S"))

    processor.argument_counts.should eq([3])
  end

  it "raises when no page has been processed" do
    engine = MarkerEngine.new
    font = Pdfbox::Pdmodel::Font::PDType3Font.new(type3_font_dict("500 0 0 0 500 700 d1"))

    expect_raises(Exception, "No current page") do
      engine.show_type3_glyph(
        Pdfbox::Util::Matrix.new,
        font,
        65,
        Pdfbox::Pdmodel::Font::PDFont::Vector.new(500.0_f32, 0.0_f32)
      )
    end
  end
end

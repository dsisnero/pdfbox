require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/PDFStreamEngine.java
#
# Java's `PDFStreamEngine#showGlyph` is the hook every decoded glyph passes
# through, and it dispatches on the font: Type 3 fonts go to `showType3Glyph`,
# everything else to `showFontGlyph`. Both are protected hooks a subclass
# overrides (the base class defaults are a no-op and a Type 3 stream walk). The
# port's `showGlyph` was an empty method, so an engine subclass could not
# receive glyphs at all.

private class GlyphRecordingEngine < Pdfbox::Contentstream::PDFStreamEngine
  getter font_glyphs = [] of Int32
  getter type3_glyphs = [] of Int32

  def show_font_glyph(text_rendering_matrix : Pdfbox::Util::Matrix,
                      font : Pdfbox::Pdmodel::Font::PDFont,
                      code : Int32,
                      displacement : Pdfbox::Pdmodel::Font::PDFont::Vector) : Nil
    @font_glyphs << code
  end

  def show_type3_glyph(text_rendering_matrix : Pdfbox::Util::Matrix,
                       font : Pdfbox::Pdmodel::Font::PDType3Font,
                       code : Int32,
                       displacement : Pdfbox::Pdmodel::Font::PDFont::Vector) : Nil
    @type3_glyphs << code
  end
end

# A Type 3 font dictionary. Only the entries `PDType3Font` reads eagerly are
# needed for the dispatch check.
private def type3_font_dict : Pdfbox::Cos::Dictionary
  dict = Pdfbox::Cos::Dictionary.new
  dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
  dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type3")
  dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name::STANDARD_ENCODING
  dict[Pdfbox::Cos::Name.new("FontMatrix")] = Pdfbox::Cos::Array.new([
    Pdfbox::Cos::Float.new(0.001), Pdfbox::Cos::Integer.new(0),
    Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Float.new(0.001),
    Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Integer.new(0),
  ])
  dict[Pdfbox::Cos::Name.new("FirstChar")] = Pdfbox::Cos::Integer.new(65)
  dict[Pdfbox::Cos::Name.new("LastChar")] = Pdfbox::Cos::Integer.new(65)
  dict[Pdfbox::Cos::Name.new("Widths")] = Pdfbox::Cos::Array.new([
    Pdfbox::Cos::Integer.new(500),
  ])
  dict
end

private def type1_font_dict : Pdfbox::Cos::Dictionary
  dict = Pdfbox::Cos::Dictionary.new
  dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
  dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type1")
  dict[Pdfbox::Cos::Name.new("BaseFont")] = Pdfbox::Cos::Name.new("Helvetica")
  dict
end

private def font_page(font_dict : Pdfbox::Cos::Dictionary, content : String) : Pdfbox::Pdmodel::Page
  page = Pdfbox::Pdmodel::Page.new
  fonts = Pdfbox::Cos::Dictionary.new
  fonts[Pdfbox::Cos::Name.new("F1")] = font_dict
  resources = Pdfbox::Cos::Dictionary.new
  resources[Pdfbox::Cos::Name.new("Font")] = fonts
  page.resources = Pdfbox::Pdmodel::Resources.new(resources)
  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)
  page
end

describe "PDFStreamEngine#show_glyph dispatch" do
  it "sends a simple font glyph to show_font_glyph" do
    engine = GlyphRecordingEngine.new
    font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(type1_font_dict)

    engine.show_glyph(
      Pdfbox::Util::Matrix.new,
      font,
      72,
      Pdfbox::Pdmodel::Font::PDFont::Vector.new(500.0_f32, 0.0_f32)
    )

    engine.font_glyphs.should eq([72])
    engine.type3_glyphs.should be_empty
  end

  it "sends a Type 3 glyph to show_type3_glyph" do
    engine = GlyphRecordingEngine.new
    font = Pdfbox::Pdmodel::Font::PDType3Font.new(type3_font_dict)

    engine.show_glyph(
      Pdfbox::Util::Matrix.new,
      font,
      65,
      Pdfbox::Pdmodel::Font::PDFont::Vector.new(500.0_f32, 0.0_f32)
    )

    engine.type3_glyphs.should eq([65])
    engine.font_glyphs.should be_empty
  end

  it "delivers the glyphs of a Tj operator to show_font_glyph" do
    page = font_page(type1_font_dict, "BT /F1 12 Tf 10 10 Td (AB) Tj ET")
    engine = GlyphRecordingEngine.new
    engine.process_page(page)

    engine.font_glyphs.should eq([65, 66])
    engine.type3_glyphs.should be_empty
  end
end

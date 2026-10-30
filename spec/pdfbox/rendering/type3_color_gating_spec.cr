require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/PDFStreamEngine.java
#
# When a Type 3 character procedure starts with `d1` (the cached-glyph operator)
# Java turns colour processing off for that stream
# (`processStreamOperators`: "isFirstOperator && ...TYPE3_D1 ... ->
# shouldProcessColorOperators = false"), so the colour operators the charproc
# contains are ignored and the glyph is painted in the current graphics-state
# colour. A charproc that starts with `d0` keeps processing colours, and the
# flag is restored afterwards. The port processed every colour operator, so a
# `d1` glyph was painted in the charproc's colour instead of the text colour.

private def color_gating_font_dict(char_proc : String) : Pdfbox::Cos::Dictionary
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

private def render_char_proc(char_proc : String, trailing_content : String = "", &) : Nil
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 100.0, 100.0)

  fonts = Pdfbox::Cos::Dictionary.new
  fonts[Pdfbox::Cos::Name.new("F3")] = color_gating_font_dict(char_proc)
  resources = Pdfbox::Cos::Dictionary.new
  resources[Pdfbox::Cos::Name.new("Font")] = fonts
  page.resources = Pdfbox::Pdmodel::Resources.new(resources)

  content = "BT /F3 50 Tf 10 10 Td (A) Tj ET #{trailing_content}"
  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)

  document = Pdfbox::Pdmodel::Document.new
  document.add_page(page)
  begin
    yield Pdfbox::Rendering::PDFRenderer.new(document).render_image(0)
  ensure
    document.close
  end
end

private def pixel(image : CrImage::RGBA, x : Int32, y : Int32) : Tuple(UInt8, UInt8, UInt8, UInt8)
  c = image[x, y].to_rgba8
  {c.r, c.g, c.b, c.a}
end

private def red?(image : CrImage::RGBA, x : Int32, y : Int32) : Bool
  c = pixel(image, x, y)
  c[0] > 200 && c[1] < 60 && c[2] < 60
end

private def any_red?(image : CrImage::RGBA) : Bool
  image.each_pixel do |x, y, _|
    return true if red?(image, x, y)
  end
  false
end

describe "Type 3 character procedure colour gating" do
  # The glyph square covers PDF (10,10)-(60,60), so its centre is device (35, 64)
  # on a 100x100 page.

  it "ignores the charproc colours when it starts with d1" do
    render_char_proc("1000 0 0 0 1000 1000 d1 1 0 0 rg 0 0 1000 1000 re f") do |image|
      r, g, b, a = pixel(image, 35, 64)
      a.should eq(255_u8)
      # painted in the text colour (black), not the charproc's red
      r.should be < 128
      g.should be < 128
      b.should be < 128
      any_red?(image).should be_false
    end
  end

  it "keeps processing colours when the charproc starts with d0" do
    render_char_proc("500 0 0 d0 1 0 0 rg 0 0 1000 1000 re f") do |image|
      red?(image, 35, 64).should be_true
    end
  end

  it "restores colour processing after the charproc" do
    # The d1 charproc sets red, which must not leak into the following fill.
    char_proc = "1000 0 0 0 1000 1000 d1 1 0 0 rg 0 0 1000 1000 re f"
    render_char_proc(char_proc, "0 0 100 10 re f") do |image|
      # the band at the bottom of the page is painted in the page's own colour
      red?(image, 50, 95).should be_false
      r, g, b, _ = pixel(image, 50, 95)
      r.should be < 128
      g.should be < 128
      b.should be < 128
    end
  end
end

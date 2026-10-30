require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PageDrawer.java
#
# Text rendering modes 4..7 clip with the glyphs: `drawGlyph` buffers the glyph
# outline in `textClippings` when `renderingMode.isClip()`, and `endText()` appends
# all buffered shapes into one non-zero path and intersects it into the graphics
# state's clipping path (`PageDrawer#endTextClip`). The port only filled/stroked
# glyphs, so modes 4..7 painted the glyph and then painted the rest of the page
# unclipped.

private def clip_text_font_dict : Pdfbox::Cos::Dictionary
  dict = Pdfbox::Cos::Dictionary.new
  dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
  dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type1")
  dict[Pdfbox::Cos::Name.new("BaseFont")] = Pdfbox::Cos::Name.new("Helvetica")
  # explicit widths so the glyphs advance (standard-14 metrics are not wired yet)
  dict[Pdfbox::Cos::Name.new("FirstChar")] = Pdfbox::Cos::Integer.new(72)
  dict[Pdfbox::Cos::Name.new("LastChar")] = Pdfbox::Cos::Integer.new(72)
  dict[Pdfbox::Cos::Name.new("Widths")] = Pdfbox::Cos::Array.new([
    Pdfbox::Cos::Integer.new(722).as(Pdfbox::Cos::Base),
  ])
  dict
end

private def render_text_clip(content : String, &) : Nil
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 200.0, 100.0)

  fonts = Pdfbox::Cos::Dictionary.new
  fonts[Pdfbox::Cos::Name.new("F1")] = clip_text_font_dict
  resources = Pdfbox::Cos::Dictionary.new
  resources[Pdfbox::Cos::Name.new("Font")] = fonts
  page.resources = Pdfbox::Pdmodel::Resources.new(resources)
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

private def dark?(image : CrImage::RGBA, x : Int32, y : Int32) : Bool
  c = pixel(image, x, y)
  c[0] < 128 && c[1] < 128 && c[2] < 128
end

private def white?(image : CrImage::RGBA, x : Int32, y : Int32) : Bool
  pixel(image, x, y) == {255_u8, 255_u8, 255_u8, 255_u8}
end

# The set of inked pixels, used to compare a clipped fill with the glyph itself.
private def ink_pixels(image : CrImage::RGBA) : Array(Tuple(Int32, Int32))
  pixels = [] of Tuple(Int32, Int32)
  image.each_pixel do |x, y, _|
    pixels << {x, y} if dark?(image, x, y)
  end
  pixels
end

private def render_ink(content : String) : Array(Tuple(Int32, Int32))
  result = [] of Tuple(Int32, Int32)
  render_text_clip(content) do |image|
    result = ink_pixels(image)
  end
  result
end

describe "text clipping modes" do
  # A 200x100 page: 48pt Helvetica "H" at (10, 40).

  it "paints the same shape as filling the glyph" do
    filled = render_ink("BT /F1 48 Tf 10 40 Td (H) Tj ET")
    filled.should_not be_empty

    # Mode 7 paints nothing itself but clips, so the page fill keeps only the
    # glyph shape.
    clipped = render_ink("BT /F1 48 Tf 10 40 Td 7 Tr (H) Tj ET 0 0 200 100 re f")
    clipped.should eq(filled)
  end

  it "confines later painting to the glyph and not the rest of the page" do
    render_text_clip("BT /F1 48 Tf 10 40 Td 7 Tr (H) Tj ET 0 0 200 100 re f") do |image|
      ink = ink_pixels(image)
      ink.should_not be_empty
      # everything stays in the glyph's neighbourhood instead of the whole page
      ink.all? { |(x, _)| x < 80 }.should be_true
      white?(image, 150, 20).should be_true
    end
  end

  it "restores the clip when the graphics state is restored" do
    # The clip is set inside q ... Q; the second fill covers the whole page.
    render_text_clip("q BT /F1 48 Tf 10 40 Td 7 Tr (H) Tj ET 0 0 200 100 re f Q " \
                     "0 0 200 100 re f") do |image|
      dark?(image, 150, 20).should be_true
    end
  end

  it "unites the glyphs of one text object into one clip region" do
    one = render_ink("BT /F1 48 Tf 10 40 Td (H) Tj ET")
    two = render_ink("BT /F1 48 Tf 10 40 Td 7 Tr (HH) Tj ET 0 0 200 100 re f")
    # two glyphs cover more than one, and the fill between them is clipped out
    two.size.should be > one.size
    # the page outside the glyphs is still white
    render_text_clip("BT /F1 48 Tf 10 40 Td 7 Tr (HH) Tj ET 0 0 200 100 re f") do |image|
      white?(image, 5, 95).should be_true
      white?(image, 150, 20).should be_true
    end
  end
end

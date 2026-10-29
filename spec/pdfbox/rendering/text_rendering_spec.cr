require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/PDFStreamEngine.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PageDrawer.java
#
# Text was not rendered at all: `PDFStreamEngine#showGlyph` never reached
# `PageDrawer#showFontGlyph`, and the graphics engine kept its text state in a
# second graphics-state stack that the engine's text machinery never read.
# These examples pin the user-visible result: a `Tj` leaves the outline of the
# glyphs on the raster, in the non-stroking colour, at the text position.

private def text_font_dict : Pdfbox::Cos::Dictionary
  dict = Pdfbox::Cos::Dictionary.new
  dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
  dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type1")
  dict[Pdfbox::Cos::Name.new("BaseFont")] = Pdfbox::Cos::Name.new("Helvetica")
  dict
end

private def text_document(content : String) : Pdfbox::Pdmodel::Document
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 200.0, 100.0)

  fonts = Pdfbox::Cos::Dictionary.new
  fonts[Pdfbox::Cos::Name.new("F1")] = text_font_dict
  resources = Pdfbox::Cos::Dictionary.new
  resources[Pdfbox::Cos::Name.new("Font")] = fonts
  page.resources = Pdfbox::Pdmodel::Resources.new(resources)

  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)

  document = Pdfbox::Pdmodel::Document.new
  document.add_page(page)
  document
end

private def rendered_pixels(content : String, &)
  document = text_document(content)
  begin
    image = Pdfbox::Rendering::PDFRenderer.new(document).render_image(0)
    yield image
  ensure
    document.close
  end
end

# The raster starts as transparent black, so a pixel only counts as ink when it
# is both opaque and dark.
private def dark_pixels(image : CrImage::RGBA) : Array(Tuple(Int32, Int32))
  pixels = [] of Tuple(Int32, Int32)
  image.each_pixel do |x, y, color|
    rgba = color.to_rgba8
    pixels << {x, y} if rgba.a > 0 && rgba.r < 128
  end
  pixels
end

describe "PDFRenderer text rendering" do
  it "draws the glyphs of a Tj operator" do
    rendered_pixels("BT /F1 48 Tf 10 40 Td (H) Tj ET") do |image|
      dark = dark_pixels(image)
      dark.should_not be_empty

      xs = dark.map(&.[0])
      ys = dark.map(&.[1])
      # 48pt Helvetica at (10, 40) in a 200x100 page rendered at 72 dpi, so the
      # mark sits right of x=10 and above the baseline row y = 100 - 40.
      xs.min.should be >= 8
      xs.max.should be <= 65
      ys.min.should be <= 60
      ys.max.should be >= 20
    end
  end

  it "leaves a page without text blank" do
    rendered_pixels("0 0 10 10 re f") do |image|
      # The rectangle is filled black in the lower left corner, nothing else.
      dark = dark_pixels(image)
      dark.should_not be_empty
      dark.all? { |x, y| x <= 11 && y >= 88 }.should be_true
    end
  end

  it "fills the glyph with the non-stroking colour" do
    rendered_pixels("1 0 0 rg BT /F1 48 Tf 10 40 Td (H) Tj ET") do |image|
      red = 0
      image.each_pixel do |x, y, color|
        rgba = color.to_rgba8
        red += 1 if rgba.r > 200 && rgba.g < 60 && rgba.b < 60
      end
      red.should be > 0
    end
  end
end

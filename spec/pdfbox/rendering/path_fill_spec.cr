require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PageDrawer.java
#
# Java paints a fill by handing the device-space path to
# `Graphics2D#fill(Shape)` after `linePath.setWindingRule(windingRule)`, so the
# area inside the path is painted (PageDrawer#fillPath). The port only drew the
# outline of the path (`draw_filled` -> `draw_lines`), so a filled rectangle or
# glyph was an empty contour.
#
# These examples pin the user-visible result: the interior of a filled path is
# inked, the outside is not, the winding rule decides nested subpaths, and
# `B` fills and strokes with the two different colours.

private def fill_document(content : String) : Pdfbox::Pdmodel::Document
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 200.0, 200.0)
  page.resources = Pdfbox::Pdmodel::Resources.new(Pdfbox::Cos::Dictionary.new)
  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)

  document = Pdfbox::Pdmodel::Document.new
  document.add_page(page)
  document
end

private def render_content(content : String, &)
  document = fill_document(content)
  begin
    yield Pdfbox::Rendering::PDFRenderer.new(document).render_image(0)
  ensure
    document.close
  end
end

# The raster starts as transparent black, so a pixel carries ink once something
# has been painted onto it.
private def inked?(image : CrImage::RGBA, x : Int32, y : Int32) : Bool
  image[x, y].to_rgba8.a > 0
end

private def rgba(image : CrImage::RGBA, x : Int32, y : Int32) : Tuple(UInt8, UInt8, UInt8, UInt8)
  c = image[x, y].to_rgba8
  {c.r, c.g, c.b, c.a}
end

describe "PageDrawer path filling" do
  # A 200x200 page at 72 dpi renders at scale 1 with the PDF origin in the
  # bottom left, so device y = 199 - pdfY.
  it "fills the interior of a rectangle" do
    render_content("0 0 100 100 re f") do |image|
      inked?(image, 50, 149).should be_true   # centre, PDF (50, 50)
      inked?(image, 5, 194).should be_true    # near the lower-left corner
      inked?(image, 95, 104).should be_true   # near the upper-right corner
      inked?(image, 150, 149).should be_false # right of the rectangle
      inked?(image, 50, 50).should be_false   # above the rectangle
    end
  end

  it "paints only the area inside a triangle" do
    # (0,0) -> (200,0) -> (0,200): the lower-left half of the page.
    render_content("0 0 m 200 0 l 0 200 l f") do |image|
      inked?(image, 20, 179).should be_true  # PDF (20, 20), inside
      inked?(image, 180, 19).should be_false # PDF (180, 180), outside
    end
  end

  it "honours the non-zero winding rule for nested subpaths" do
    # Two rectangles drawn in the same direction: non-zero fills the whole
    # outline, so the inner area is inked too.
    content = "0 0 100 100 re 25 25 50 50 re f"
    render_content(content) do |image|
      inked?(image, 50, 149).should be_true # centre, inside both rectangles
      inked?(image, 12, 149).should be_true # inside the outer, outside the inner
    end
  end

  it "honours the even-odd rule for nested subpaths" do
    # The same two rectangles with f* leave the inner rectangle as a hole.
    content = "0 0 100 100 re 25 25 50 50 re f*"
    render_content(content) do |image|
      inked?(image, 50, 149).should be_false # centre, inside both rectangles
      inked?(image, 12, 149).should be_true  # inside the outer, outside the inner
    end
  end

  it "paints nothing for a path with no area" do
    # A horizontal line has zero height, so there is no area to fill.
    render_content("0 0 m 100 0 l f") do |image|
      any_ink = false
      image.each_pixel { |_, _, color| any_ink = true if color.to_rgba8.a > 0 }
      any_ink.should be_false
    end
  end

  it "fills and strokes with B" do
    render_content("1 0 0 rg 0 0 1 RG 0 0 100 100 re B") do |image|
      # Centre is filled with the non-stroking colour ...
      rgba(image, 50, 149).should eq({255_u8, 0_u8, 0_u8, 255_u8})
      # ... and the path itself is stroked with the stroking colour.
      rgba(image, 50, 99).should eq({0_u8, 0_u8, 255_u8, 255_u8})
      rgba(image, 100, 149).should eq({0_u8, 0_u8, 255_u8, 255_u8})
    end
  end
end

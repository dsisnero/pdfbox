require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PageDrawer.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/state/PDGraphicsState.java
#
# `W`/`W*` add the current path to the graphics state's clipping paths
# (PageDrawer#clip -> PDGraphicsState#intersectClippingPath) and every later
# painting operator is restricted to their intersection (PageDrawer#setClip
# before fill/stroke). The port's `PageDrawer#clip` was a no-op, so a clipped
# page painted everywhere.
#
# These examples pin the user-visible result: painting stops at the clip edge,
# `q`/`Q` restores the clip, `W*` honours the even-odd rule, strokes are clipped
# too, and successive `W`s intersect.

private def clip_document(content : String) : Pdfbox::Pdmodel::Document
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 200.0, 200.0)
  page.resources = Pdfbox::Pdmodel::Resources.new(Pdfbox::Cos::Dictionary.new)
  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)

  document = Pdfbox::Pdmodel::Document.new
  document.add_page(page)
  document
end

private def render_clipped(content : String, &)
  document = clip_document(content)
  begin
    yield Pdfbox::Rendering::PDFRenderer.new(document).render_image(0)
  ensure
    document.close
  end
end

private def inked?(image : CrImage::RGBA, x : Int32, y : Int32) : Bool
  image[x, y].to_rgba8.a > 0
end

describe "PageDrawer clipping" do
  # A 200x200 page at 72 dpi renders at scale 1 with the PDF origin in the
  # bottom left, so device y = 199 - pdfY.
  it "restricts a fill to the clipping path" do
    # The clip covers x < 50; the fill covers the whole page.
    render_clipped("0 0 50 200 re W n 0 0 200 200 re f") do |image|
      inked?(image, 10, 100).should be_true   # inside the clip
      inked?(image, 49, 100).should be_true   # just inside the clip edge
      inked?(image, 100, 100).should be_false # beyond the clip edge
      inked?(image, 150, 20).should be_false  # far right, still clipped
    end
  end

  it "restores the clipping path when the graphics state is restored" do
    # The clip is set inside q ... Q, so it must not affect the second fill.
    render_clipped("q 0 0 50 200 re W n Q 0 0 200 200 re f") do |image|
      inked?(image, 100, 100).should be_true
      inked?(image, 150, 20).should be_true
    end
  end

  it "honours the even-odd rule for W*" do
    # Outer rectangle with an inner rectangle as a hole; the fill covers all.
    render_clipped("0 0 100 100 re 25 25 50 50 re W* n 0 0 200 200 re f") do |image|
      inked?(image, 50, 149).should be_false  # inside the hole
      inked?(image, 12, 149).should be_true   # inside the outer rectangle only
      inked?(image, 150, 149).should be_false # outside the clip
    end
  end

  it "clips strokes as well as fills" do
    # A horizontal line across the page, clipped to x < 50.
    render_clipped("0 0 50 200 re W n 0 100 m 200 100 l S") do |image|
      inked?(image, 10, 99).should be_true
      inked?(image, 100, 99).should be_false
    end
  end

  it "intersects successive clipping paths" do
    # First clip x < 50, then the band PDF y < 50 (device y > 149).
    render_clipped("0 0 50 200 re W n 0 0 200 50 re W n 0 0 200 200 re f") do |image|
      inked?(image, 10, 180).should be_true   # inside both
      inked?(image, 10, 100).should be_false  # outside the second clip
      inked?(image, 100, 180).should be_false # outside the first clip
    end
  end
end

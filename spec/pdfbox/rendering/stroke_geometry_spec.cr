require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PageDrawer.java
#
# Java strokes with a `BasicStroke` built from the graphics state
# (PageDrawer#getStroke): the line width scaled by the CTM and clamped to Adobe's
# 0.25 minimum, the line cap and join, the miter limit, and the dash array/phase
# (also CTM-scaled; an all-zero array paints nothing, PDFBOX-5168), drawn with
# `Graphics2D#draw`. The port painted 1-pixel bresenham lines whatever `/w`, `/J`,
# `/j`, `/m` or `/d` said.
#
# These examples pin the user-visible result: width, caps, joins and dashes.
# Device rows/columns are sampled at integer coordinates.

private def stroke_document(content : String) : Pdfbox::Pdmodel::Document
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 200.0, 200.0)
  page.resources = Pdfbox::Pdmodel::Resources.new(Pdfbox::Cos::Dictionary.new)
  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)

  document = Pdfbox::Pdmodel::Document.new
  document.add_page(page)
  document
end

private def render_stroke(content : String, &)
  document = stroke_document(content)
  begin
    yield Pdfbox::Rendering::PDFRenderer.new(document).render_image(0)
  ensure
    document.close
  end
end

private def inked?(image : CrImage::RGBA, x : Int32, y : Int32) : Bool
  image[x, y].to_rgba8.a > 0
end

describe "PageDrawer stroke geometry" do
  # A 200x200 page at 72 dpi renders at scale 1 with the PDF origin in the
  # bottom left, so device y = 199 - pdfY; a line at PDF y=100 lands on row 99.

  it "paints the line with the current line width" do
    render_stroke("10 w 0 100 m 200 100 l S") do |image|
      inked?(image, 100, 99).should be_true  # centre of the stroke
      inked?(image, 100, 94).should be_true  # top edge of the 10pt band
      inked?(image, 100, 103).should be_true # bottom edge of the band
      inked?(image, 100, 93).should be_false
      inked?(image, 100, 104).should be_false
    end
  end

  it "keeps a one-point line one pixel wide" do
    render_stroke("1 w 0 100 m 200 100 l S") do |image|
      inked?(image, 100, 99).should be_true
      inked?(image, 100, 98).should be_false
      inked?(image, 100, 100).should be_false
    end
  end

  it "clamps a zero-width line to Adobe's minimum hairline" do
    render_stroke("0 w 0 100 m 200 100 l S") do |image|
      inked?(image, 100, 99).should be_true
      inked?(image, 100, 98).should be_false
    end
  end

  it "extends the ends of a line according to the cap style" do
    # The line runs from x=50 to x=150 with a 10pt width, so the caps reach
    # half the width (5px) beyond the ends.
    render_stroke("10 w 0 J 50 100 m 150 100 l S") do |image|
      inked?(image, 45, 99).should be_false # butt cap stops at the end point
    end
    render_stroke("10 w 2 J 50 100 m 150 100 l S") do |image|
      inked?(image, 45, 99).should be_true # square cap
      inked?(image, 45, 96).should be_true # square cap keeps the full width
      inked?(image, 44, 99).should be_false
    end
    render_stroke("10 w 1 J 50 100 m 150 100 l S") do |image|
      inked?(image, 47, 96).should be_true  # round cap: radius 5
      inked?(image, 45, 96).should be_false # round cap is not square
    end
  end

  it "mitres a sharp join and falls back to a bevel" do
    # A right-angled "peak" at device (100, 99): the outer miter tip sits about
    # 7px above the vertex, the bevel only 5px.
    render_stroke("10 w 0 j 10 M 50 50 m 100 100 l 150 50 l S") do |image|
      inked?(image, 100, 92).should be_true
    end
    render_stroke("10 w 2 j 50 50 m 100 100 l 150 50 l S") do |image|
      inked?(image, 100, 92).should be_false
      inked?(image, 100, 97).should be_true # the bevel still fills the corner
    end
    # A miter limit of 1 turns the miter into a bevel.
    render_stroke("10 w 0 j 1 M 50 50 m 100 100 l 150 50 l S") do |image|
      inked?(image, 100, 92).should be_false
    end
  end

  it "dashes the line with the dash array and phase" do
    # 10pt on, 10pt off, starting at the path start (device x=0).
    render_stroke("10 w [10 10] 0 d 0 100 m 200 100 l S") do |image|
      inked?(image, 5, 99).should be_true
      inked?(image, 15, 99).should be_false
      inked?(image, 25, 99).should be_true
    end
    # The phase shifts the pattern: a phase of 10 starts in the gap.
    render_stroke("10 w [10 10] 10 d 0 100 m 200 100 l S") do |image|
      inked?(image, 5, 99).should be_false
      inked?(image, 15, 99).should be_true
    end
  end

  it "paints nothing for an all-zero dash array" do
    # PDFBOX-5168: Adobe shows such a line as invisible.
    render_stroke("10 w [0 0] 0 d 0 100 m 200 100 l S") do |image|
      any_ink = false
      image.each_pixel { |_, _, color| any_ink = true if color.to_rgba8.a > 0 }
      any_ink.should be_false
    end
  end

  it "scales the line width by the transformation matrix" do
    # A 5pt line under a 2x CTM is 10 device pixels wide.
    render_stroke("2 0 0 2 0 0 cm 5 w 0 50 m 100 50 l S") do |image|
      inked?(image, 50, 99).should be_true
      inked?(image, 50, 94).should be_true
      inked?(image, 50, 104).should be_false
    end
  end
end

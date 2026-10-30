require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/PDFStreamEngine.java
#
# When a Form XObject is processed, Java clips to the form's `/BBox`
# (`processStream` -> `clipToRect(contentStream.getBBox())`, which intersects the
# clipping path with `PDRectangle#transform(CTM)`). The port processed the
# form's operators without clipping, so a form could paint outside its box.

private def form_page(form_content : String, bbox : Array(Float64),
                      page_content : String) : Pdfbox::Pdmodel::Document
  form = Pdfbox::Cos::Stream.new(data: form_content.to_slice)
  form[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name.new("XObject")
  form[Pdfbox::Cos::Name.new("Subtype")] = Pdfbox::Cos::Name.new("Form")
  form[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new(
    bbox.map { |value| Pdfbox::Cos::Float.new(value).as(Pdfbox::Cos::Base) }
  )
  form[Pdfbox::Cos::Name.new("Resources")] = Pdfbox::Cos::Dictionary.new

  xobjects = Pdfbox::Cos::Dictionary.new
  xobjects[Pdfbox::Cos::Name.new("Fm1")] = form
  resources = Pdfbox::Cos::Dictionary.new
  resources[Pdfbox::Cos::Name.new("XObject")] = xobjects

  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 200.0, 200.0)
  page.resources = Pdfbox::Pdmodel::Resources.new(resources)
  page.contents = Pdfbox::Cos::Stream.new(data: page_content.to_slice)

  document = Pdfbox::Pdmodel::Document.new
  document.add_page(page)
  document
end

private def render_form(form_content : String, bbox : Array(Float64),
                        page_content : String, &) : Nil
  document = form_page(form_content, bbox, page_content)
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

describe "Form XObject bounding box" do
  # A 200x200 page at 72 dpi: device y = 199 - pdfY. The form fills 200x200 in
  # form space but its BBox is only 50x50, so only the box may be painted.

  it "clips the form content to its BBox" do
    render_form("0 0 200 200 re f", [0.0, 0.0, 50.0, 50.0],
      "q 1 0 0 1 100 100 cm /Fm1 Do Q") do |image|
      dark?(image, 125, 74).should be_true   # inside the BBox
      white?(image, 175, 74).should be_true  # right of the BBox
      white?(image, 125, 24).should be_true  # below the BBox
      white?(image, 125, 120).should be_true # above the BBox
    end
  end

  it "transforms the BBox with the placement matrix" do
    # The 2x placement scales the 50x50 BBox to 100x100 at (50, 50).
    render_form("0 0 200 200 re f", [0.0, 0.0, 50.0, 50.0],
      "q 2 0 0 2 50 50 cm /Fm1 Do Q") do |image|
      dark?(image, 100, 100).should be_true # centre of the scaled BBox
      white?(image, 160, 100).should be_true
      white?(image, 40, 100).should be_true
    end
  end

  it "leaves form content inside the BBox untouched" do
    render_form("0 0 20 20 re f", [0.0, 0.0, 50.0, 50.0],
      "q 1 0 0 1 100 100 cm /Fm1 Do Q") do |image|
      dark?(image, 105, 94).should be_true  # inside both the content and the BBox
      white?(image, 140, 74).should be_true # inside the BBox, outside the content
    end
  end
end

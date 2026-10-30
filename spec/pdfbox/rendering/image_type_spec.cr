require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PDFRenderer.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/ImageType.java
#
# Java clears the page image before drawing and picks the clear colour from the
# image type: `ImageType.RGB` (the type `renderImage(pageIndex)` returns) clears
# to opaque white, `ImageType.ARGB` to transparent. The port always returned a
# transparent raster, so a rendered page had no white paper under its content.

private def image_type_document(content : String) : Pdfbox::Pdmodel::Document
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 100.0, 100.0)
  page.resources = Pdfbox::Pdmodel::Resources.new(Pdfbox::Cos::Dictionary.new)
  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)

  document = Pdfbox::Pdmodel::Document.new
  document.add_page(page)
  document
end

private def render_page(content : String, image_type : Pdfbox::Rendering::ImageType,
                        &) : Nil
  document = image_type_document(content)
  begin
    yield Pdfbox::Rendering::PDFRenderer.new(document).render_image(0, 1.0, image_type)
  ensure
    document.close
  end
end

private def pixel(image : CrImage::RGBA, x : Int32, y : Int32) : Tuple(UInt8, UInt8, UInt8, UInt8)
  c = image[x, y].to_rgba8
  {c.r, c.g, c.b, c.a}
end

describe "PDFRenderer image types" do
  it "clears an RGB render to opaque white" do
    render_page("", Pdfbox::Rendering::ImageType::RGB) do |image|
      pixel(image, 0, 0).should eq({255_u8, 255_u8, 255_u8, 255_u8})
      pixel(image, 50, 50).should eq({255_u8, 255_u8, 255_u8, 255_u8})
      pixel(image, 99, 99).should eq({255_u8, 255_u8, 255_u8, 255_u8})
    end
  end

  it "keeps an ARGB render transparent" do
    render_page("", Pdfbox::Rendering::ImageType::ARGB) do |image|
      pixel(image, 0, 0).should eq({0_u8, 0_u8, 0_u8, 0_u8})
      pixel(image, 50, 50).should eq({0_u8, 0_u8, 0_u8, 0_u8})
    end
  end

  it "paints the content over the cleared background" do
    render_page("0 0 50 50 re f", Pdfbox::Rendering::ImageType::RGB) do |image|
      pixel(image, 25, 74).should eq({0_u8, 0_u8, 0_u8, 255_u8})       # filled rectangle
      pixel(image, 75, 74).should eq({255_u8, 255_u8, 255_u8, 255_u8}) # white page
    end
  end

  it "honours the image type of a DPI render" do
    document = image_type_document("")
    begin
      renderer = Pdfbox::Rendering::PDFRenderer.new(document)
      white = renderer.render_image_with_dpi(0, 144)
      transparent = renderer.render_image_with_dpi(0, 144, Pdfbox::Rendering::ImageType::ARGB)
      pixel(white, 10, 10).should eq({255_u8, 255_u8, 255_u8, 255_u8})
      pixel(transparent, 10, 10).should eq({0_u8, 0_u8, 0_u8, 0_u8})
    ensure
      document.close
    end
  end

  it "rejects the image types the port cannot produce" do
    document = image_type_document("")
    begin
      renderer = Pdfbox::Rendering::PDFRenderer.new(document)
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
        renderer.render_image(0, 1.0, Pdfbox::Rendering::ImageType::GRAY)
      end
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
        renderer.render_image(0, 1.0, Pdfbox::Rendering::ImageType::BINARY)
      end
    ensure
      document.close
    end
  end
end

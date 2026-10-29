require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/operator/graphics/BeginInlineImage.java
#
# The graphics engine must turn a BI operator (with parsed inline image
# parameters/data) into a PDInlineImage and hand it to drawImage.

private class RecordingImageEngine < Pdfbox::Contentstream::PDFGraphicsStreamEngine
  getter images = [] of Pdfbox::Pdmodel::Graphics::Image::PDImage

  def append_rectangle(p0 : Tuple(Float32, Float32), p1 : Tuple(Float32, Float32),
                       p2 : Tuple(Float32, Float32), p3 : Tuple(Float32, Float32)) : Nil
  end

  def draw_image(pd_image : Pdfbox::Pdmodel::Graphics::Image::PDImage) : Nil
    @images << pd_image
  end

  def clip(winding_rule : Int32) : Nil
  end

  def move_to(x : Float32, y : Float32) : Nil
  end

  def line_to(x : Float32, y : Float32) : Nil
  end

  def curve_to(x1 : Float32, y1 : Float32, x2 : Float32, y2 : Float32, x3 : Float32, y3 : Float32) : Nil
  end

  def current_point : Tuple(Float32, Float32)?
    nil
  end

  def close_path : Nil
  end

  def end_path : Nil
  end

  def stroke_path : Nil
  end

  def fill_path(winding_rule : Int32) : Nil
  end

  def fill_and_stroke_path(winding_rule : Int32) : Nil
  end

  def shading_fill(shading_name : String) : Nil
  end

  def begin_text : Nil
  end

  def end_text : Nil
  end

  def show_font_glyph(text_rendering_matrix : Pdfbox::Util::Matrix, font : Pdfbox::Pdmodel::Font::PDFont,
                      code : Int32, displacement : Pdfbox::Pdmodel::Font::PDFont::Vector) : Nil
  end

  def show_type3_glyph(text_rendering_matrix : Pdfbox::Util::Matrix, font : Pdfbox::Pdmodel::Font::PDType3Font,
                       code : Int32, displacement : Pdfbox::Pdmodel::Font::PDFont::Vector) : Nil
  end
end

private def inline_image_page : Pdfbox::Pdmodel::Page
  io = ::IO::Memory.new
  io << "BI /W 2 /H 2 /BPC 8 /CS /G ID "
  io.write(Bytes[1_u8, 2_u8, 3_u8, 4_u8])
  io << " EI"

  page = Pdfbox::Pdmodel::Page.new
  page.resources = Pdfbox::Pdmodel::Resources.new(Pdfbox::Cos::Dictionary.new)
  page.contents = Pdfbox::Cos::Stream.new(data: io.to_slice)
  page
end

describe "PDFGraphicsStreamEngine inline image (BI) handling" do
  it "draws a PDInlineImage for a BI operator" do
    page = inline_image_page
    engine = RecordingImageEngine.new(page)
    engine.process_page(page)

    engine.images.size.should eq(1)
    image = engine.images.first
    image.should be_a(Pdfbox::Pdmodel::Graphics::Image::PDInlineImage)
    image.width.should eq(2)
    image.height.should eq(2)
    image.bits_per_component.should eq(8)
    image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
  end
end

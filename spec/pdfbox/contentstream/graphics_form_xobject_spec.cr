require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/PDFGraphicsStreamEngine.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/operator/graphics/DrawObject.java
#
# A content stream `Do` of a Form XObject must be processed recursively so the
# form's operators reach the graphics callbacks. The graphics-engine Do handler
# previously dropped forms.

private class RecordingGraphicsEngine < Pdfbox::Contentstream::PDFGraphicsStreamEngine
  getter rectangles = 0
  getter fills = 0

  def append_rectangle(p0 : Tuple(Float32, Float32), p1 : Tuple(Float32, Float32),
                       p2 : Tuple(Float32, Float32), p3 : Tuple(Float32, Float32)) : Nil
    @rectangles += 1
  end

  def draw_image(pd_image : Pdfbox::Pdmodel::Graphics::Image::PDImage) : Nil
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
    @fills += 1
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
                      code : Int32, displacement : Tuple(Float32, Float32)) : Nil
  end

  def show_type3_glyph(text_rendering_matrix : Pdfbox::Util::Matrix, font : Pdfbox::Pdmodel::Font::PDType3Font,
                       code : Int32, displacement : Tuple(Float32, Float32)) : Nil
  end
end

private def form_page(content : String, form_content : String) : Pdfbox::Pdmodel::Page
  page = Pdfbox::Pdmodel::Page.new

  form = Pdfbox::Cos::Stream.new(data: form_content.to_slice)
  form.set_name(Pdfbox::Cos::Name.new("Subtype"), "Form")
  form[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new([
    Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Integer.new(0),
    Pdfbox::Cos::Integer.new(100), Pdfbox::Cos::Integer.new(100),
  ])
  form[Pdfbox::Cos::Name.new("Resources")] = Pdfbox::Cos::Dictionary.new

  xobjects = Pdfbox::Cos::Dictionary.new
  xobjects[Pdfbox::Cos::Name.new("Fm0")] = form

  resources = Pdfbox::Cos::Dictionary.new
  resources[Pdfbox::Cos::Name.new("XObject")] = xobjects
  page.resources = Pdfbox::Pdmodel::Resources.new(resources)

  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)
  page
end

describe "PDFGraphicsStreamEngine Form XObject handling" do
  it "processes a form XObject's operators (Do)" do
    page = form_page("q /Fm0 Do Q", "0 0 10 10 re f")
    engine = RecordingGraphicsEngine.new(page)
    engine.process_page(page)

    engine.rectangles.should eq(1)
    engine.fills.should eq(1)
  end

  it "processes nested form XObjects using the form's own resources" do
    page = Pdfbox::Pdmodel::Page.new

    inner = Pdfbox::Cos::Stream.new(data: "0 0 10 10 re f".to_slice)
    inner.set_name(Pdfbox::Cos::Name.new("Subtype"), "Form")
    inner[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Integer.new(0),
      Pdfbox::Cos::Integer.new(100), Pdfbox::Cos::Integer.new(100),
    ])
    inner[Pdfbox::Cos::Name.new("Resources")] = Pdfbox::Cos::Dictionary.new

    outer = Pdfbox::Cos::Stream.new(data: "q /FmInner Do Q".to_slice)
    outer.set_name(Pdfbox::Cos::Name.new("Subtype"), "Form")
    outer[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Integer.new(0),
      Pdfbox::Cos::Integer.new(100), Pdfbox::Cos::Integer.new(100),
    ])
    outer_xobjects = Pdfbox::Cos::Dictionary.new
    outer_xobjects[Pdfbox::Cos::Name.new("FmInner")] = inner
    outer_resources = Pdfbox::Cos::Dictionary.new
    outer_resources[Pdfbox::Cos::Name.new("XObject")] = outer_xobjects
    outer[Pdfbox::Cos::Name.new("Resources")] = outer_resources

    page_xobjects = Pdfbox::Cos::Dictionary.new
    page_xobjects[Pdfbox::Cos::Name.new("FmOuter")] = outer
    page_resources = Pdfbox::Cos::Dictionary.new
    page_resources[Pdfbox::Cos::Name.new("XObject")] = page_xobjects
    page.resources = Pdfbox::Pdmodel::Resources.new(page_resources)
    page.contents = Pdfbox::Cos::Stream.new(data: "q /FmOuter Do Q".to_slice)

    engine = RecordingGraphicsEngine.new(page)
    engine.process_page(page)
    engine.rectangles.should eq(1)
    engine.fills.should eq(1)
  end
end

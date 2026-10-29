require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/PDFGraphicsStreamEngine.java
#   contentstream/operator/color/SetStrokingColorN.java (SCN), SetNonStrokingColorN.java (scn)
#   contentstream/operator/graphics/LegacyFillNonZeroRule.java (F)
#
# Java registers the generic color operators SCN/scn (pattern-capable spaces)
# and the legacy fill operator F. The Crystal registry was missing them, so
# those operators were silently dropped.

private class RecordingColorEngine < Pdfbox::Contentstream::PDFGraphicsStreamEngine
  getter fills = 0
  getter strokes = 0
  getter stroking_colors = [] of Array(Float32)
  getter non_stroking_colors = [] of Array(Float32)

  def append_rectangle(p0 : Tuple(Float32, Float32), p1 : Tuple(Float32, Float32),
                       p2 : Tuple(Float32, Float32), p3 : Tuple(Float32, Float32)) : Nil
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
    @strokes += 1
    @stroking_colors << graphics_state.stroking_color.components
  end

  def fill_path(winding_rule : Int32) : Nil
    @fills += 1
    @non_stroking_colors << graphics_state.non_stroking_color.components
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

private def operator_page(content : String) : Pdfbox::Pdmodel::Page
  page = Pdfbox::Pdmodel::Page.new
  page.resources = Pdfbox::Pdmodel::Resources.new(Pdfbox::Cos::Dictionary.new)
  page.contents = Pdfbox::Cos::Stream.new(data: content.to_slice)
  page
end

describe "PDFGraphicsStreamEngine operator names" do
  it "handles the legacy fill operator F" do
    page = operator_page("0 0 10 10 re F")
    engine = RecordingColorEngine.new(page)
    engine.process_page(page)
    engine.fills.should eq(1)
  end

  it "handles SCN (stroking color on pattern-capable spaces)" do
    page = operator_page("1 0 0 RG 0 1 0 SCN 0 0 10 10 re S")
    engine = RecordingColorEngine.new(page)
    engine.process_page(page)
    # processStream saves and restores the graphics state, so the colour has to
    # be observed while the stream is running.
    engine.stroking_colors.should eq([[0.0_f32, 1.0_f32, 0.0_f32]])
  end

  it "handles scn (non-stroking color on pattern-capable spaces)" do
    page = operator_page("1 0 0 rg 0 1 0 scn 0 0 10 10 re f")
    engine = RecordingColorEngine.new(page)
    engine.process_page(page)
    engine.non_stroking_colors.should eq([[0.0_f32, 1.0_f32, 0.0_f32]])
  end
end

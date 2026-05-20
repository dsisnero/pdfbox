# PDFGraphicsStreamEngine - Abstract base for graphics processing.
# Port of Apache PDFBox PDFGraphicsStreamEngine.
#
# This class should be subclassed by end users looking to hook into graphics operations.
# It registers all graphics, text, color, and state operators and defines abstract
# callback methods that subclasses must implement.
require "../cos"
require "../pdmodel"
require "./pdf_stream_engine"
require "../pdmodel/graphics/color/pdcolor"
require "../pdmodel/graphics/color/pdcolor_space"
require "../pdmodel/graphics/color/pddevice_gray"
require "../pdmodel/graphics/color/pddevice_rgb"
require "../pdmodel/graphics/color/pddevice_cmyk"
require "../pdmodel/graphics/state/pd_graphics_state"
require "../pdmodel/graphics/state/pd_soft_mask"
require "../pdmodel/graphics/state/rendering_intent"
require "../pdmodel/graphics/state/rendering_mode"
require "../pdmodel/graphics/state/pd_text_state"
require "../pdmodel/graphics/blend/blend_mode"
require "../pdmodel/graphics/pd_line_dash_pattern"
require "../pdmodel/common/pdrectangle"
require "../util"

module Pdfbox::Contentstream
  # Subclass of PDFStreamEngine for advanced processing of graphics.
  # Provides callback methods for rendering paths, text, images, and other content.
  abstract class PDFGraphicsStreamEngine < PDFStreamEngine
    # Current line path being built
    @line_path : Path2D
    # Winding rule for clipping
    @clip_winding_rule : Int32 = -1

    # Creates a new PDFGraphicsStreamEngine.
    def initialize(@page : Pdmodel::Page?)
      super()
      @line_path = Path2D.new
      @graphics_state_stack = [] of Pdmodel::Graphics::State::PDGraphicsState
      # Initialize with a proper PDGraphicsState to avoid type mismatch with parent's stack
      @graphics_state_stack << Pdmodel::Graphics::State::PDGraphicsState.new
      register_operators
    end

    # Returns the page.
    def page : Pdmodel::Page?
      @page
    end

    # Returns the current graphics state.
    def graphics_state : Pdmodel::Graphics::State::PDGraphicsState
      @graphics_state_stack.last || raise "Graphics state stack empty"
    end

    # Save the graphics state - override to use properly typed stack
    def save_graphics_state : Nil
      @graphics_state_stack << graphics_state
    end

    # Restore the graphics state - override to use properly typed stack
    def restore_graphics_state : Nil
      if @graphics_state_stack.size > 0
        @graphics_state_stack.pop
      end
    end

    # Returns the current line path.
    def line_path : Path2D
      @line_path.not_nil! # ameba:disable Lint/NotNil
    end

    # --- Abstract callback methods that subclasses must implement ---

    # Append a rectangle to the current path.
    abstract def append_rectangle(p0 : Tuple(Float32, Float32),
                                  p1 : Tuple(Float32, Float32),
                                  p2 : Tuple(Float32, Float32),
                                  p3 : Tuple(Float32, Float32)) : Nil

    # Draw an image.
    abstract def draw_image(pd_image : Pdmodel::Graphics::Image::PDImage) : Nil

    # Modify the current clipping path.
    abstract def clip(winding_rule : Int32) : Nil

    # Start a new path at (x, y).
    abstract def move_to(x : Float32, y : Float32) : Nil

    # Draw a line from the current point to (x, y).
    abstract def line_to(x : Float32, y : Float32) : Nil

    # Draw a Bezier curve.
    abstract def curve_to(x1 : Float32, y1 : Float32,
                          x2 : Float32, y2 : Float32,
                          x3 : Float32, y3 : Float32) : Nil

    # Get the current point of the path.
    abstract def current_point : Tuple(Float32, Float32)?

    # Close the current path.
    abstract def close_path : Nil

    # End the current path without filling or stroking.
    abstract def end_path : Nil

    # Stroke the path.
    abstract def stroke_path : Nil

    # Fill the path.
    abstract def fill_path(winding_rule : Int32) : Nil

    # Fill and then stroke the path.
    abstract def fill_and_stroke_path(winding_rule : Int32) : Nil

    # Fill with shading.
    abstract def shading_fill(shading_name : String) : Nil

    # Begin a text object.
    abstract def begin_text : Nil

    # End a text object.
    abstract def end_text : Nil

    # Show a glyph from a font.
    abstract def show_font_glyph(text_rendering_matrix : Util::Matrix,
                                 font : Pdmodel::Font::PDFont,
                                 code : Int32,
                                 displacement : Tuple(Float32, Float32)) : Nil

    # Show a Type 3 glyph.
    abstract def show_type3_glyph(text_rendering_matrix : Util::Matrix,
                                  font : Pdmodel::Font::PDType3Font,
                                  code : Int32,
                                  displacement : Tuple(Float32, Float32)) : Nil

    # --- Path manipulation helpers ---

    # Add a rectangle to the line path.
    def add_rectangle_to_path(p0 : Tuple(Float32, Float32),
                              p1 : Tuple(Float32, Float32),
                              p2 : Tuple(Float32, Float32),
                              p3 : Tuple(Float32, Float32)) : Nil
      path = @line_path
      path.move_to(p0[0], p0[1])
      path.line_to(p1[0], p1[1])
      path.line_to(p2[0], p2[1])
      path.line_to(p3[0], p3[1])
      path.close_path
    end

    # Move to a point in the line path.
    def add_move_to(x : Float32, y : Float32) : Nil
      @line_path.move_to(x, y)
    end

    # Line to a point in the line path.
    def add_line_to(x : Float32, y : Float32) : Nil
      @line_path.line_to(x, y)
    end

    # Add a Bezier curve to the line path.
    def add_curve_to(x1 : Float32, y1 : Float32,
                     x2 : Float32, y2 : Float32,
                     x3 : Float32, y3 : Float32) : Nil
      @line_path.curve_to(x1, y1, x2, y2, x3, y3)
    end

    # Close the line path.
    def add_close_path : Nil
      @line_path.close_path
    end

    # Reset the line path.
    def reset_line_path : Nil
      @line_path.reset
    end

    private def register_operators : Nil
      # Graphics operators
      add_operator(OperatorMoveTo.new(self))
      add_operator(OperatorLineTo.new(self))
      add_operator(OperatorCurveTo.new(self))
      add_operator(OperatorCurveToReplicateInitialPoint.new(self))
      add_operator(OperatorCurveToReplicateFinalPoint.new(self))
      add_operator(OperatorClosePath.new(self))
      add_operator(OperatorAppendRectangle.new(self))
      add_operator(OperatorStrokePath.new(self))
      add_operator(OperatorCloseAndStrokePath.new(self))
      add_operator(OperatorFillNonZeroRule.new(self))
      add_operator(OperatorFillEvenOddRule.new(self))
      add_operator(OperatorFillNonZeroAndStrokePath.new(self))
      add_operator(OperatorFillEvenOddAndStrokePath.new(self))
      add_operator(OperatorCloseFillNonZeroAndStrokePath.new(self))
      add_operator(OperatorCloseFillEvenOddAndStrokePath.new(self))
      add_operator(OperatorEndPath.new(self))
      add_operator(OperatorClipNonZeroRule.new(self))
      add_operator(OperatorClipEvenOddRule.new(self))
      add_operator(OperatorShadingFill.new(self))

      # State operators
      add_operator(OperatorSave.new(self))
      add_operator(OperatorRestore.new(self))
      add_operator(OperatorConcatenate.new(self))
      add_operator(OperatorSetLineWidth.new(self))
      add_operator(OperatorSetLineCapStyle.new(self))
      add_operator(OperatorSetLineJoinStyle.new(self))
      add_operator(OperatorSetLineMiterLimit.new(self))
      add_operator(OperatorSetLineDashPattern.new(self))
      add_operator(OperatorSetFlatness.new(self))
      add_operator(OperatorSetRenderingIntent.new(self))
      add_operator(OperatorSetGraphicsStateParameters.new(self))

      # Text operators
      add_operator(OperatorBeginText.new(self))
      add_operator(OperatorEndText.new(self))
      add_operator(OperatorSetFontAndSize.new(self))
      add_operator(OperatorShowText.new(self))
      add_operator(OperatorShowTextAdjusted.new(self))
      add_operator(OperatorShowTextLine.new(self))
      add_operator(OperatorShowTextLineAndSpace.new(self))
      add_operator(OperatorMoveText.new(self))
      add_operator(OperatorMoveTextSetLeading.new(self))
      add_operator(OperatorSetCharSpacing.new(self))
      add_operator(OperatorSetWordSpacing.new(self))
      add_operator(OperatorSetTextHorizontalScaling.new(self))
      add_operator(OperatorSetTextLeading.new(self))
      add_operator(OperatorSetTextRenderingMode.new(self))
      add_operator(OperatorSetTextRise.new(self))
      add_operator(OperatorNextLine.new(self))

      # Color operators
      add_operator(OperatorSetStrokingColorSpace.new(self))
      add_operator(OperatorSetNonStrokingColorSpace.new(self))
      add_operator(OperatorSetStrokingDeviceGrayColor.new(self))
      add_operator(OperatorSetNonStrokingDeviceGrayColor.new(self))
      add_operator(OperatorSetStrokingDeviceRGBColor.new(self))
      add_operator(OperatorSetNonStrokingDeviceRGBColor.new(self))
      add_operator(OperatorSetStrokingDeviceCMYKColor.new(self))
      add_operator(OperatorSetNonStrokingDeviceCMYKColor.new(self))
      add_operator(OperatorSetStrokingColor.new(self))
      add_operator(OperatorSetNonStrokingColor.new(self))

      # Marked content operators
      add_operator(OperatorBeginMarkedContent.new(self))
      add_operator(OperatorEndMarkedContent.new(self))
      add_operator(OperatorMarkedContentPoint.new(self))
      add_operator(OperatorMarkedContentPointWithProperties.new(self))
      add_operator(OperatorBeginMarkedContentWithProperties.new(self))

      # Draw object operator
      add_operator(OperatorDrawObject.new(self))
    end
  end

  # Simple 2D path for tracking path operations
  class Path2D
    enum SegmentType
      MoveTo
      LineTo
      CurveTo
      ClosePath
    end

    struct Segment
      property type : SegmentType
      property coords : Array(Float32)

      def initialize(@type : SegmentType, @coords : Array(Float32))
      end
    end

    property segments : Array(Segment)

    def initialize
      @segments = [] of Segment
    end

    def move_to(x : Float32, y : Float32) : Nil
      @segments << Segment.new(SegmentType::MoveTo, [x, y])
    end

    def line_to(x : Float32, y : Float32) : Nil
      @segments << Segment.new(SegmentType::LineTo, [x, y])
    end

    def curve_to(x1 : Float32, y1 : Float32,
                 x2 : Float32, y2 : Float32,
                 x3 : Float32, y3 : Float32) : Nil
      @segments << Segment.new(SegmentType::CurveTo, [x1, y1, x2, y2, x3, y3])
    end

    def close_path : Nil
      @segments << Segment.new(SegmentType::ClosePath, [] of Float32)
    end

    def reset : Nil
      @segments.clear
    end

    def clone : Path2D
      copy = Path2D.new
      @segments.each do |seg|
        copy.segments << Segment.new(seg.type, seg.coords.dup)
      end
      copy
    end

    def current_point : Tuple(Float32, Float32)?
      return if @segments.empty?
      last = @segments.last
      case last.type
      when SegmentType::MoveTo
        {last.coords[0], last.coords[1]}
      when SegmentType::LineTo
        {last.coords[0], last.coords[1]}
      when SegmentType::CurveTo
        {last.coords[4], last.coords[5]}
      when SegmentType::ClosePath
        nil
      else
        nil
      end
    end

    def empty? : Bool
      @segments.empty?
    end
  end

  # --- Operator processors for graphics stream engine ---

  # Base class for graphics stream engine operators
  abstract class GraphicsOperatorProcessor < OperatorProcessor
    def initialize(engine : PDFGraphicsStreamEngine)
      super(engine)
    end

    def context : PDFGraphicsStreamEngine
      @engine.as(PDFGraphicsStreamEngine)
    end

    def graphics_context : PDFGraphicsStreamEngine
      @engine.as(PDFGraphicsStreamEngine)
    end
  end

  # MoveTo operator (m)
  class OperatorMoveTo < GraphicsOperatorProcessor
    def name : String
      "m"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      x = arguments[0].as(Cos::Number).value.to_f32
      y = arguments[1].as(Cos::Number).value.to_f32
      context.add_move_to(x, y)
      context.move_to(x, y)
    end
  end

  # LineTo operator (l)
  class OperatorLineTo < GraphicsOperatorProcessor
    def name : String
      "l"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      x = arguments[0].as(Cos::Number).value.to_f32
      y = arguments[1].as(Cos::Number).value.to_f32
      context.add_line_to(x, y)
      context.line_to(x, y)
    end
  end

  # CurveTo operator (c)
  class OperatorCurveTo < GraphicsOperatorProcessor
    def name : String
      "c"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      x1 = arguments[0].as(Cos::Number).value.to_f32
      y1 = arguments[1].as(Cos::Number).value.to_f32
      x2 = arguments[2].as(Cos::Number).value.to_f32
      y2 = arguments[3].as(Cos::Number).value.to_f32
      x3 = arguments[4].as(Cos::Number).value.to_f32
      y3 = arguments[5].as(Cos::Number).value.to_f32
      context.add_curve_to(x1, y1, x2, y2, x3, y3)
      context.curve_to(x1, y1, x2, y2, x3, y3)
    end
  end

  # CurveToReplicateInitialPoint operator (v)
  class OperatorCurveToReplicateInitialPoint < GraphicsOperatorProcessor
    def name : String
      "v"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      x2 = arguments[0].as(Cos::Number).value.to_f32
      y2 = arguments[1].as(Cos::Number).value.to_f32
      x3 = arguments[2].as(Cos::Number).value.to_f32
      y3 = arguments[3].as(Cos::Number).value.to_f32
      current = context.current_point
      if current
        x1 = current[0]
        y1 = current[1]
        context.add_curve_to(x1, y1, x2, y2, x3, y3)
        context.curve_to(x1, y1, x2, y2, x3, y3)
      end
    end
  end

  # CurveToReplicateFinalPoint operator (y)
  class OperatorCurveToReplicateFinalPoint < GraphicsOperatorProcessor
    def name : String
      "y"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      x1 = arguments[0].as(Cos::Number).value.to_f32
      y1 = arguments[1].as(Cos::Number).value.to_f32
      x3 = arguments[2].as(Cos::Number).value.to_f32
      y3 = arguments[3].as(Cos::Number).value.to_f32
      context.add_curve_to(x1, y1, x3, y3, x3, y3)
      context.curve_to(x1, y1, x3, y3, x3, y3)
    end
  end

  # ClosePath operator (h)
  class OperatorClosePath < GraphicsOperatorProcessor
    def name : String
      "h"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.add_close_path
      context.close_path
    end
  end

  # AppendRectangle operator (re)
  class OperatorAppendRectangle < GraphicsOperatorProcessor
    def name : String
      "re"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      x = arguments[0].as(Cos::Number).value.to_f32
      y = arguments[1].as(Cos::Number).value.to_f32
      w = arguments[2].as(Cos::Number).value.to_f32
      h = arguments[3].as(Cos::Number).value.to_f32
      p0 = {x, y}
      p1 = {x + w, y}
      p2 = {x + w, y + h}
      p3 = {x, y + h}
      context.add_rectangle_to_path(p0, p1, p2, p3)
      context.append_rectangle(p0, p1, p2, p3)
    end
  end

  # StrokePath operator (S)
  class OperatorStrokePath < GraphicsOperatorProcessor
    def name : String
      "S"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.stroke_path
    end
  end

  # CloseAndStrokePath operator (s)
  class OperatorCloseAndStrokePath < GraphicsOperatorProcessor
    def name : String
      "s"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.add_close_path
      context.close_path
      context.stroke_path
    end
  end

  # FillNonZeroRule operator (f)
  class OperatorFillNonZeroRule < GraphicsOperatorProcessor
    def name : String
      "f"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.fill_path(0) # WIND_NON_ZERO
    end
  end

  # FillEvenOddRule operator (f*)
  class OperatorFillEvenOddRule < GraphicsOperatorProcessor
    def name : String
      "f*"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.fill_path(1) # WIND_EVEN_ODD
    end
  end

  # FillNonZeroAndStrokePath operator (B)
  class OperatorFillNonZeroAndStrokePath < GraphicsOperatorProcessor
    def name : String
      "B"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.fill_and_stroke_path(0)
    end
  end

  # FillEvenOddAndStrokePath operator (B*)
  class OperatorFillEvenOddAndStrokePath < GraphicsOperatorProcessor
    def name : String
      "B*"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.fill_and_stroke_path(1)
    end
  end

  # CloseFillNonZeroAndStrokePath operator (b)
  class OperatorCloseFillNonZeroAndStrokePath < GraphicsOperatorProcessor
    def name : String
      "b"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.add_close_path
      context.close_path
      context.fill_and_stroke_path(0)
    end
  end

  # CloseFillEvenOddAndStrokePath operator (b*)
  class OperatorCloseFillEvenOddAndStrokePath < GraphicsOperatorProcessor
    def name : String
      "b*"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.add_close_path
      context.close_path
      context.fill_and_stroke_path(1)
    end
  end

  # EndPath operator (n)
  class OperatorEndPath < GraphicsOperatorProcessor
    def name : String
      "n"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.end_path
    end
  end

  # ClipNonZeroRule operator (W)
  class OperatorClipNonZeroRule < GraphicsOperatorProcessor
    def name : String
      "W"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.clip(0)
    end
  end

  # ClipEvenOddRule operator (W*)
  class OperatorClipEvenOddRule < GraphicsOperatorProcessor
    def name : String
      "W*"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.clip(1)
    end
  end

  # ShadingFill operator (sh)
  class OperatorShadingFill < GraphicsOperatorProcessor
    def name : String
      "sh"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      shading_name = arguments[0].as(Cos::Name).value
      context.shading_fill(shading_name)
    end
  end

  # Save graphics state operator (q)
  class OperatorSave < GraphicsOperatorProcessor
    def name : String
      "q"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.save_graphics_state
    end
  end

  # Restore graphics state operator (Q)
  class OperatorRestore < GraphicsOperatorProcessor
    def name : String
      "Q"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.restore_graphics_state
    end
  end

  # Concatenate matrix operator (cm)
  class OperatorConcatenate < GraphicsOperatorProcessor
    def name : String
      "cm"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      a = arguments[0].as(Cos::Number).value.to_f32
      b = arguments[1].as(Cos::Number).value.to_f32
      c = arguments[2].as(Cos::Number).value.to_f32
      d = arguments[3].as(Cos::Number).value.to_f32
      e = arguments[4].as(Cos::Number).value.to_f32
      f = arguments[5].as(Cos::Number).value.to_f32
      matrix = Util::Matrix.new(a, b, c, d, e, f)
      context.graphics_state.current_transformation_matrix.concatenate(matrix)
    end
  end

  # SetLineWidth operator (w)
  class OperatorSetLineWidth < GraphicsOperatorProcessor
    def name : String
      "w"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      width = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.line_width = width
    end
  end

  # SetLineCapStyle operator (J)
  class OperatorSetLineCapStyle < GraphicsOperatorProcessor
    def name : String
      "J"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      cap = arguments[0].as(Cos::Number).value.to_i32
      context.graphics_state.line_cap = cap
    end
  end

  # SetLineJoinStyle operator (j)
  class OperatorSetLineJoinStyle < GraphicsOperatorProcessor
    def name : String
      "j"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      join = arguments[0].as(Cos::Number).value.to_i32
      context.graphics_state.line_join = join
    end
  end

  # SetLineMiterLimit operator (M)
  class OperatorSetLineMiterLimit < GraphicsOperatorProcessor
    def name : String
      "M"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      limit = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.miter_limit = limit
    end
  end

  # SetLineDashPattern operator (d)
  class OperatorSetLineDashPattern < GraphicsOperatorProcessor
    def name : String
      "d"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      dash_array = arguments[0].as(Cos::Array)
      phase = arguments[1].as(Cos::Number).value.to_i32
      context.graphics_state.line_dash_pattern = Pdmodel::Graphics::PDLineDashPattern.new(dash_array, phase)
    end
  end

  # SetFlatness operator (i)
  class OperatorSetFlatness < GraphicsOperatorProcessor
    def name : String
      "i"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      flatness = arguments[0].as(Cos::Number).value.to_f64
      context.graphics_state.flatness = flatness
    end
  end

  # SetRenderingIntent operator (ri)
  class OperatorSetRenderingIntent < GraphicsOperatorProcessor
    def name : String
      "ri"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      intent_name = arguments[0].as(Cos::Name).value
      context.graphics_state.rendering_intent = Pdmodel::Graphics::State::RenderingIntent.from_string(intent_name)
    end
  end

  # SetGraphicsStateParameters operator (gs)
  class OperatorSetGraphicsStateParameters < GraphicsOperatorProcessor
    def name : String
      "gs"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      base = arguments[0]
      return unless base.is_a?(Cos::Name)
      resources = context.resources
      return unless resources
      gs = resources.ext_g_state(base)
      if gs
        gs.copy_into_graphics_state(context.graphics_state)
      end
    end
  end

  # BeginText operator (BT)
  class OperatorBeginText < GraphicsOperatorProcessor
    def name : String
      "BT"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.graphics_state.text_matrix = Util::Matrix.identity
      context.graphics_state.text_line_matrix = Util::Matrix.identity
      context.begin_text
    end
  end

  # EndText operator (ET)
  class OperatorEndText < GraphicsOperatorProcessor
    def name : String
      "ET"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.end_text
    end
  end

  # SetFontAndSize operator (Tf)
  class OperatorSetFontAndSize < GraphicsOperatorProcessor
    def name : String
      "Tf"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      font_arg = arguments[0].as(Cos::Name)
      font_size = arguments[1].as(Cos::Number).value.to_f32
      resources = context.resources
      if resources
        font = resources.font(font_arg)
        if font.is_a?(Pdfbox::Pdmodel::Font::PDFont)
          context.graphics_state.text_state.font = font
        end
        context.graphics_state.text_state.font_size = font_size
      end
    end
  end

  # ShowText operator (Tj)
  class OperatorShowText < GraphicsOperatorProcessor
    def name : String
      "Tj"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      context.show_text_string(arguments[0])
    end
  end

  # ShowTextAdjusted operator (TJ)
  class OperatorShowTextAdjusted < GraphicsOperatorProcessor
    def name : String
      "TJ"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      base = arguments[0]
      return unless base.is_a?(Cos::Array)
      context.show_text_strings(base)
    end
  end

  # ShowTextLine operator (')
  class OperatorShowTextLine < GraphicsOperatorProcessor
    def name : String
      "'"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      # Move to next line
      leading = context.graphics_state.text_state.leading
      context.graphics_state.text_matrix = context.graphics_state.text_line_matrix.clone
      context.graphics_state.text_matrix.try(&.translate(0.0_f32, -leading))
      context.graphics_state.text_line_matrix = context.graphics_state.text_matrix.clone
      # Show text
      context.show_text_string(arguments[0]) unless arguments.empty?
    end
  end

  # ShowTextLineAndSpace operator (")
  class OperatorShowTextLineAndSpace < GraphicsOperatorProcessor
    def name : String
      "\""
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.size < 3
      # Set word spacing
      aw = arguments[0]
      if aw.is_a?(Cos::Integer) || aw.is_a?(Cos::Float)
        context.graphics_state.text_state.word_spacing = aw.as(Cos::Number).value.to_f32
      end
      # Set character spacing
      ac = arguments[1]
      if ac.is_a?(Cos::Integer) || ac.is_a?(Cos::Float)
        context.graphics_state.text_state.character_spacing = ac.as(Cos::Number).value.to_f32
      end
      # Move to next line and show text
      leading = context.graphics_state.text_state.leading
      context.graphics_state.text_matrix = context.graphics_state.text_line_matrix.clone
      context.graphics_state.text_matrix.try(&.translate(0.0_f32, -leading))
      context.graphics_state.text_line_matrix = context.graphics_state.text_matrix.clone
      context.show_text_string(arguments[2])
    end
  end

  # MoveText operator (Td)
  class OperatorMoveText < GraphicsOperatorProcessor
    def name : String
      "Td"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      tx = arguments[0].as(Cos::Number).value.to_f32
      ty = arguments[1].as(Cos::Number).value.to_f32
      context.graphics_state.text_matrix = context.graphics_state.text_line_matrix.clone
      context.graphics_state.text_matrix.try(&.translate(tx, ty))
      context.graphics_state.text_line_matrix = context.graphics_state.text_matrix.clone
    end
  end

  # MoveTextSetLeading operator (TD)
  class OperatorMoveTextSetLeading < GraphicsOperatorProcessor
    def name : String
      "TD"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      tx = arguments[0].as(Cos::Number).value.to_f32
      ty = arguments[1].as(Cos::Number).value.to_f32
      context.graphics_state.text_state.leading = -ty
      context.graphics_state.text_matrix = context.graphics_state.text_line_matrix.clone
      context.graphics_state.text_matrix.try(&.translate(tx, ty))
      context.graphics_state.text_line_matrix = context.graphics_state.text_matrix.clone
    end
  end

  # SetCharSpacing operator (Tc)
  class OperatorSetCharSpacing < GraphicsOperatorProcessor
    def name : String
      "Tc"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      spacing = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.text_state.character_spacing = spacing
    end
  end

  # SetWordSpacing operator (Tw)
  class OperatorSetWordSpacing < GraphicsOperatorProcessor
    def name : String
      "Tw"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      spacing = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.text_state.word_spacing = spacing
    end
  end

  # SetTextHorizontalScaling operator (Tz)
  class OperatorSetTextHorizontalScaling < GraphicsOperatorProcessor
    def name : String
      "Tz"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      scaling = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.text_state.horizontal_scaling = scaling
    end
  end

  # SetTextLeading operator (TL)
  class OperatorSetTextLeading < GraphicsOperatorProcessor
    def name : String
      "TL"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      leading = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.text_state.leading = leading
    end
  end

  # SetTextRenderingMode operator (Tr)
  class OperatorSetTextRenderingMode < GraphicsOperatorProcessor
    def name : String
      "Tr"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      mode = arguments[0].as(Cos::Number).value.to_i32
      context.graphics_state.text_state.rendering_mode = Pdmodel::Graphics::State::RenderingMode.from_int(mode)
    end
  end

  # SetTextRise operator (Ts)
  class OperatorSetTextRise < GraphicsOperatorProcessor
    def name : String
      "Ts"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      rise = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.text_state.rise = rise
    end
  end

  # NextLine operator (T*)
  class OperatorNextLine < GraphicsOperatorProcessor
    def name : String
      "T*"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      leading = context.graphics_state.text_state.leading
      context.graphics_state.text_matrix = context.graphics_state.text_line_matrix.clone
      context.graphics_state.text_matrix.try(&.translate(0.0_f32, -leading))
      context.graphics_state.text_line_matrix = context.graphics_state.text_matrix.clone
    end
  end

  # SetStrokingColorSpace operator (CS)
  class OperatorSetStrokingColorSpace < GraphicsOperatorProcessor
    def name : String
      "CS"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      name_arg = arguments[0]
      return unless name_arg.is_a?(Cos::Name)
      resources = context.resources
      return unless resources
      cs = resources.color_space(name_arg)
      return unless cs
      context.graphics_state.stroking_color_space = cs
      context.graphics_state.stroking_color = cs.initial_color
    end
  end

  # SetNonStrokingColorSpace operator (cs)
  class OperatorSetNonStrokingColorSpace < GraphicsOperatorProcessor
    def name : String
      "cs"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      name_arg = arguments[0]
      return unless name_arg.is_a?(Cos::Name)
      resources = context.resources
      return unless resources
      cs = resources.color_space(name_arg)
      return unless cs
      context.graphics_state.non_stroking_color_space = cs
      context.graphics_state.non_stroking_color = cs.initial_color
    end
  end

  # SetStrokingDeviceGrayColor operator (G)
  class OperatorSetStrokingDeviceGrayColor < GraphicsOperatorProcessor
    def name : String
      "G"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      gray = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.stroking_color_space = Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
      context.graphics_state.stroking_color = Pdmodel::Graphics::Color::PDColor.new([gray], Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
    end
  end

  # SetNonStrokingDeviceGrayColor operator (g)
  class OperatorSetNonStrokingDeviceGrayColor < GraphicsOperatorProcessor
    def name : String
      "g"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      gray = arguments[0].as(Cos::Number).value.to_f32
      context.graphics_state.non_stroking_color_space = Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
      context.graphics_state.non_stroking_color = Pdmodel::Graphics::Color::PDColor.new([gray], Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
    end
  end

  # SetStrokingDeviceRGBColor operator (RG)
  class OperatorSetStrokingDeviceRGBColor < GraphicsOperatorProcessor
    def name : String
      "RG"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      r = arguments[0].as(Cos::Number).value.to_f32
      g = arguments[1].as(Cos::Number).value.to_f32
      b = arguments[2].as(Cos::Number).value.to_f32
      context.graphics_state.stroking_color_space = Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
      context.graphics_state.stroking_color = Pdmodel::Graphics::Color::PDColor.new([r, g, b], Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    end
  end

  # SetNonStrokingDeviceRGBColor operator (rg)
  class OperatorSetNonStrokingDeviceRGBColor < GraphicsOperatorProcessor
    def name : String
      "rg"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      r = arguments[0].as(Cos::Number).value.to_f32
      g = arguments[1].as(Cos::Number).value.to_f32
      b = arguments[2].as(Cos::Number).value.to_f32
      context.graphics_state.non_stroking_color_space = Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
      context.graphics_state.non_stroking_color = Pdmodel::Graphics::Color::PDColor.new([r, g, b], Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    end
  end

  # SetStrokingDeviceCMYKColor operator (K)
  class OperatorSetStrokingDeviceCMYKColor < GraphicsOperatorProcessor
    def name : String
      "K"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      c = arguments[0].as(Cos::Number).value.to_f32
      m = arguments[1].as(Cos::Number).value.to_f32
      y = arguments[2].as(Cos::Number).value.to_f32
      k = arguments[3].as(Cos::Number).value.to_f32
      context.graphics_state.stroking_color_space = Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE
      context.graphics_state.stroking_color = Pdmodel::Graphics::Color::PDColor.new([c, m, y, k], Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE)
    end
  end

  # SetNonStrokingDeviceCMYKColor operator (k)
  class OperatorSetNonStrokingDeviceCMYKColor < GraphicsOperatorProcessor
    def name : String
      "k"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      c = arguments[0].as(Cos::Number).value.to_f32
      m = arguments[1].as(Cos::Number).value.to_f32
      y = arguments[2].as(Cos::Number).value.to_f32
      k = arguments[3].as(Cos::Number).value.to_f32
      context.graphics_state.non_stroking_color_space = Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE
      context.graphics_state.non_stroking_color = Pdmodel::Graphics::Color::PDColor.new([c, m, y, k], Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE)
    end
  end

  # SetStrokingColor operator (SC)
  class OperatorSetStrokingColor < GraphicsOperatorProcessor
    def name : String
      "SC"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      cs = context.graphics_state.stroking_color_space
      return unless cs
      components = arguments.map do |arg|
        arg = arg.object if arg.is_a?(Cos::Object)
        arg.is_a?(Cos::Number) ? arg.value.to_f32 : 0.0_f32
      end
      context.graphics_state.stroking_color = Pdmodel::Graphics::Color::PDColor.new(components, cs)
    end
  end

  # SetNonStrokingColor operator (sc)
  class OperatorSetNonStrokingColor < GraphicsOperatorProcessor
    def name : String
      "sc"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      cs = context.graphics_state.non_stroking_color_space
      return unless cs
      components = arguments.map do |arg|
        arg = arg.object if arg.is_a?(Cos::Object)
        arg.is_a?(Cos::Number) ? arg.value.to_f32 : 0.0_f32
      end
      context.graphics_state.non_stroking_color = Pdmodel::Graphics::Color::PDColor.new(components, cs)
    end
  end

  # BeginMarkedContent operator (BMC)
  class OperatorBeginMarkedContent < GraphicsOperatorProcessor
    def name : String
      "BMC"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      tag = nil
      arguments.each do |arg|
        tag = arg if arg.is_a?(Cos::Name)
      end
      context.begin_marked_content_sequence(tag, nil)
    end
  end

  # EndMarkedContent operator (EMC)
  class OperatorEndMarkedContent < GraphicsOperatorProcessor
    def name : String
      "EMC"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      context.end_marked_content_sequence
    end
  end

  # MarkedContentPoint operator (MP)
  class OperatorMarkedContentPoint < GraphicsOperatorProcessor
    def name : String
      "MP"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      tag = arguments[0]
      return unless tag.is_a?(Cos::Name)
      context.marked_content_point(tag, nil)
    end
  end

  # MarkedContentPointWithProperties operator (DP)
  class OperatorMarkedContentPointWithProperties < GraphicsOperatorProcessor
    def name : String
      "DP"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.size < 2
      tag = arguments[0]
      return unless tag.is_a?(Cos::Name)
      op1 = arguments[1]
      prop_dict = resolve_property_dict(op1)
      return unless prop_dict
      context.marked_content_point(tag, prop_dict)
    end

    private def resolve_property_dict(op : Cos::Base) : Cos::Dictionary?
      if op.is_a?(Cos::Name)
        resources = context.resources
        return unless resources
        prop = resources.properties(op)
        return unless prop
        prop.cos_object.is_a?(Cos::Dictionary) ? prop.cos_object : nil
      elsif op.is_a?(Cos::Dictionary)
        op
      end
    end
  end

  # BeginMarkedContentSequenceWithProperties operator (BDC)
  class OperatorBeginMarkedContentWithProperties < GraphicsOperatorProcessor
    def name : String
      "BDC"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.size < 2
      tag = arguments[0]
      return unless tag.is_a?(Cos::Name)
      op1 = arguments[1]
      prop_dict = _resolve_prop_dict(op1)
      return unless prop_dict
      context.begin_marked_content_sequence(tag, prop_dict)
    end

    private def _resolve_prop_dict(op : Cos::Base) : Cos::Dictionary?
      if op.is_a?(Cos::Name)
        resources = context.resources
        return unless resources
        prop = resources.properties(op)
        return unless prop
        prop.cos_object.is_a?(Cos::Dictionary) ? prop.cos_object : nil
      elsif op.is_a?(Cos::Dictionary)
        op
      end
    end
  end

  # DrawObject operator (Do)
  class OperatorDrawObject < GraphicsOperatorProcessor
    def name : String
      "Do"
    end

    def process(arguments : Array(Cos::Base)) : Nil
      return if arguments.empty?
      name_arg = arguments[0]
      return unless name_arg.is_a?(Cos::Name)

      page = context.page
      return unless page

      resources = page.resources
      return unless resources

      xobject = resources.xobject(name_arg)
      return unless xobject

      # Resolve indirect references
      if xobject.is_a?(Cos::Object)
        xobject = xobject.object
      end

      return unless xobject.is_a?(Cos::Dictionary)

      subtype = xobject[Cos::Name.new("Subtype")]?
      return unless subtype.is_a?(Cos::Name)

      case subtype.value
      when "Image"
        doc = Pdmodel::Document.new # Use page's document context
        image = Pdmodel::Graphics::Image::PDImageXObject.new(doc, xobject, xobject.as?(Cos::Stream))
        context.draw_image(image)
      when "Form"
        # Form XObject handling - not yet implemented
      end
    end
  end
end

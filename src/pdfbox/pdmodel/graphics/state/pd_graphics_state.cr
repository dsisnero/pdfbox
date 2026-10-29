# The current state of graphics parameters when executing a content stream.
# Port of Apache PDFBox PDGraphicsState.
module Pdfbox::Pdmodel::Graphics::State
  class PDGraphicsState
    property current_transformation_matrix : Pdfbox::Util::Matrix
    property stroking_color : Pdfbox::Pdmodel::Graphics::Color::PDColor
    property non_stroking_color : Pdfbox::Pdmodel::Graphics::Color::PDColor
    property stroking_color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace
    property non_stroking_color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace
    property text_state : PDTextState
    property line_width : Float32
    property line_cap : Int32
    property line_join : Int32
    property miter_limit : Float32
    property line_dash_pattern : Pdfbox::Pdmodel::Graphics::PDLineDashPattern
    property rendering_intent : RenderingIntent?
    property stroke_adjustment : Bool # ameba:disable Naming/QueryBoolMethods
    property blend_mode : Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    property soft_mask : PDSoftMask?
    property alpha_constant : Float64
    property non_stroking_alpha_constant : Float64
    property alpha_source : Bool # ameba:disable Naming/QueryBoolMethods
    # Java PDGraphicsState declares both text matrices as `new Matrix()`, so they
    # are never null.
    property text_matrix : Pdfbox::Util::Matrix
    property text_line_matrix : Pdfbox::Util::Matrix
    property transfer : Pdfbox::Cos::Base?

    # Device-dependent parameters
    property overprint : Bool              # ameba:disable Naming/QueryBoolMethods
    property non_stroking_overprint : Bool # ameba:disable Naming/QueryBoolMethods
    property overprint_mode : Int32
    property flatness : Float64
    property smoothness : Float64

    # Constructor with a given page size to initialize the clipping path.
    def initialize(page : Pdfbox::Pdmodel::Common::PDRectangle)
      @current_transformation_matrix = Pdfbox::Util::Matrix.new
      @stroking_color = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE.initial_color
      @non_stroking_color = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE.initial_color
      @stroking_color_space = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
      @non_stroking_color_space = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
      @text_state = PDTextState.new
      @line_width = 1.0_f32
      @line_cap = 0_i32  # CAP_BUTT
      @line_join = 0_i32 # JOIN_MITER
      @miter_limit = 10.0_f32
      @line_dash_pattern = Pdfbox::Pdmodel::Graphics::PDLineDashPattern.new
      @rendering_intent = nil
      @stroke_adjustment = false
      @blend_mode = Pdfbox::Pdmodel::Graphics::Blend::BlendMode.new
      @soft_mask = nil
      @alpha_constant = 1.0
      @non_stroking_alpha_constant = 1.0
      @alpha_source = false
      @text_matrix = Pdfbox::Util::Matrix.new
      @text_line_matrix = Pdfbox::Util::Matrix.new
      @overprint = false
      @non_stroking_overprint = false
      @overprint_mode = 0
      @flatness = 1.0
      @smoothness = 0.0
    end

    # Default constructor (no page clipping path).
    def initialize
      @current_transformation_matrix = Pdfbox::Util::Matrix.new
      @stroking_color = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE.initial_color
      @non_stroking_color = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE.initial_color
      @stroking_color_space = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
      @non_stroking_color_space = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
      @text_state = PDTextState.new
      @line_width = 1.0_f32
      @line_cap = 0_i32
      @line_join = 0_i32
      @miter_limit = 10.0_f32
      @line_dash_pattern = Pdfbox::Pdmodel::Graphics::PDLineDashPattern.new
      @rendering_intent = nil
      @stroke_adjustment = false
      @blend_mode = Pdfbox::Pdmodel::Graphics::Blend::BlendMode.new
      @soft_mask = nil
      @alpha_constant = 1.0
      @non_stroking_alpha_constant = 1.0
      @alpha_source = false
      @text_matrix = Pdfbox::Util::Matrix.new
      @text_line_matrix = Pdfbox::Util::Matrix.new
      @overprint = false
      @non_stroking_overprint = false
      @overprint_mode = 0
      @flatness = 1.0
      @smoothness = 0.0
    end

    # Creates a deep copy of this graphics state.
    def clone : PDGraphicsState
      copy = PDGraphicsState.new
      copy.current_transformation_matrix = @current_transformation_matrix.clone
      copy.stroking_color = @stroking_color
      copy.non_stroking_color = @non_stroking_color
      copy.stroking_color_space = @stroking_color_space
      copy.non_stroking_color_space = @non_stroking_color_space
      copy.text_state = @text_state.clone
      copy.line_width = @line_width
      copy.line_cap = @line_cap
      copy.line_join = @line_join
      copy.miter_limit = @miter_limit
      copy.line_dash_pattern = @line_dash_pattern
      copy.rendering_intent = @rendering_intent
      copy.stroke_adjustment = @stroke_adjustment
      copy.blend_mode = @blend_mode
      copy.soft_mask = @soft_mask
      copy.alpha_constant = @alpha_constant
      copy.non_stroking_alpha_constant = @non_stroking_alpha_constant
      copy.alpha_source = @alpha_source
      copy.text_line_matrix = @text_line_matrix.clone
      copy.text_matrix = @text_matrix.clone
      copy.overprint = @overprint
      copy.non_stroking_overprint = @non_stroking_overprint
      copy.overprint_mode = @overprint_mode
      copy.flatness = @flatness
      copy.smoothness = @smoothness
      copy.transfer = @transfer
      copy
    end

    # --- Text state accessors used by PDFStreamEngine ---
    #
    # Java's stream engine reads and writes `getGraphicsState().getTextState()`
    # directly. The port's engine drives two graphics-state classes: the plain
    # `GraphicsState` of `PDFStreamEngine` and this Java-shaped state of
    # `PDFGraphicsStreamEngine`. Both answer to the same messages, so the shared
    # operator handling works on either. The types here match `GraphicsState`
    # (Float64/Int32); PDTextState stores Java floats, so values are narrowed on
    # the way in.
    def font : Pdfbox::Pdmodel::Font::PDFont?
      @text_state.font
    end

    def font=(value : Pdfbox::Pdmodel::Font::PDFont?) : Pdfbox::Pdmodel::Font::PDFont?
      @text_state.font = value
    end

    def font_size : Float64
      @text_state.font_size.to_f64
    end

    def font_size=(value : Float64) : Float64
      @text_state.font_size = value.to_f32
      value
    end

    def horizontal_scaling : Float64
      @text_state.horizontal_scaling.to_f64
    end

    def horizontal_scaling=(value : Float64) : Float64
      @text_state.horizontal_scaling = value.to_f32
      value
    end

    def character_spacing : Float64
      @text_state.character_spacing.to_f64
    end

    def character_spacing=(value : Float64) : Float64
      @text_state.character_spacing = value.to_f32
      value
    end

    def word_spacing : Float64
      @text_state.word_spacing.to_f64
    end

    def word_spacing=(value : Float64) : Float64
      @text_state.word_spacing = value.to_f32
      value
    end

    # Java PDTextState#getLeading; the engine calls it text leading.
    def text_leading : Float64
      @text_state.leading.to_f64
    end

    def text_leading=(value : Float64) : Float64
      @text_state.leading = value.to_f32
      value
    end

    def text_rise : Float64
      @text_state.rise.to_f64
    end

    def text_rise=(value : Float64) : Float64
      @text_state.rise = value.to_f32
      value
    end

    # Java PDTextState#get/setRenderingMode, addressed with the operator's
    # integer value like the engine's `Tr` handling.
    def text_rendering_mode : Int32
      @text_state.rendering_mode.int_value
    end

    def text_rendering_mode=(value : Int32) : Int32
      @text_state.rendering_mode = RenderingMode.from_int(value)
      value
    end
  end
end

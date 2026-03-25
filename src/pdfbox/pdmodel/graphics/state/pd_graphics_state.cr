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
    property text_matrix : Pdfbox::Util::Matrix?
    property text_line_matrix : Pdfbox::Util::Matrix?

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
      @text_matrix = nil
      @text_line_matrix = nil
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
      @text_matrix = nil
      @text_line_matrix = nil
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
      copy.text_line_matrix = @text_line_matrix.try(&.clone)
      copy.text_matrix = @text_matrix.try(&.clone)
      copy.overprint = @overprint
      copy.non_stroking_overprint = @non_stroking_overprint
      copy.overprint_mode = @overprint_mode
      copy.flatness = @flatness
      copy.smoothness = @smoothness
      copy
    end
  end
end

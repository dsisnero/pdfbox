module Pdfbox::Pdmodel::Graphics::State
  class PDExtendedGraphicsState
    include Pdfbox::Pdmodel::Common::COSObjectable

    def initialize(@dict : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end

    # Copies all properties from this extended graphics state into the given graphics state.
    # Port of Java PDExtendedGraphicsState.copyIntoGraphicsState.
    def copy_into_graphics_state(gs : PDGraphicsState) : Nil
      @dict.entries.each do |key, _value|
        key_name = key.value
        case key_name
        when "LW"
          v = line_width
          gs.line_width = v || 1.0_f32
        when "LC"
          gs.line_cap = line_cap_style
        when "LJ"
          gs.line_join = line_join_style
        when "ML"
          v = miter_limit
          gs.miter_limit = v || 10.0_f32
        when "D"
          if p = line_dash_pattern
            gs.line_dash_pattern = p
          end
        when "RI"
          if ri = rendering_intent
            gs.rendering_intent = ri
          end
        when "OPM"
          gs.overprint_mode = overprint_mode || 0
        when "OP"
          gs.overprint = stroking_overprint_control
        when "op"
          gs.non_stroking_overprint = non_stroking_overprint_control
        when "FL"
          v = flatness_tolerance
          gs.flatness = (v || 1.0).to_f64
        when "SM"
          v = smoothness_tolerance
          gs.smoothness = (v || 0.0).to_f64
        when "SA"
          gs.stroke_adjustment = automatic_stroke_adjustment
        when "CA"
          v = stroking_alpha_constant
          gs.alpha_constant = v || 1.0_f64
        when "ca"
          v = non_stroking_alpha_constant
          gs.non_stroking_alpha_constant = v || 1.0_f64
        when "AIS"
          gs.alpha_source = alpha_source_flag
        when "TK"
          gs.text_state.knockout = text_knockout_flag
        when "SMASK"
          if mask = soft_mask
            mask.initial_transformation_matrix = gs.current_transformation_matrix.clone
            gs.soft_mask = mask
          end
        when "BM"
          if bm = blend_mode
            gs.blend_mode = bm
          end
        when "Font"
          if setting = font_setting
            gs.text_state.font = setting.font
            gs.text_state.font_size = setting.font_size
          end
        end
      end
    end

    # --- Getters for dictionary entries ---

    def line_width : Float32?
      get_float_item("LW")
    end

    def line_cap_style : Int32
      @dict.get_int(Pdfbox::Cos::Name.new("LC"), 0_i64).to_i32
    end

    def line_join_style : Int32
      @dict.get_int(Pdfbox::Cos::Name.new("LJ"), 0_i64).to_i32
    end

    def miter_limit : Float32?
      get_float_item("ML")
    end

    def line_dash_pattern : PDLineDashPattern?
      dash = @dict[Pdfbox::Cos::Name.new("D")]
      dash = dash.object if dash.is_a?(Pdfbox::Cos::Object)
      return unless dash.is_a?(Pdfbox::Cos::Array) && dash.size >= 2
      phase_item = dash[dash.size - 1]
      phase_item = phase_item.object if phase_item.is_a?(Pdfbox::Cos::Object)
      phase = phase_item.is_a?(Pdfbox::Cos::Number) ? phase_item.value.to_i32 : 0
      PDLineDashPattern.new(dash, phase)
    end

    def rendering_intent : RenderingIntent?
      ri = @dict[Pdfbox::Cos::Name.new("RI")]
      ri = ri.object if ri.is_a?(Pdfbox::Cos::Object)
      return unless ri.is_a?(Pdfbox::Cos::Name)
      RenderingIntent.from_string(ri.value)
    end

    def overprint_mode : Int32?
      v = @dict[Pdfbox::Cos::Name.new("OPM")]
      v = v.object if v.is_a?(Pdfbox::Cos::Object)
      return unless v.is_a?(Pdfbox::Cos::Integer)
      v.value.to_i32
    end

    def stroking_overprint_control : Bool
      dict_get_bool("OP", false)
    end

    def non_stroking_overprint_control : Bool
      dict_get_bool("op", false)
    end

    def flatness_tolerance : Float32?
      get_float_item("FL")
    end

    def smoothness_tolerance : Float32?
      get_float_item("SM")
    end

    def automatic_stroke_adjustment : Bool
      dict_get_bool("SA", true)
    end

    def stroking_alpha_constant : Float64?
      get_float_item("CA").try(&.to_f64)
    end

    def non_stroking_alpha_constant : Float64?
      get_float_item("ca").try(&.to_f64)
    end

    def alpha_source_flag : Bool
      dict_get_bool("AIS", false)
    end

    def alpha_source_flag=(value : Bool) : Bool
      @dict.set_boolean(Pdfbox::Cos::Name.new("AIS"), value)
      value
    end

    def stroking_alpha_constant=(value : Number) : Float64
      float_value = value.to_f64
      @dict.set_float(Pdfbox::Cos::Name.new("CA"), float_value)
      float_value
    end

    def non_stroking_alpha_constant=(value : Number) : Float64
      float_value = value.to_f64
      @dict.set_float(Pdfbox::Cos::Name.new("ca"), float_value)
      float_value
    end

    def text_knockout_flag : Bool
      dict_get_bool("TK", true)
    end

    def soft_mask : PDSoftMask?
      sm = @dict[Pdfbox::Cos::Name.new("SMask")]
      sm = sm.object if sm.is_a?(Pdfbox::Cos::Object)
      return unless sm.is_a?(Pdfbox::Cos::Dictionary)
      PDSoftMask.new(sm)
    end

    def blend_mode : Pdfbox::Pdmodel::Graphics::Blend::BlendMode?
      bm = @dict[Pdfbox::Cos::Name.new("BM")]
      return unless bm
      Blend::BlendMode.get_instance(bm)
    rescue
      nil
    end

    def blend_mode=(value : Pdfbox::Pdmodel::Graphics::Blend::BlendMode) : Pdfbox::Pdmodel::Graphics::Blend::BlendMode
      @dict[Pdfbox::Cos::Name.new("BM")] = Pdfbox::Cos::Name.new(value.mode.to_cos_name)
      value
    end

    def font_setting : FontSetting?
      f = @dict[Pdfbox::Cos::Name.new("Font")]
      f = f.object if f.is_a?(Pdfbox::Cos::Object)
      return unless f.is_a?(Pdfbox::Cos::Array) && f.size >= 2
      font_ref = f[0]
      font_ref = font_ref.object if font_ref.is_a?(Pdfbox::Cos::Object)
      size = f[1]
      size = size.object if size.is_a?(Pdfbox::Cos::Object)
      return unless font_ref.is_a?(Pdfbox::Cos::Dictionary) && size.is_a?(Pdfbox::Cos::Number)
      font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(font_ref)
      return unless font
      FontSetting.new(font, size.value.to_f32)
    end

    private def dict_get_bool(name : String, default : Bool) : Bool
      v = @dict[Pdfbox::Cos::Name.new(name)]
      v = v.object if v.is_a?(Pdfbox::Cos::Object)
      return default unless v.is_a?(Pdfbox::Cos::Boolean)
      v.value
    end

    private def get_float_item(name : String) : Float32?
      v = @dict[Pdfbox::Cos::Name.new(name)]
      v = v.object if v.is_a?(Pdfbox::Cos::Object)
      return unless v.is_a?(Pdfbox::Cos::Number)
      v.value.to_f32
    end

    struct FontSetting
      getter font : Pdfbox::Pdmodel::Font::PDFont
      getter font_size : Float32

      def initialize(@font : Pdfbox::Pdmodel::Font::PDFont, @font_size : Float32)
      end
    end
  end
end

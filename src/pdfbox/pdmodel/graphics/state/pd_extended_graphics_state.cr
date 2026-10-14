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
          gs.line_width = default_if_null(line_width, 1.0_f32)
        when "LC"
          gs.line_cap = line_cap_style
        when "LJ"
          gs.line_join = line_join_style
        when "ML"
          gs.miter_limit = default_if_null(miter_limit, 10.0_f32)
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
          gs.flatness = default_if_null(flatness_tolerance, 1.0_f32).to_f64
        when "SM"
          gs.smoothness = default_if_null(smoothness_tolerance, 0.0_f32).to_f64
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
        when "SMask"
          mask = soft_mask
          if mask
            # Soft mask must know the CTM at the time the ExtGState was activated.
            mask.initial_transformation_matrix = gs.current_transformation_matrix.clone
          end
          gs.soft_mask = mask
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
      dash = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("D")).as?(Pdfbox::Cos::Array)
      return unless dash && dash.size == 2

      dash_array = dash[0]
      dash_array = dash_array.object if dash_array.is_a?(Pdfbox::Cos::Object)
      phase_item = dash[1]
      phase_item = phase_item.object if phase_item.is_a?(Pdfbox::Cos::Object)
      return unless dash_array.is_a?(Pdfbox::Cos::Array) && phase_item.is_a?(Pdfbox::Cos::Number)

      PDLineDashPattern.new(dash_array, phase_item.value.to_i32)
    end

    # Sets the dash pattern (/D). Java PDExtendedGraphicsState#setLineDashPattern.
    def line_dash_pattern=(dash_pattern : PDLineDashPattern) : PDLineDashPattern
      @dict[Pdfbox::Cos::Name.new("D")] = dash_pattern.cos_object
      dash_pattern
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
      dict_get_bool("op", stroking_overprint_control)
    end

    def flatness_tolerance : Float32?
      get_float_item("FL")
    end

    def smoothness_tolerance : Float32?
      get_float_item("SM")
    end

    def automatic_stroke_adjustment : Bool
      dict_get_bool("SA", false)
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
      sm = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("SMask"))
      sm ? PDSoftMask.create(sm) : nil
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

    def font_setting : Pdfbox::Pdmodel::Graphics::PDFontSetting?
      font = @dict.get_array(Pdfbox::Cos::Name.new("Font"))
      font ? Pdfbox::Pdmodel::Graphics::PDFontSetting.new(font) : nil
    end

    def font_setting=(font_setting : Pdfbox::Pdmodel::Graphics::PDFontSetting?) : Nil
      key = Pdfbox::Cos::Name.new("Font")
      if font_setting
        @dict[key] = font_setting.cos_object
      else
        @dict.delete(key)
      end
    end

    # --- Setters (Java PDExtendedGraphicsState) ---

    def line_width=(width : Float32?) : Float32?
      set_float_item("LW", width)
      width
    end

    def line_cap_style=(style : Int32) : Int32
      @dict.set_int(Pdfbox::Cos::Name.new("LC"), style)
      style
    end

    def line_join_style=(style : Int32) : Int32
      @dict.set_int(Pdfbox::Cos::Name.new("LJ"), style)
      style
    end

    def miter_limit=(miter_limit : Float32?) : Float32?
      set_float_item("ML", miter_limit)
      miter_limit
    end

    def flatness_tolerance=(flatness : Float32?) : Float32?
      set_float_item("FL", flatness)
      flatness
    end

    def smoothness_tolerance=(smoothness : Float32?) : Float32?
      set_float_item("SM", smoothness)
      smoothness
    end

    def overprint_mode=(mode : Int32?) : Int32?
      key = Pdfbox::Cos::Name.new("OPM")
      if mode
        @dict.set_int(key, mode)
      else
        @dict.delete(key)
      end
      mode
    end

    def stroking_overprint_control=(op : Bool) : Bool
      @dict.set_boolean(Pdfbox::Cos::Name.new("OP"), op)
      op
    end

    def non_stroking_overprint_control=(op : Bool) : Bool
      @dict.set_boolean(Pdfbox::Cos::Name.new("op"), op)
      op
    end

    def automatic_stroke_adjustment=(sa : Bool) : Bool
      @dict.set_boolean(Pdfbox::Cos::Name.new("SA"), sa)
      sa
    end

    def text_knockout_flag=(tk : Bool) : Bool
      @dict.set_boolean(Pdfbox::Cos::Name.new("TK"), tk)
      tk
    end

    # Java PDExtendedGraphicsState#setRenderingIntent(String).
    def rendering_intent=(ri : String) : String
      @dict.set_name(Pdfbox::Cos::Name.new("RI"), ri)
      ri
    end

    # The transfer function (/TR), or nil. Java getTransfer.
    def transfer : Pdfbox::Cos::Base?
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("TR"))
      return nil if value.is_a?(Pdfbox::Cos::Array) && value.size != 4
      value
    end

    # Java PDExtendedGraphicsState#setTransfer.
    def transfer=(value : Pdfbox::Cos::Base?) : Pdfbox::Cos::Base?
      key = Pdfbox::Cos::Name.new("TR")
      if value
        @dict[key] = value
      else
        @dict.delete(key)
      end
      value
    end

    # The second transfer function (/TR2), or nil. Java getTransfer2.
    def transfer2 : Pdfbox::Cos::Base?
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("TR2"))
      return nil if value.is_a?(Pdfbox::Cos::Array) && value.size != 4
      value
    end

    # Java PDExtendedGraphicsState#setTransfer2.
    def transfer2=(value : Pdfbox::Cos::Base?) : Pdfbox::Cos::Base?
      key = Pdfbox::Cos::Name.new("TR2")
      if value
        @dict[key] = value
      else
        @dict.delete(key)
      end
      value
    end

    # Returns the default when the "standard" value is nil. Java defaultIfNull.
    private def default_if_null(standard_value : Float32?, default_value : Float32) : Float32
      standard_value.nil? ? default_value : standard_value
    end

    # Java PDExtendedGraphicsState#setFloatItem.
    private def set_float_item(name : String, value : Float32?) : Nil
      key = Pdfbox::Cos::Name.new(name)
      if value
        @dict.set_float(key, value.to_f64)
      else
        @dict.delete(key)
      end
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
  end
end

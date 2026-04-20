module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationLine < PDAnnotationMarkup
    include AppearanceHandlerSupport

    IT_LINE_ARROW     = "LineArrow"
    IT_LINE_DIMENSION = "LineDimension"
    LE_SQUARE         = "Square"
    LE_CIRCLE         = "Circle"
    LE_DIAMOND        = "Diamond"
    LE_OPEN_ARROW     = "OpenArrow"
    LE_CLOSED_ARROW   = "ClosedArrow"
    LE_NONE           = "None"
    LE_BUTT           = "Butt"
    LE_R_OPEN_ARROW   = "ROpenArrow"
    LE_R_CLOSED_ARROW = "RClosedArrow"
    LE_SLASH          = "Slash"
    SUB_TYPE          = "Line"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
      self.line = [0.0, 0.0, 0.0, 0.0] if cos_object[Cos::Name.new("L")]?.nil?
    end

    def line : Array(Float64)?
      cos_object.get_array(Cos::Name.new("L")).try(&.to_float_array)
    end

    def line=(value : Enumerable(Number)) : Array(Float64)
      float_values = value.map(&.to_f64).to_a
      cos_object[Cos::Name.new("L")] = cos_array_of_numbers(float_values)
      float_values
    end

    def start_point_ending_style : String
      ending_style_at(0)
    end

    def start_point_ending_style=(value : String?) : String
      set_line_ending_style(0, value || LE_NONE)
    end

    def end_point_ending_style : String
      ending_style_at(1)
    end

    def end_point_ending_style=(value : String?) : String
      set_line_ending_style(1, value || LE_NONE)
    end

    def interior_color : Graphics::Color::PDColor?
      color_for(Cos::Name.new("IC"))
    end

    def interior_color=(value : Graphics::Color::PDColor) : Graphics::Color::PDColor
      cos_object[Cos::Name.new("IC")] = value.to_cos_array
      value
    end

    def caption? : Bool
      boolean_value(Cos::Name.new("Cap"), false)
    end

    def caption=(value : Bool) : Bool
      cos_object.set_boolean(Cos::Name.new("Cap"), value)
      value
    end

    def leader_line_length : Float64
      cos_object.get_float(Cos::Name.new("LL"), 0.0_f64)
    end

    def leader_line_length=(value : Number) : Float64
      set_float(Cos::Name.new("LL"), value)
    end

    def leader_line_extension_length : Float64
      cos_object.get_float(Cos::Name.new("LLE"), 0.0_f64)
    end

    def leader_line_extension_length=(value : Number) : Float64
      set_float(Cos::Name.new("LLE"), value)
    end

    def leader_line_offset_length : Float64
      cos_object.get_float(Cos::Name.new("LLO"), 0.0_f64)
    end

    def leader_line_offset_length=(value : Number) : Float64
      set_float(Cos::Name.new("LLO"), value)
    end

    def caption_positioning : String?
      cos_object.get_name_as_string(Cos::Name.new("CP"))
    end

    def caption_positioning=(value : String) : String
      cos_object.set_name(Cos::Name.new("CP"), value)
      value
    end

    def caption_horizontal_offset : Float64
      caption_offset_at(0)
    end

    def caption_horizontal_offset=(value : Number) : Float64
      set_caption_offset(0, value.to_f64)
    end

    def caption_vertical_offset : Float64
      caption_offset_at(1)
    end

    def caption_vertical_offset=(value : Number) : Float64
      set_caption_offset(1, value.to_f64)
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDLineAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end

    private def ending_style_at(index : Int32) : String
      array = cos_object.get_array(Cos::Name.new("LE"))
      return LE_NONE unless array && array.size >= 2
      array.get_name(index, LE_NONE) || LE_NONE
    end

    private def set_line_ending_style(index : Int32, value : String) : String
      array = cos_object.get_array(Cos::Name.new("LE")) || Cos::Array.new
      array.grow_to_size(2, Cos::Name.new(LE_NONE))
      array.set_name(index, value)
      cos_object[Cos::Name.new("LE")] = array
      value
    end

    private def caption_offset_at(index : Int32) : Float64
      array = cos_object.get_array(Cos::Name.new("CO"))
      return 0.0_f64 unless array
      array.to_float_array[index]? || 0.0_f64
    end

    private def set_caption_offset(index : Int32, value : Float64) : Float64
      array = cos_object.get_array(Cos::Name.new("CO")) || cos_array_of_numbers([0.0, 0.0])
      array.grow_to_size(2, Cos::Float::ZERO)
      array[index] = Cos::Float.new(value)
      cos_object[Cos::Name.new("CO")] = array
      value
    end

    private def set_float(key : Cos::Name, value : Number) : Float64
      float_value = value.to_f64
      cos_object.set_float(key, float_value)
      float_value
    end
  end
end

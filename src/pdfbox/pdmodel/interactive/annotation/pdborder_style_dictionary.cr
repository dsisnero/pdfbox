module Pdfbox::Pdmodel::Interactive::Annotation
  class PDBorderStyleDictionary
    STYLE_SOLID     = "S"
    STYLE_DASHED    = "D"
    STYLE_BEVELED   = "B"
    STYLE_INSET     = "I"
    STYLE_UNDERLINE = "U"

    @dictionary : Cos::Dictionary

    def initialize(@dictionary : Cos::Dictionary = Cos::Dictionary.new)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    def width : Float64
      return 0.0_f64 if @dictionary[Cos::Name::W]?.is_a?(Cos::Name)
      @dictionary.get_float(Cos::Name::W, 1.0_f64)
    end

    def width=(value : Number) : Float64
      float_value = value.to_f64
      if float_value == float_value.to_i.to_f64
        @dictionary.set_int(Cos::Name::W, float_value.to_i)
      else
        @dictionary.set_float(Cos::Name::W, float_value)
      end
      float_value
    end

    def style : String
      @dictionary.get_name_as_string(Cos::Name::S) || STYLE_SOLID
    end

    def style=(value : String) : String
      @dictionary.set_name(Cos::Name::S, value)
      value
    end

    def dash_style : Graphics::PDLineDashPattern
      dash_array = @dictionary.get_array(Cos::Name.new("D"))
      unless dash_array
        dash_array = Cos::Array.new
        dash_array.add(Cos::Integer::THREE)
        @dictionary[Cos::Name.new("D")] = dash_array
      end
      Graphics::PDLineDashPattern.new(dash_array, 0)
    end

    def dash_style=(value : Cos::Array) : Cos::Array
      @dictionary[Cos::Name.new("D")] = value
      value
    end
  end
end

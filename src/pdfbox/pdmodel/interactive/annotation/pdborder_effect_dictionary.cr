module Pdfbox::Pdmodel::Interactive::Annotation
  class PDBorderEffectDictionary
    STYLE_SOLID  = "S"
    STYLE_CLOUDY = "C"

    @dictionary : Cos::Dictionary

    def initialize(@dictionary : Cos::Dictionary = Cos::Dictionary.new)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    def intensity : Float64
      @dictionary.get_float(Cos::Name.new("I"), 0.0_f64)
    end

    def intensity=(value : Number) : Float64
      float_value = value.to_f64
      @dictionary.set_float(Cos::Name.new("I"), float_value)
      float_value
    end

    def style : String
      @dictionary.get_name_as_string(Cos::Name::S) || STYLE_SOLID
    end

    def style=(value : String) : String
      @dictionary.set_name(Cos::Name::S, value)
      value
    end
  end
end

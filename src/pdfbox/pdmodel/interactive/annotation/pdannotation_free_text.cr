module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationFreeText < PDAnnotationMarkup
    include AppearanceHandlerSupport

    SUB_TYPE                 = "FreeText"
    IT_FREE_TEXT             = "FreeText"
    IT_FREE_TEXT_CALLOUT     = "FreeTextCallout"
    IT_FREE_TEXT_TYPE_WRITER = "FreeTextTypeWriter"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def default_appearance : String?
      cos_object.get_string(Cos::Name.new("DA"))
    end

    def default_appearance=(value : String) : String
      cos_object.set_string(Cos::Name.new("DA"), value)
      value
    end

    def default_style_string : String?
      cos_object.get_string(Cos::Name.new("DS"))
    end

    def default_style_string=(value : String) : String
      cos_object.set_string(Cos::Name.new("DS"), value)
      value
    end

    def q : Int32
      cos_object.get_int(Cos::Name.new("Q"), 0_i64).to_i32
    end

    def q=(value : Int) : Int32
      int_value = value.to_i32
      cos_object.set_int(Cos::Name.new("Q"), int_value)
      int_value
    end

    def rect_differences=(values : Enumerable(Number)) : Array(Float64)
      float_values = values.map(&.to_f64).to_a
      raise ArgumentError.new("rect_differences must contain exactly four numbers") unless float_values.size == 4

      values = float_values
      cos_object[Cos::Name.new("RD")] = cos_array_of_numbers(values)
      values
    end

    def rect_differences : Array(Float64)
      cos_object.get_array(Cos::Name.new("RD")).try(&.to_float_array) || [] of Float64
    end

    def callout : Array(Float64)?
      cos_object.get_array(Cos::Name.new("CL")).try(&.to_float_array)
    end

    def callout=(value : Enumerable(Number)) : Array(Float64)
      float_values = value.map(&.to_f64).to_a
      cos_object[Cos::Name.new("CL")] = cos_array_of_numbers(float_values)
      float_values
    end

    def line_ending_style : String
      cos_object.get_name_as_string(Cos::Name.new("LE")) || PDAnnotationLine::LE_NONE
    end

    def line_ending_style=(value : String) : String
      cos_object.set_name(Cos::Name.new("LE"), value)
      value
    end

    def border_effect : PDBorderEffectDictionary?
      cos_object.get_dictionary(Cos::Name.new("BE")).try { |entry| PDBorderEffectDictionary.new(entry) }
    end

    def border_effect=(value : PDBorderEffectDictionary) : PDBorderEffectDictionary
      cos_object[Cos::Name.new("BE")] = value.cos_object
      value
    end

    def rect_difference : Common::PDRectangle?
      cos_object.get_array(Cos::Name.new("RD")).try { |entry| Common::PDRectangle.new(entry) }
    end

    def rect_difference=(value : Common::PDRectangle) : Common::PDRectangle
      cos_object[Cos::Name.new("RD")] = value.cos_object
      value
    end
  end
end

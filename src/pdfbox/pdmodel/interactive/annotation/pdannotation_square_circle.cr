module Pdfbox::Pdmodel::Interactive::Annotation
  abstract class PDAnnotationSquareCircle < PDAnnotationMarkup
    include AppearanceHandlerSupport

    protected def initialize(subtype_name : String)
      super()
      self.subtype = subtype_name
    end

    protected def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def interior_color : Graphics::Color::PDColor?
      color_for(Cos::Name.new("IC"))
    end

    def interior_color=(value : Graphics::Color::PDColor) : Graphics::Color::PDColor
      cos_object[Cos::Name.new("IC")] = value.to_cos_array
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
  end
end

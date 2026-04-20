module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationPolygon < PDAnnotationMarkup
    include AppearanceHandlerSupport

    SUB_TYPE = "Polygon"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
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

    def vertices : Array(Float64)?
      cos_object.get_array(Cos::Name.new("Vertices")).try(&.to_float_array)
    end

    def vertices=(value : Enumerable(Number)) : Array(Float64)
      float_values = value.map(&.to_f64).to_a
      cos_object[Cos::Name.new("Vertices")] = cos_array_of_numbers(float_values)
      float_values
    end

    def path : Array(Array(Float64))?
      cos_object.get_array(Cos::Name.new("Path")).try do |array|
        array.items.map do |item|
          item.as?(Cos::Array).try(&.to_float_array) || [] of Float64
        end
      end
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDPolygonAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end

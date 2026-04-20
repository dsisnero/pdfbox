module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationInk < PDAnnotationMarkup
    include AppearanceHandlerSupport

    SUB_TYPE = "Ink"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def ink_list : Array(Array(Float64))
      array = cos_object.get_array(Cos::Name.new("InkList"))
      return [] of Array(Float64) unless array

      array.items.map do |item|
        item.as?(Cos::Array).try(&.to_float_array) || [] of Float64
      end
    end

    def ink_list=(value : Enumerable(Enumerable(Number))) : Array(Array(Float64))
      float_values = value.map(&.map(&.to_f64).to_a).to_a
      outer = Cos::Array.new
      float_values.each do |path|
        outer.add(cos_array_of_numbers(path))
      end
      cos_object[Cos::Name.new("InkList")] = outer
      float_values
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDInkAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end

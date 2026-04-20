module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationCaret < PDAnnotationMarkup
    include AppearanceHandlerSupport

    SUB_TYPE = "Caret"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
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

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDCaretAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end

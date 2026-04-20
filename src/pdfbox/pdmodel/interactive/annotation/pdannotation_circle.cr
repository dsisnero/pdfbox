# A circle annotation
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationCircle < PDAnnotationSquareCircle
    SUB_TYPE = "Circle"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE if subtype.nil?
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDCircleAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end

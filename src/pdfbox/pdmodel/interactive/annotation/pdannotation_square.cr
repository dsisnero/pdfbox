# A square annotation
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationSquare < PDAnnotationSquareCircle
    SUB_TYPE = "Square"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE if subtype.nil?
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDSquareAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end

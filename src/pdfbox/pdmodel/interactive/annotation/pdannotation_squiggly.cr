module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationSquiggly < PDAnnotationTextMarkup
    SUB_TYPE = "Squiggly"

    def initialize
      super(SUB_TYPE)
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDSquigglyAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end

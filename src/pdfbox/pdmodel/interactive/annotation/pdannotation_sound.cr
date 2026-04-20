module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationSound < PDAnnotationMarkup
    include AppearanceHandlerSupport

    SUB_TYPE = "Sound"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end
  end
end

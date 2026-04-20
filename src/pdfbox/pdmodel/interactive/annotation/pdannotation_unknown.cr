module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationUnknown < PDAnnotation
    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
    end
  end
end

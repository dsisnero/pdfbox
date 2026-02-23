# A circle annotation
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationCircle < PDAnnotation
    SUB_TYPE = "Circle"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      @dictionary[Cos::Name.new("Subtype")] = Cos::Name.new(SUB_TYPE)
    end

    def subtype : String
      SUB_TYPE
    end
  end
end

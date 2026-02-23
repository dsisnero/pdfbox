# A link annotation
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationLink < PDAnnotation
    SUB_TYPE = "Link"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      @dictionary[Cos::Name.new("Subtype")] = Cos::Name.new(SUB_TYPE)
    end

    def subtype : String
      SUB_TYPE
    end
  end
end

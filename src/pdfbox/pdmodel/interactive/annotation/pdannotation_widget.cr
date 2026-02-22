# A widget annotation that is used for form fields
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationWidget < PDAnnotation
    SUB_TYPE = "Widget"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      @dictionary[Cos::Name.new("Subtype")] = Cos::Name.new(SUB_TYPE)
    end

    def subtype : String
      SUB_TYPE
    end

    # Get the field name (T entry)
    def field_name : String?
      @dictionary[Cos::Name.new("T")].as?(Cos::String).try(&.value)
    end

    # Set the field name
    def field_name=(name : String)
      @dictionary[Cos::Name.new("T")] = Cos::String.new(name)
    end

    # Get the page reference
    def page : Cos::Base?
      @dictionary[Cos::Name.new("P")]
    end

    # Set the page reference
    def page=(page : Cos::Base)
      @dictionary[Cos::Name.new("P")] = page
    end
  end
end

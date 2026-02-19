module Pdfbox::Pdmodel::Graphics::OptionalContent
  class PDOptionalContentGroup
    TYPE = "OCG"

    @dict : Pdfbox::Cos::Dictionary

    def initialize(name : String)
      @dict = Pdfbox::Cos::Dictionary.new
      @dict.set_name("Type", TYPE)
      self.name = name
    end

    def initialize(@dict : Pdfbox::Cos::Dictionary)
      type = @dict[Pdfbox::Cos::Name.new("Type")]
      type_name = type.as?(Pdfbox::Cos::Name).try(&.value)
      if type_name != TYPE
        raise ArgumentError.new("Provided dictionary is not of type '/#{TYPE}'")
      end
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dict
    end

    def name : String?
      value = @dict[Pdfbox::Cos::Name.new("Name")]
      value.as?(Pdfbox::Cos::String).try(&.value)
    end

    def name=(name : String) : String
      @dict.set_string("Name", name)
      name
    end
  end
end

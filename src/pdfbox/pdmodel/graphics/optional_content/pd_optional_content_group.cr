require "../../document_interchange/marked_content/pd_property_list"

module Pdfbox::Pdmodel::Graphics::OptionalContent
  # Optional content group (Java PDOptionalContentGroup extends PDPropertyList).
  class PDOptionalContentGroup < Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList
    TYPE = "OCG"

    def initialize(name : String)
      super(Pdfbox::Cos::Dictionary.new)
      @dict.set_name("Type", TYPE)
      self.name = name
    end

    def initialize(dict : Pdfbox::Cos::Dictionary)
      type = dict[Pdfbox::Cos::Name.new("Type")]
      type_name = type.as?(Pdfbox::Cos::Name).try(&.value)
      if type_name != TYPE
        raise ArgumentError.new("Provided dictionary is not of type '/#{TYPE}'")
      end
      super(dict)
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

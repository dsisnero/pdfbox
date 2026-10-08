module Pdfbox::Pdmodel::DocumentInterchange::MarkedContent
  class PDPropertyList
    @dict : Pdfbox::Cos::Dictionary

    # Java PDPropertyList#create: dispatch on /Type (OCG -> PDOptionalContentGroup).
    def self.create(dict : Pdfbox::Cos::Dictionary) : PDPropertyList
      type = dict[Pdfbox::Cos::Name.new("Type")]?
      type = type.object if type.is_a?(Pdfbox::Cos::Object)
      if type.is_a?(Pdfbox::Cos::Name) && type.value == "OCG"
        Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new(dict)
      else
        new(dict)
      end
    end

    protected def initialize
      @dict = Pdfbox::Cos::Dictionary.new
    end

    def initialize(@dict : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dict
    end
  end
end

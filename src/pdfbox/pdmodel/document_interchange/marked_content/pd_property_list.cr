module Pdfbox::Pdmodel::DocumentInterchange::MarkedContent
  class PDPropertyList
    @dict : Pdfbox::Cos::Dictionary

    # Java PDPropertyList#create: dispatch on /Type (OCG -> PDOptionalContentGroup,
    # OCMD -> PDOptionalContentMembershipDictionary).
    def self.create(dict : Cos::Dictionary) : PDPropertyList
      type = dict[Cos::Name.new("Type")]?
      type = type.object if type.is_a?(Cos::Object)
      if type.is_a?(Cos::Name)
        case type.value
        when "OCG"
          Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new(dict)
        when "OCMD"
          Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentMembershipDictionary.new(dict)
        else
          new(dict)
        end
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

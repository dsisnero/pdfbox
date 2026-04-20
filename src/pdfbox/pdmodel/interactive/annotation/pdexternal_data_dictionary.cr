module Pdfbox::Pdmodel::Interactive::Annotation
  class PDExternalDataDictionary
    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
      @dictionary.set_name(Cos::Name::TYPE, "ExData")
    end

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    def type : String
      @dictionary.get_name_as_string(Cos::Name::TYPE) || "ExData"
    end

    def subtype : String?
      @dictionary.get_name_as_string(Cos::Name::SUBTYPE)
    end

    def subtype=(value : String) : String
      @dictionary.set_name(Cos::Name::SUBTYPE, value)
      value
    end
  end
end

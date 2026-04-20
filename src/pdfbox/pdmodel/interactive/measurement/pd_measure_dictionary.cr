module Pdfbox::Pdmodel::Interactive::Measurement
  class PDMeasureDictionary
    TYPE = "Measure"

    @measure_dictionary : Cos::Dictionary

    def initialize
      @measure_dictionary = Cos::Dictionary.new
      @measure_dictionary.set_name(Cos::Name::TYPE, TYPE)
    end

    def initialize(@measure_dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @measure_dictionary
    end

    def type : String
      TYPE
    end

    def subtype : String
      @measure_dictionary.get_name_as_string(Cos::Name::SUBTYPE) || PDRectlinearMeasureDictionary::SUBTYPE
    end

    protected def subtype=(value : String) : String
      @measure_dictionary.set_name(Cos::Name::SUBTYPE, value)
      value
    end
  end
end

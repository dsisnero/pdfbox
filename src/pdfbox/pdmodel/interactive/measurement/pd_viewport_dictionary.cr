module Pdfbox::Pdmodel::Interactive::Measurement
  class PDViewportDictionary
    TYPE = "Viewport"

    @viewport_dictionary : Cos::Dictionary

    def initialize
      @viewport_dictionary = Cos::Dictionary.new
    end

    def initialize(@viewport_dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @viewport_dictionary
    end

    def type : String
      TYPE
    end

    def bbox : Pdfbox::Pdmodel::Common::PDRectangle?
      @viewport_dictionary.get_array(Cos::Name.new("BBox")).try do |array|
        Pdfbox::Pdmodel::Common::PDRectangle.new(array)
      end
    end

    def bbox=(rectangle : Pdfbox::Pdmodel::Common::PDRectangle) : Pdfbox::Pdmodel::Common::PDRectangle
      @viewport_dictionary[Cos::Name.new("BBox")] = rectangle.cos_object
      rectangle
    end

    def name : String?
      @viewport_dictionary.get_name_as_string(Cos::Name::NAME)
    end

    def name=(value : String) : String
      @viewport_dictionary.set_name(Cos::Name::NAME, value)
      value
    end

    def measure : PDMeasureDictionary?
      @viewport_dictionary.get_dictionary(Cos::Name.new("Measure")).try do |dictionary|
        PDMeasureDictionary.new(dictionary)
      end
    end

    def measure=(value : PDMeasureDictionary) : PDMeasureDictionary
      @viewport_dictionary[Cos::Name.new("Measure")] = value.cos_object
      value
    end
  end
end

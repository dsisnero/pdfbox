# A wrapper for a COS dictionary including Type information
module Pdfbox::Pdmodel::Common
  class PDTypedDictionaryWrapper < PDDictionaryWrapper
    # Creates a new instance with a given type
    def initialize(type : ::String)
      super()
      cos_object[Cos::Name::TYPE] = Cos::Name.new(type)
    end

    # Creates a new instance with a given COS dictionary
    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    # Gets the type
    def type : String?
      cos_object[Cos::Name::TYPE].as?(Cos::Name).try(&.value)
    end

    # There is no set_type method because changing the Type would most
    # probably also change the type of PD object
  end
end

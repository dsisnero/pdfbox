# A wrapper for a COS dictionary
module Pdfbox::Pdmodel::Common
  class PDDictionaryWrapper
    @dictionary : Cos::Dictionary

    # Default constructor
    def initialize
      @dictionary = Cos::Dictionary.new
    end

    # Creates a new instance with a given COS dictionary
    def initialize(@dictionary : Cos::Dictionary)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @dictionary
    end

    def ==(other : PDDictionaryWrapper) : Bool
      @dictionary == other.@dictionary
    end

    def ==(other) : Bool
      false
    end

    def_hash @dictionary
  end
end

module Pdfbox::Pdmodel::Interactive::Action
  class PDURIDictionary
    @uri_dictionary : Cos::Dictionary

    def initialize
      @uri_dictionary = Cos::Dictionary.new
    end

    def initialize(@uri_dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @uri_dictionary
    end

    def base : String?
      @uri_dictionary.get_string(Cos::Name.new("Base"))
    end

    def base=(value : String) : String
      @uri_dictionary.set_string("Base", value)
      value
    end
  end
end

# Placeholder for PDActionJavaScript
module Pdfbox::Pdmodel::Interactive::Action
  class PDActionJavaScript
    @dict : Cos::Dictionary

    def initialize
      @dict = Cos::Dictionary.new
      @dict[Cos::Name::TYPE] = Cos::Name::ACTION
      @dict[Cos::Name::SUBTYPE] = Cos::Name.new("JavaScript")
    end

    def initialize(dict : Cos::Dictionary)
      @dict = dict
    end

    def cos_object : Cos::Dictionary
      @dict
    end
  end
end
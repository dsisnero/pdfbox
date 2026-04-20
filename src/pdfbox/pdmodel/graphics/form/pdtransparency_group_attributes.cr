module Pdfbox::Pdmodel::Graphics::Form
  class PDTransparencyGroupAttributes
    include Pdfbox::Pdmodel::Common::COSObjectable

    @dictionary : Pdfbox::Cos::Dictionary

    def initialize
      @dictionary = Pdfbox::Cos::Dictionary.new
      @dictionary.set_name(Pdfbox::Cos::Name::S, "Transparency")
    end

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Base
      @dictionary
    end

    def isolated? : Bool
      @dictionary.get_bool(Pdfbox::Cos::Name.new("I"), false)
    end

    def knockout? : Bool
      @dictionary.get_bool(Pdfbox::Cos::Name.new("K"), false)
    end
  end
end

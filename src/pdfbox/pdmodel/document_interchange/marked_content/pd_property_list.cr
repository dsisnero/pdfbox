module Pdfbox::Pdmodel::DocumentInterchange::MarkedContent
  class PDPropertyList
    @dict : Pdfbox::Cos::Dictionary

    def self.create(dict : Pdfbox::Cos::Dictionary) : self
      new(dict)
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

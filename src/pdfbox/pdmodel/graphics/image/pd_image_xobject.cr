module Pdfbox::Pdmodel::Graphics::Image
  class PDImageXObject
    include Pdfbox::Pdmodel::Common::COSObjectable

    def initialize(_document : Pdfbox::Pdmodel::Document)
      @dict = Pdfbox::Cos::Dictionary.new
      @dict[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("XObject")
      @dict[Pdfbox::Cos::Name.new("Subtype")] = Pdfbox::Cos::Name.new("Image")
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end
  end
end

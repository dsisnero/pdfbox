module Pdfbox::Pdmodel::Graphics::Shading
  class PDShadingType1
    include Pdfbox::Pdmodel::Common::COSObjectable

    def initialize(@dict : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end
  end
end

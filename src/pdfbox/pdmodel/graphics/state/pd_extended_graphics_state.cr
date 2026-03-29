module Pdfbox::Pdmodel::Graphics::State
  class PDExtendedGraphicsState
    include Pdfbox::Pdmodel::Common::COSObjectable

    def initialize(@dict : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end
  end
end

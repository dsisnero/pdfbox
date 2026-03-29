module Pdfbox::Pdmodel::Graphics::Image
  class PDInlineImage
    def initialize(@parameters : Pdfbox::Cos::Dictionary, @data : Bytes, @resources : Pdfbox::Pdmodel::PDResources)
    end
  end
end

# The result of a filter decode operation. Allows information such as color
# space to be extracted from image streams, and for stream parameters to be
# repaired during reading.
# Java: org.apache.pdfbox.filter.DecodeResult
module Pdfbox::Filter
  class DecodeResult
    getter parameters : Pdfbox::Cos::Dictionary
    getter jpx_color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace?

    def initialize(parameters : Pdfbox::Cos::Dictionary)
      @parameters = parameters
      @jpx_color_space = nil
    end

    def initialize(parameters : Pdfbox::Cos::Dictionary, color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace)
      @parameters = parameters
      @jpx_color_space = color_space
    end

    # Return a default DecodeResult.
    def self.create_default : DecodeResult
      new(Pdfbox::Cos::Dictionary.new)
    end

    # Sets the JPX color space.
    def color_space=(color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace)
      @jpx_color_space = color_space
    end
  end
end

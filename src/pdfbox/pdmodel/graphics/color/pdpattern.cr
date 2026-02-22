# Pattern color space
module Pdfbox::Pdmodel::Graphics::Color
  class PDPattern < PDColorSpace
    @underlying_color_space : PDColorSpace?

    def initialize(@underlying_color_space : PDColorSpace? = nil)
    end

    # Returns the underlying color space for uncolored tiling patterns
    def underlying_color_space : PDColorSpace?
      @underlying_color_space
    end

    def number_of_components : Int32
      @underlying_color_space.try(&.number_of_components) || 0
    end

    def to_rgb(components : Array(Float32)) : Array(Float32)
      # Pattern colors cannot be directly converted to RGB
      [0.0_f32, 0.0_f32, 0.0_f32]
    end
  end
end

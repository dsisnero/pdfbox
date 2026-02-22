# DeviceCMYK color space - subtractive CMYK (cyan, magenta, yellow, black) model
module Pdfbox::Pdmodel::Graphics::Color
  class PDDeviceCMYK < PDDeviceColorSpace
    # Single instance of this class (singleton pattern)
    INSTANCE = new

    private def initialize
    end

    def name : String
      "DeviceCMYK"
    end

    def number_of_components : Int32
      4
    end

    def initial_color : PDColor
      @initial_color ||= PDColor.new([0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32], self)
    end

    def to_rgb(components : Array(Float32)) : Array(Float32)
      # Basic CMYK to RGB conversion
      # RGB = (1-C) * (1-K), (1-M) * (1-K), (1-Y) * (1-K)
      c = components[0]
      m = components[1]
      y = components[2]
      k = components[3]

      r = (1.0_f32 - c) * (1.0_f32 - k)
      g = (1.0_f32 - m) * (1.0_f32 - k)
      b = (1.0_f32 - y) * (1.0_f32 - k)

      [r, g, b]
    end
  end
end

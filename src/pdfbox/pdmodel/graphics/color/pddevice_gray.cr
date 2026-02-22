# DeviceGray color space - black, white, and intermediate shades of gray
module Pdfbox::Pdmodel::Graphics::Color
  class PDDeviceGray < PDDeviceColorSpace
    # Single instance of this class (singleton pattern)
    INSTANCE = new

    private def initialize
    end

    def name : String
      "DeviceGray"
    end

    def number_of_components : Int32
      1
    end

    def initial_color : PDColor
      @initial_color ||= PDColor.new([0.0_f32], self)
    end

    def to_rgb(components : Array(Float32)) : Array(Float32)
      # Gray to RGB conversion
      gray = components[0]
      [gray, gray, gray]
    end
  end
end

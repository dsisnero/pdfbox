# DeviceRGB colour space - additive RGB (red-green-blue) colour model
module Pdfbox::Pdmodel::Graphics::Color
  class PDDeviceRGB < PDDeviceColorSpace
    # Single instance of this class (singleton pattern)
    INSTANCE = new

    private def initialize
    end

    def name : String
      "DeviceRGB"
    end

    def number_of_components : Int32
      3
    end

    def initial_color : PDColor
      @initial_color ||= PDColor.new([0.0_f32, 0.0_f32, 0.0_f32], self)
    end

    def to_rgb(components : Array(Float32)) : Array(Float32)
      # RGB is already RGB, just return the components
      components
    end
  end
end

# Device colour spaces directly specify colours or shades of gray produced by an output device
module Pdfbox::Pdmodel::Graphics::Color
  abstract class PDDeviceColorSpace < PDColorSpace
    def to_s : String
      name
    end

    def cos_object : Cos::Base
      Cos::Name.new(name)
    end

    # Returns the name of this color space
    abstract def name : String
  end
end

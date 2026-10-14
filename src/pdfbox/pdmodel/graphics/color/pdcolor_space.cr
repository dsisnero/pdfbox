# Base class for color spaces
module Pdfbox::Pdmodel::Graphics::Color
  abstract class PDColorSpace
    # Returns the number of components in this color space
    abstract def number_of_components : Int32

    # Converts color components to RGB
    abstract def to_rgb(components : Array(Float32)) : Array(Float32)

    # Returns the COS representation of this color space.
    abstract def cos_object : Cos::Base

    # Returns the color space name (Java PDColorSpace#getName).
    abstract def name : String

    # Returns the default decode array for this color space.
    # Java PDColorSpace#getDefaultDecode.
    abstract def default_decode(bits_per_component : Int32) : Array(Float32)

    # Returns the initial color for this color space (all zeros).
    def initial_color : PDColor
      components = Array(Float32).new(number_of_components, 0.0_f32)
      PDColor.new(components, self)
    end

    # Create a color space from a COS name or array.
    def self.create(cos_base : Cos::Base) : PDColorSpace?
      case cos_base
      when Cos::Name
        case cos_base.value
        when "DeviceGray", "G"
          PDDeviceGray::INSTANCE
        when "DeviceRGB", "RGB"
          PDDeviceRGB::INSTANCE
        when "DeviceCMYK", "CMYK"
          PDDeviceCMYK::INSTANCE
        end
      when Cos::Array
        if cos_base.size > 0
          first = cos_base[0]
          first = first.object if first.is_a?(Cos::Object)
          if first.is_a?(Cos::Name)
            case first.value
            when "DeviceGray"
              PDDeviceGray::INSTANCE
            when "DeviceRGB"
              PDDeviceRGB::INSTANCE
            when "DeviceCMYK"
              PDDeviceCMYK::INSTANCE
            when "Lab"
              PDLab.new(cos_base)
            when "ICCBased"
              PDICCBased.new(cos_base)
            when "Indexed"
              PDIndexed.new(cos_base)
            when "CalGray"
              PDCalGray.new(cos_base)
            when "CalRGB"
              PDCalRGB.new(cos_base)
            when "Separation"
              PDSeparation.new(cos_base)
            when "DeviceN"
              PDDeviceN.new(cos_base)
            else
              nil
            end
          end
        end
      end
    end
  end
end

# Rendering intent for color management.
# Port of Apache PDFBox RenderingIntent.
module Pdfbox::Pdmodel::Graphics::State
  enum RenderingIntent
    AbsoluteColorimetric
    RelativeColorimetric
    Saturation
    Perceptual

    # Parse a rendering intent from a PDF name string.
    # Returns RelativeColorimetric if the name is not recognized.
    def self.from_string(value : String) : RenderingIntent
      case value
      when "AbsoluteColorimetric" then AbsoluteColorimetric
      when "RelativeColorimetric" then RelativeColorimetric
      when "Saturation"           then Saturation
      when "Perceptual"           then Perceptual
      else
        # "If a conforming reader does not recognize the specified name,
        # it shall use the RelativeColorimetric intent by default."
        RelativeColorimetric
      end
    end

    # Returns the string value, as used in a PDF file.
    def to_s_value : String
      case self
      when .absolute_colorimetric? then "AbsoluteColorimetric"
      when .relative_colorimetric? then "RelativeColorimetric"
      when .saturation?            then "Saturation"
      when .perceptual?            then "Perceptual"
      else                              "RelativeColorimetric"
      end
    end
  end
end

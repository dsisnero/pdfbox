# Base class for color spaces
module Pdfbox::Pdmodel::Graphics::Color
  abstract class PDColorSpace
    # Returns the number of components in this color space
    abstract def number_of_components : Int32

    # Converts color components to RGB
    abstract def to_rgb(components : Array(Float32)) : Array(Float32)
  end
end

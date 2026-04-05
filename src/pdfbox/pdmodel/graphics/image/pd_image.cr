module Pdfbox::Pdmodel::Graphics::Image
  # An image in a PDF document.
  # Corresponds to org.apache.pdfbox.pdmodel.graphics.image.PDImage in Apache PDFBox
  abstract class PDImage
    include Pdfbox::Pdmodel::Common::COSObjectable

    # Returns true if the image has no data.
    abstract def empty? : Bool

    # Returns true if the image is a stencil mask.
    abstract def stencil? : Bool

    # Sets whether the image is a stencil.
    # This corresponds to the `ImageMask` entry in the image stream's dictionary.
    abstract def stencil=(is_stencil : Bool) : Nil

    # Returns bits per component of this image, or -1 if one has not been set.
    abstract def bits_per_component : Int32

    # Set the number of bits per component.
    abstract def bits_per_component=(bits_per_component : Int32) : Nil

    # Returns the image's color space.
    abstract def color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace

    # Sets the color space for this image.
    abstract def color_space=(color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace) : Nil

    # Returns height of this image, or -1 if one has not been set.
    abstract def height : Int32

    # Sets the height of the image. This is for internal PDFBox usage and not to set the size of
    # the image on the page.
    abstract def height=(height : Int32) : Nil

    # Returns the width of this image, or -1 if one has not been set.
    abstract def width : Int32

    # Sets the width of the image. This is for internal PDFBox usage and not to set the size of
    # the image on the page.
    abstract def width=(width : Int32) : Nil

    # Sets the decode array.
    abstract def decode=(decode : Pdfbox::Cos::Array) : Nil

    # Returns the decode array.
    abstract def decode : Pdfbox::Cos::Array

    # Returns true if the image should be interpolated when rendered.
    abstract def interpolate? : Bool

    # Sets the Interpolate flag, true for high-quality image scaling.
    abstract def interpolate=(value : Bool) : Nil

    # Returns the suffix for this image type, e.g. "jpg"
    abstract def suffix : String

    # Returns an InputStream containing the image data, irrespective of whether this is an
    # inline image or an image XObject.
    abstract def create_input_stream : ::IO

    # Returns an InputStream containing the image data, irrespective of whether this is an
    # inline image or an image XObject. The given filters will not be decoded.
    abstract def create_input_stream(stop_filters : Array(String)) : ::IO

    # TODO: Implement these methods when we have image rendering support
    # abstract def get_image : BufferedImage
    # abstract def get_raw_raster : WritableRaster
    # abstract def get_raw_image : BufferedImage
    # abstract def get_stencil_image(paint : Paint) : BufferedImage
  end
end

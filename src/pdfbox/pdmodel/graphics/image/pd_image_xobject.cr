require "crimage"
require "./pd_image"

module Pdfbox::Pdmodel::Graphics::Image
  class PDImageXObject < PDImage
    @dict : Pdfbox::Cos::Dictionary
    @document : Pdfbox::Pdmodel::Document
    @stream : Pdfbox::Cos::Stream?

    # Creates a PDImageXObject from an image file.
    # JPEG files are embedded directly with DCTDecode filter.
    # Other formats are converted to raw RGB with FlateDecode compression.
    def self.create_from_file(image_path : String, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      ext = File.extname(image_path).downcase
      case ext
      when ".jpg", ".jpeg"
        create_from_jpeg(image_path, document)
      else
        create_from_raster(image_path, document)
      end
    end

    private def self.create_from_jpeg(image_path : String, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      file_data = File.read(image_path)
      image_bytes = file_data.to_slice

      # Read dimensions from the JPEG header using crimage
      config = CrImage.read_config(image_path)
      width = config.width
      height = config.height

      stream = Pdfbox::Cos::Stream.new
      stream.data = image_bytes
      stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("DCTDecode")
      stream[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(width)
      stream[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(height)
      stream[Pdfbox::Cos::Name.new("BitsPerComponent")] = Pdfbox::Cos::Integer.new(8)
      stream[Pdfbox::Cos::Name.new("ColorSpace")] = Pdfbox::Cos::Name.new("DeviceRGB")

      new(document, stream, stream)
    end

    private def self.create_from_raster(image_path : String, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      img = CrImage.read(image_path)
      bounds = img.bounds
      width = bounds.width
      height = bounds.height

      # Extract raw RGB pixel data (top-to-bottom, left-to-right)
      rgb_data = Bytes.new(width * height * 3)
      idx = 0
      bounds.min.y.upto(bounds.max.y - 1) do |y|
        bounds.min.x.upto(bounds.max.x - 1) do |x|
          color = img.at(x, y)
          r, g, b, _a = color.rgba
          rgb_data[idx] = (r >> 8).to_u8
          rgb_data[idx + 1] = (g >> 8).to_u8
          rgb_data[idx + 2] = (b >> 8).to_u8
          idx += 3
        end
      end

      stream = Pdfbox::Cos::Stream.new
      encoded_output = stream.create_output_stream(Pdfbox::Cos::Name.new("FlateDecode"))
      encoded_output.write(rgb_data)
      encoded_output.close

      stream[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(width)
      stream[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(height)
      stream[Pdfbox::Cos::Name.new("BitsPerComponent")] = Pdfbox::Cos::Integer.new(8)
      stream[Pdfbox::Cos::Name.new("ColorSpace")] = Pdfbox::Cos::Name.new("DeviceRGB")

      new(document, stream, stream)
    end

    def initialize(document : Pdfbox::Pdmodel::Document, dict : Pdfbox::Cos::Dictionary? = nil, stream : Pdfbox::Cos::Stream? = nil)
      @document = document
      @dict = dict || Pdfbox::Cos::Dictionary.new
      @stream = stream

      # Ensure required dictionary entries
      unless @dict.has_key?(Pdfbox::Cos::Name.new("Type"))
        @dict[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("XObject")
      end
      unless @dict.has_key?(Pdfbox::Cos::Name.new("Subtype"))
        @dict[Pdfbox::Cos::Name.new("Subtype")] = Pdfbox::Cos::Name.new("Image")
      end
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end

    def empty? : Bool
      # TODO: Implement based on stream data
      false
    end

    def stencil? : Bool
      @dict.has_key?(Pdfbox::Cos::Name.new("ImageMask")) &&
        @dict[Pdfbox::Cos::Name.new("ImageMask")].as(Pdfbox::Cos::Boolean).value
    end

    def stencil=(is_stencil : Bool) : Nil
      @dict[Pdfbox::Cos::Name.new("ImageMask")] = is_stencil ? Pdfbox::Cos::Boolean::TRUE : Pdfbox::Cos::Boolean::FALSE
    end

    def bits_per_component : Int32
      if @dict.has_key?(Pdfbox::Cos::Name.new("BitsPerComponent"))
        @dict[Pdfbox::Cos::Name.new("BitsPerComponent")].as(Pdfbox::Cos::Integer).value.to_i32
      else
        -1
      end
    end

    def bits_per_component=(bits_per_component : Int32) : Nil
      @dict[Pdfbox::Cos::Name.new("BitsPerComponent")] = Pdfbox::Cos::Integer.new(bits_per_component)
    end

    def color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace
      # TODO: Implement proper color space parsing
      Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB.new
    end

    def color_space=(color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace) : Nil
      # TODO: Implement proper color space setting
    end

    def height : Int32
      if @dict.has_key?(Pdfbox::Cos::Name.new("Height"))
        @dict[Pdfbox::Cos::Name.new("Height")].as(Pdfbox::Cos::Integer).value.to_i32
      else
        -1
      end
    end

    def height=(height : Int32) : Nil
      @dict[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(height)
    end

    def width : Int32
      if @dict.has_key?(Pdfbox::Cos::Name.new("Width"))
        @dict[Pdfbox::Cos::Name.new("Width")].as(Pdfbox::Cos::Integer).value.to_i32
      else
        -1
      end
    end

    def width=(width : Int32) : Nil
      @dict[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(width)
    end

    def decode=(decode : Pdfbox::Cos::Array) : Nil
      @dict[Pdfbox::Cos::Name.new("Decode")] = decode
    end

    def decode : Pdfbox::Cos::Array
      if @dict.has_key?(Pdfbox::Cos::Name.new("Decode"))
        @dict[Pdfbox::Cos::Name.new("Decode")].as(Pdfbox::Cos::Array)
      else
        Pdfbox::Cos::Array.new
      end
    end

    def interpolate? : Bool
      if @dict.has_key?(Pdfbox::Cos::Name.new("Interpolate"))
        @dict[Pdfbox::Cos::Name.new("Interpolate")].as(Pdfbox::Cos::Boolean).value
      else
        false
      end
    end

    def interpolate=(value : Bool) : Nil
      @dict[Pdfbox::Cos::Name.new("Interpolate")] = value ? Pdfbox::Cos::Boolean::TRUE : Pdfbox::Cos::Boolean::FALSE
    end

    def suffix : String
      # Determine suffix based on filter
      filter = @dict[Pdfbox::Cos::Name.new("Filter")]?
      return "png" unless filter

      filter_name = extract_filter_name(filter)

      case filter_name
      when "DCTDecode", "DCT"
        "jpg"
      when "JPXDecode"
        "jp2"
      when "CCITTFaxDecode"
        "tiff"
      when "FlateDecode", "LZWDecode", "RunLengthDecode"
        "png"
      else
        "png"
      end
    end

    private def extract_filter_name(filter : Pdfbox::Cos::Base) : String?
      case filter
      when Pdfbox::Cos::Name
        filter.as(Pdfbox::Cos::Name).value
      when Pdfbox::Cos::Array
        filters = filter.as(Pdfbox::Cos::Array)
        return if filters.size == 0
        first_filter = filters[0]
        first_filter.is_a?(Pdfbox::Cos::Name) ? first_filter.as(Pdfbox::Cos::Name).value : nil
      else
        nil
      end
    end

    def create_input_stream : ::IO
      create_input_stream([] of String)
    end

    def create_input_stream(stop_filters : Array(String)) : ::IO
      # Get the stream data
      stream = @stream
      unless stream
        # Try to get stream from dictionary
        if @dict.is_a?(Pdfbox::Cos::Stream)
          stream = @dict.as(Pdfbox::Cos::Stream)
        else
          return ::IO::Memory.new
        end
      end

      # Create input stream from stream data
      # TODO: Implement filter decoding based on stop_filters
      ::IO::Memory.new(stream.data)
    end

    # Helper method to get the COS stream
    private def get_stream : Pdfbox::Cos::Stream?
      @stream || (@dict.is_a?(Pdfbox::Cos::Stream) ? @dict.as(Pdfbox::Cos::Stream) : nil)
    end
  end
end

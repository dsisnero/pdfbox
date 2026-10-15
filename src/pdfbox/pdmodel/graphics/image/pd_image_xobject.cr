require "crimage"
require "./pd_image"

module Pdfbox::Pdmodel::Graphics::Image
  class PDImageXObject < PDImage
    @dict : Pdfbox::Cos::Dictionary
    @document : Pdfbox::Pdmodel::Document?
    @stream : Pdfbox::Cos::Stream?

    # Wraps a thumbnail stream as an image XObject without a document.
    # Java: PDImageXObject.createThumbnail(COSStream).
    def self.create_thumbnail(cos_stream : Pdfbox::Cos::Stream) : PDImageXObject
      new(nil, cos_stream, cos_stream)
    end

    # Creates a PDImageXObject from an image file.
    # Java: PDImageXObject.createFromFile(imagePath, doc)
    def self.create_from_file(image_path : String, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      create_from_file_by_extension(image_path, document)
    end

    # Creates a PDImageXObject from an image file, dispatching on the file-name suffix.
    # JPEG files are embedded directly with DCTDecode filter; other formats are converted
    # to raw RGB with FlateDecode compression.
    # Java: PDImageXObject.createFromFileByExtension(file, doc)
    def self.create_from_file_by_extension(image_path : String, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      name = File.basename(image_path)
      dot = name.rindex('.')
      raise ::ArgumentError.new("Image type not supported: #{name}") unless dot

      ext = name[dot + 1, name.size - dot - 1].downcase
      case ext
      when "jpg", "jpeg"
        JPEGFactory.create_from_stream(document, ::File.open(image_path))
      when "tif", "tiff", "gif", "bmp", "png"
        # CCITTFax (tif/tiff) decoding not yet in the Crystal filter set; raster fallback
        create_from_raster(image_path, document)
      else
        raise ::ArgumentError.new("Image type not supported: #{name}")
      end
    end

    # Creates a PDImageXObject from an image file, dispatching on the file content magic bytes.
    # Java: PDImageXObject.createFromFileByContent(file, doc)
    def self.create_from_file_by_content(image_path : String, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      file_type = Util::FileTypeDetector.detect_file_type(::File.read(image_path).to_slice)
      dispatch_by_file_type(file_type, image_path, document)
    end

    # Creates a PDImageXObject from a byte array of an image file, dispatching on content magic bytes.
    # Java: PDImageXObject.createFromByteArray(document, byteArray, name)
    def self.create_from_byte_array(document : Pdfbox::Pdmodel::Document, bytes : Bytes, name : String?) : PDImageXObject
      file_type = Util::FileTypeDetector.detect_file_type(bytes)
      case file_type
      when Util::FileType::Jpeg
        JPEGFactory.create_from_byte_array(document, bytes)
      when Util::FileType::Png
        # Java: try to convert the PNG directly (no recoding), fall back to raster.
        PNGConverter.convert_png_image(document, bytes) || create_from_raster_bytes(bytes, document)
      when Util::FileType::Gif, Util::FileType::Bmp
        create_from_raster_bytes(bytes, document)
      when Util::FileType::Tiff
        # CCITTFax decoding not yet in the Crystal filter set; raster fallback
        create_from_raster_bytes(bytes, document)
      else
        raise ::ArgumentError.new("Image type #{file_type} not supported: #{name}")
      end
    end

    private def self.dispatch_by_file_type(file_type : Util::FileType, image_path : String, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      case file_type
      when Util::FileType::Jpeg
        JPEGFactory.create_from_stream(document, ::File.open(image_path))
      when Util::FileType::Tiff
        # CCITTFax decoding not yet in the Crystal filter set; raster fallback
        create_from_raster(image_path, document)
      when Util::FileType::Bmp, Util::FileType::Gif, Util::FileType::Png
        create_from_raster(image_path, document)
      else
        raise ::ArgumentError.new("Image type #{file_type} not supported: #{File.basename(image_path)}")
      end
    end

    private def self.create_from_raster(image_path : String, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      create_from_raster_bytes(File.read(image_path).to_slice, document)
    end

    private def self.create_from_raster_bytes(image_bytes : Bytes, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      img = CrImage.read(::IO::Memory.new(image_bytes))
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

    def initialize(document : Pdfbox::Pdmodel::Document?, dict : Pdfbox::Cos::Dictionary? = nil, stream : Pdfbox::Cos::Stream? = nil)
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

    # Java PDImageXObject#getStructParent: key in the structural parent tree,
    # or -1 if there isn't any.
    def struct_parent : Int32
      @dict.get_int(Pdfbox::Cos::Name::STRUCT_PARENT, -1_i64).to_i32
    end

    def struct_parent=(value : Int) : Int32
      int_value = value.to_i32
      @dict.set_int(Pdfbox::Cos::Name::STRUCT_PARENT, int_value)
      int_value
    end

    # Java PDImageXObject#isEmpty: the encoded stream length is 0.
    def empty? : Bool
      stream.try(&.data.size) == 0
    end

    # Java getMask(): the explicit /Mask stream as a DeviceGray image, or nil.
    # A /Mask array is a color key mask (see color_key_mask), not an explicit mask.
    def mask : PDImageXObject?
      return nil if @dict.get_array(Pdfbox::Cos::Name.new("Mask"))
      cos_stream = @dict.get_stream(Pdfbox::Cos::Name.new("Mask"))
      cos_stream ? PDImageXObject.new(@document, cos_stream, cos_stream) : nil
    end

    # Java getColorKeyMask(): the /Mask array (color key mask), or nil.
    def color_key_mask : Pdfbox::Cos::Array?
      @dict.get_array(Pdfbox::Cos::Name.new("Mask"))
    end

    # Java getSoftMask(): the /SMask stream as a DeviceGray image, or nil.
    def soft_mask : PDImageXObject?
      cos_stream = @dict.get_stream(Pdfbox::Cos::Name.new("SMask"))
      cos_stream ? PDImageXObject.new(@document, cos_stream, cos_stream) : nil
    end

    # Java getOptionalContent(): the /OC entry as a PDPropertyList, or nil.
    def optional_content : Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList?
      dict = @dict.get_dictionary(Pdfbox::Cos::Name.new("OC"))
      dict ? Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList.create(dict) : nil
    end

    # Java setOptionalContent(PDPropertyList).
    def optional_content=(oc : Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList) : Nil
      @dict[Pdfbox::Cos::Name.new("OC")] = oc.cos_object
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
      cos_base = @dict[Pdfbox::Cos::Name.new("ColorSpace")]?
      if cos_base.is_a?(Pdfbox::Cos::Object)
        cos_base = cos_base.object
      end
      if cos_base
        if result = Pdfbox::Pdmodel::Graphics::Color::PDColorSpace.create(cos_base)
          return result
        end
        raise ::IO::Error.new("Illegal type of image color space: #{cos_base}")
      elsif stencil?
        # stencil mask color space must be gray, it is often missing
        Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
      else
        # an image without a color space is always broken
        raise ::IO::Error.new("could not determine color space")
      end
    end

    def color_space=(color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace) : Nil
      @dict[Pdfbox::Cos::Name.new("ColorSpace")] = color_space.cos_object
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
      source = stream
      return ::IO::Memory.new unless source

      source.create_input_stream(stop_filters)
    end

    # The underlying COS stream. Java getCOSObject() returns the COSStream.
    def stream : Pdfbox::Cos::Stream?
      @stream || (@dict.is_a?(Pdfbox::Cos::Stream) ? @dict.as(Pdfbox::Cos::Stream) : nil)
    end

    # The metadata stream (/Metadata), or nil (Java getMetadata).
    def metadata : Pdfbox::Pdmodel::Common::PDMetadata?
      s = stream
      return nil unless s
      md = s.get_dictionary_object(Pdfbox::Cos::Name.new("Metadata"))
      md.is_a?(Pdfbox::Cos::Stream) ? Pdfbox::Pdmodel::Common::PDMetadata.new(md) : nil
    end

    # Sets the metadata stream (/Metadata); nil removes it (Java setMetadata).
    def metadata=(meta : Pdfbox::Pdmodel::Common::PDMetadata?) : Nil
      s = stream
      return unless s
      key = Pdfbox::Cos::Name.new("Metadata")
      if meta
        s.set_item(key, meta.cos_object)
      else
        s.delete(key)
      end
    end
  end
end

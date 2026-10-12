require "./pd_image_xobject"
require "./lossless_factory"

module Pdfbox::Pdmodel::Graphics::Image
  # Factory for creating a PDImageXObject containing a JPEG compressed image.
  # Port of Apache PDFBox JPEGFactory (createFromStream / createFromByteArray /
  # createFromImage).
  #
  # create_from_stream / create_from_byte_array preserve the JPEG stream data and embed
  # it in the PDF file without modification. The color space is derived from the number
  # of components in the JPEG SOF (Start of Frame) marker: 1 -> DeviceGray, 3 ->
  # DeviceRGB, 4 -> DeviceCMYK. For CMYK images the Decode array is set to invert all
  # four components (Java parity).
  #
  # create_from_image encodes a raster image (the Crystal equivalent of a Java
  # BufferedImage) to JPEG. Images with transparency are flattened over an opaque white
  # background and get a DeviceGray JPEG soft mask (Java getColorImage/getAlphaImage).
  module JPEGFactory
    extend self

    # Java: JPEGFactory.DEFAULT_QUALITY
    DEFAULT_QUALITY = 0.75_f32

    # Creates a new JPEG Image XObject from an input stream containing JPEG data.
    def create_from_stream(document : Pdfbox::Pdmodel::Document, io : ::IO) : PDImageXObject
      create_from_byte_array(document, io.getb_to_end)
    end

    # Creates a new JPEG Image XObject from a byte array containing JPEG data.
    def create_from_byte_array(document : Pdfbox::Pdmodel::Document, bytes : Bytes) : PDImageXObject
      dimensions = retrieve_dimensions(bytes)

      color_space =
        case dimensions.num_components
        when 1 then Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
        when 3 then Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
        when 4 then Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE
        else
          raise Pdfbox::Cos::UnsupportedOperationError.new("number of data elements not supported: #{dimensions.num_components}")
        end

      stream = Pdfbox::Cos::Stream.new
      stream.data = bytes
      stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("DCTDecode")
      stream[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(dimensions.width)
      stream[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(dimensions.height)
      stream[Pdfbox::Cos::Name.new("BitsPerComponent")] = Pdfbox::Cos::Integer.new(8)
      stream[Pdfbox::Cos::Name.new("ColorSpace")] = color_space.cos_object

      image = PDImageXObject.new(document, stream, stream)

      if color_space.is_a?(Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK)
        decode = Pdfbox::Cos::Array.new
        decode.add(Pdfbox::Cos::Integer::ONE)
        decode.add(Pdfbox::Cos::Integer::ZERO)
        decode.add(Pdfbox::Cos::Integer::ONE)
        decode.add(Pdfbox::Cos::Integer::ZERO)
        decode.add(Pdfbox::Cos::Integer::ONE)
        decode.add(Pdfbox::Cos::Integer::ZERO)
        decode.add(Pdfbox::Cos::Integer::ONE)
        decode.add(Pdfbox::Cos::Integer::ZERO)
        image.decode = decode
      end

      image
    end

    # Java: JPEGFactory.createFromImage(PDDocument, BufferedImage)
    def create_from_image(document : Pdfbox::Pdmodel::Document, image : CrImage::Image) : PDImageXObject
      create_from_image(document, image, DEFAULT_QUALITY)
    end

    # Java: JPEGFactory.createFromImage(PDDocument, BufferedImage, float quality)
    #
    # The quality is a fraction (Java DEFAULT_QUALITY is 0.75). A JPEG has no alpha
    # channel, so transparent images are flattened over an opaque white background and
    # the original alpha is stored separately as a DeviceGray soft mask.
    def create_from_image(document : Pdfbox::Pdmodel::Document, image : CrImage::Image, quality : Float32) : PDImageXObject
      has_alpha = LosslessFactory.has_transparency?(image)

      ximage = create_from_byte_array(document, encode_image(image, quality))

      if has_alpha
        # Java getAlphaImage + ximage.getCOSObject().setItem(COSName.SMASK, xAlpha).
        xalpha = create_from_byte_array(document, encode_jpeg(alpha_gray_image(image), quality))
        ximage.cos_object[Pdfbox::Cos::Name.new("SMask")] = xalpha.cos_object
      end
      ximage
    end

    # Encodes the color plane of an image to JPEG. Grayscale images stay single-component
    # (DeviceGray); everything else is flattened to opaque RGB (DeviceRGB).
    #
    # The source image is always rebuilt into a freshly constructed CrImage before being
    # handed to the JPEG encoder: CrImage's JPEG writer cannot re-encode an image produced
    # by its own JPEG reader (it observes a corrupted bounds rectangle). Freshly built
    # images encode correctly.
    private def encode_image(image : CrImage::Image, quality : Float32) : Bytes
      if LosslessFactory.gray_image?(image)
        encode_jpeg(gray_copy(image), quality)
      else
        encode_jpeg(composite_over_white(image), quality)
      end
    end

    # Java JPEGFactory.encodeImageToJPEGStream: quality is a fraction converted to the
    # 1..100 range expected by the encoder (0.75 -> 75).
    private def encode_jpeg(image : CrImage::Image, quality : Float32) : Bytes
      jpeg_quality = (quality * 100).round.to_i.clamp(1, 100)
      io = ::IO::Memory.new
      CrImage::JPEG.write(io, image, jpeg_quality)
      io.to_slice
    end

    # Copies a grayscale image into a freshly constructed CrImage::Gray.
    private def gray_copy(image : CrImage::Image) : CrImage::Gray
      width = image.bounds.width
      height = image.bounds.height
      result = CrImage::Gray.new(CrImage.rect(0, 0, width, height))
      0.upto(height - 1) do |y|
        0.upto(width - 1) do |x|
          gray = CrImage::Color.gray_model.convert(image.at(x, y)).as(CrImage::Color::Gray)
          result.set_gray(x, y, gray)
        end
      end
      result
    end

    # Java JPEGFactory.getColorImage: builds an opaque RGB image by compositing the source
    # over a white background. Uses non-premultiplied components (Color::NRGBA) so the
    # flattening matches java.awt alpha compositing.
    private def composite_over_white(image : CrImage::Image) : CrImage::RGBA
      width = image.bounds.width
      height = image.bounds.height
      result = CrImage::RGBA.new(CrImage.rect(0, 0, width, height))
      0.upto(height - 1) do |y|
        0.upto(width - 1) do |x|
          color = CrImage::Color.nrgba_model.convert(image.at(x, y)).as(CrImage::Color::NRGBA)
          a = color.a.to_i32
          r = ((color.r.to_i32 * a) + (255 * (255 - a)) + 127) // 255
          g = ((color.g.to_i32 * a) + (255 * (255 - a)) + 127) // 255
          b = ((color.b.to_i32 * a) + (255 * (255 - a)) + 127) // 255
          result.set_rgba(x, y, CrImage::Color::RGBA.new(r.to_u8, g.to_u8, b.to_u8, 255_u8))
        end
      end
      result
    end

    # Java JPEGFactory.getAlphaImage: the alpha channel as an 8-bit grayscale image.
    private def alpha_gray_image(image : CrImage::Image) : CrImage::Gray
      width = image.bounds.width
      height = image.bounds.height
      result = CrImage::Gray.new(CrImage.rect(0, 0, width, height))
      0.upto(height - 1) do |y|
        0.upto(width - 1) do |x|
          color = CrImage::Color.nrgba_model.convert(image.at(x, y)).as(CrImage::Color::NRGBA)
          result.set_gray(x, y, CrImage::Color::Gray.new(color.a))
        end
      end
      result
    end

    private record Dimensions, width : Int32, height : Int32, num_components : Int32

    # Scans the JPEG markers for a Start of Frame (SOF) marker to read width, height and
    # the number of frame components. Mirrors Java's numFrameComponents behaviour
    # (PDFBOX-4691 / PDFBOX-5137: use frame, not scan, components).
    private def retrieve_dimensions(bytes : Bytes) : Dimensions
      length = bytes.size
      raise ::IO::Error.new("jpeg not long enough") if length < 4

      pos = 2 # skip SOI (0xFF 0xD8)
      while pos + 4 <= length
        marker = bytes[pos]
        raise ::IO::Error.new("invalid jpeg") unless marker == 0xFF

        marker_code = bytes[pos + 1]
        # Skip standalone / restart markers (no length field)
        if marker_code == 0xD8 || marker_code == 0x01 || (marker_code >= 0xD0 && marker_code <= 0xD7)
          pos += 2
          next
        end

        segment_length = (bytes[pos + 2].to_i32 << 8) | bytes[pos + 3].to_i32
        raise ::IO::Error.new("invalid jpeg segment length") if segment_length < 2

        # Start of Frame markers carry the frame dimensions and component count.
        # SOF0-SOF3, SOF5-SOF7, SOF9-SOF11, SOF13-SOF15 (SOF4/8/12/16 are arithmetic-coded
        # per segment, not frame headers).
        is_sof =
          case marker_code
          when 0xC0, 0xC1, 0xC2, 0xC3,
               0xC5, 0xC6, 0xC7,
               0xC9, 0xCA, 0xCB,
               0xCD, 0xCE, 0xCF
            true
          else
            false
          end

        if is_sof
          # SOF segment: length(2) precision(1) height(2) width(2) numComponents(1)
          return Dimensions.new(
            ((bytes[pos + 7].to_i32 << 8) | bytes[pos + 8].to_i32),
            ((bytes[pos + 5].to_i32 << 8) | bytes[pos + 6].to_i32),
            bytes[pos + 9].to_i32
          )
        end

        pos += 2 + segment_length
      end

      raise ::IO::Error.new("jpeg SOF marker not found")
    end
  end
end

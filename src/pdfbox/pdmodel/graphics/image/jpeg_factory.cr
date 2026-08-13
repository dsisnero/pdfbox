require "./pd_image_xobject"

module Pdfbox::Pdmodel::Graphics::Image
  # Factory for creating a PDImageXObject containing a JPEG compressed image.
  # Port of Apache PDFBox JPEGFactory (createFromStream / createFromByteArray).
  #
  # The JPEG stream data is preserved and embedded in the PDF file without modification.
  # The color space is derived from the number of components in the JPEG SOF (Start of
  # Frame) marker: 1 -> DeviceGray, 3 -> DeviceRGB, 4 -> DeviceCMYK. For CMYK images the
  # Decode array is set to invert all four components (Java parity).
  module JPEGFactory
    extend self

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

require "../../../io"

module Pdfbox::Pdmodel::Graphics::Image
  # Creates CCITT Fax (Group 4) compressed image XObjects from TIFF files.
  # Java org.apache.pdfbox.pdmodel.graphics.image.CCITTFactory.
  #
  # Only single-strip CCITT T4 (Group 3) or T6 (Group 4) compressed TIFF files
  # are supported. The CCITT-compressed strip is extracted from the TIFF and
  # wrapped in a PDImageXObject using the CCITTFaxDecode filter.
  class CCITTFactory
    Log = ::Log.for(self)

    # Creates a new CCITT Fax compressed image XObject from a specific image of
    # a TIFF file. Java CCITTFactory#createFromByteArray.
    def self.create_from_byte_array(document : Pdmodel::Document, byte_array : Bytes, number : Int32 = 0) : PDImageXObject?
      source = Pdfbox::IO::RandomAccessReadBuffer.new(byte_array)
      create_from_random_access_impl(document, source, number)
    end

    # Creates a new CCITT Fax compressed image XObject from a specific image of
    # a TIFF file. Java CCITTFactory#createFromFile.
    def self.create_from_file(document : Pdmodel::Document, path : String, number : Int32 = 0) : PDImageXObject?
      data = File.read(path).to_slice
      create_from_byte_array(document, data, number)
    end

    # Creates a new CCITT Fax compressed image XObject from an in-memory 1-bit
    # black-and-white raster. Java CCITTFactory#createFromImage.
    def self.create_from_image(document : Pdmodel::Document, width : Int32, height : Int32, binary_data : Bytes) : PDImageXObject
      # Flip bits so black=0 (avoid needing /BlackIs1).
      flipped = Bytes.new(binary_data.size)
      binary_data.each_with_index do |byte, i|
        flipped[i] = (~byte & 0xFF).to_u8
      end

      prepare_image_x_object(document, flipped, width, height)
    end

    private def self.prepare_image_x_object(document : Pdmodel::Document, byte_array : Bytes, width : Int32, height : Int32) : PDImageXObject
      dict = Pdfbox::Cos::Dictionary.new
      dict.set_int(Pdfbox::Cos::Name.new("Width"), width)
      dict.set_int(Pdfbox::Cos::Name.new("Height"), height)
      dict.set_int(Pdfbox::Cos::Name.new("Columns"), width)
      dict.set_int(Pdfbox::Cos::Name.new("Rows"), height)
      dict.set_int(Pdfbox::Cos::Name.new("K"), -1)
      dict.set_int(Pdfbox::Cos::Name.new("BitsPerComponent"), 1)
      dict.set_name(Pdfbox::Cos::Name.new("ColorSpace"), "DeviceGray")
      dict.set_name(Pdfbox::Cos::Name.new("Filter"), "CCITTFaxDecode")
      dict[Pdfbox::Cos::Name.new("DecodeParms")] = dict

      stream = Pdfbox::Cos::Stream.new(dict.entries, byte_array)
      PDImageXObject.new(document, dict, stream)
    end

    # Extracts the CCITT-compressed strip from a single-page TIFF and builds the
    # image XObject. Java CCITTFactory#createFromRandomAccessImpl.
    private def self.create_from_random_access_impl(document : Pdmodel::Document, reader : Pdfbox::IO::RandomAccessRead, number : Int32) : PDImageXObject?
      params = Pdfbox::Cos::Dictionary.new
      bytes = extract_from_tiff(reader, params, number)
      return nil if bytes.empty?

      dict = Pdfbox::Cos::Dictionary.new
      dict.set_name(Pdfbox::Cos::Name.new("Filter"), "CCITTFaxDecode")
      dict.set_int(Pdfbox::Cos::Name.new("BitsPerComponent"), 1)
      dict.set_int(Pdfbox::Cos::Name.new("Width"), params.get_int(Pdfbox::Cos::Name.new("Columns"), 0))
      dict.set_int(Pdfbox::Cos::Name.new("Height"), params.get_int(Pdfbox::Cos::Name.new("Rows"), 0))
      dict.set_name(Pdfbox::Cos::Name.new("ColorSpace"), "DeviceGray")
      dict[Pdfbox::Cos::Name.new("DecodeParms")] = params

      stream = Pdfbox::Cos::Stream.new(dict.entries, bytes)
      PDImageXObject.new(document, dict, stream)
    end

    # Parses the TIFF header/IFD and copies the single CCITT strip to a buffer,
    # populating the decode-params dictionary. Java CCITTFactory#extractFromTiff.
    private def self.extract_from_tiff(reader : Pdfbox::IO::RandomAccessRead, params : Pdfbox::Cos::Dictionary, number : Int32) : Bytes
      reader.seek(0)

      first = reader.read
      second = reader.read
      if first.nil? || second.nil? || first != second
        raise ::IO::Error.new("Not a valid tiff file")
      end
      endianness = first.chr
      if endianness != 'M' && endianness != 'I'
        raise ::IO::Error.new("Not a valid tiff file")
      end

      magic_number = read_short(endianness, reader)
      if magic_number != 42
        raise ::IO::Error.new("Not a valid tiff file")
      end

      address = read_long(endianness, reader)
      reader.seek(address)

      number.times do
        num_tags = read_short(endianness, reader)
        if num_tags > 50
          raise ::IO::Error.new("Not a valid tiff file")
        end
        reader.seek(address + 2 + num_tags * 12_i64)
        address = read_long(endianness, reader)
        return Bytes.empty if address == 0
        reader.seek(address)
      end

      num_tags = read_short(endianness, reader)
      if num_tags > 50
        raise ::IO::Error.new("Not a valid tiff file")
      end

      k = -1000
      data_offset = 0_i64
      data_length = 0_i64

      num_tags.times do
        tag = read_short(endianness, reader)
        type = read_short(endianness, reader)
        count = read_long(endianness, reader)
        val =
          case type
          when 1 # byte value
            v = reader.read
            reader.read
            reader.read
            reader.read
            v ? v : 0
          when 3 # short value
            v = read_short(endianness, reader)
            reader.read
            reader.read
            v
          else # long and other types
            read_long(endianness, reader)
          end

        case tag
        when 256
          params.set_int(Pdfbox::Cos::Name.new("Columns"), val)
        when 257
          params.set_int(Pdfbox::Cos::Name.new("Rows"), val)
        when 259
          k = -1 if val == 4 # T6
          k = 0 if val == 3  # T4
        when 262
          params.set_boolean(Pdfbox::Cos::Name.new("BlackIs1"), true) if val == 1
        when 266
          raise ::IO::Error.new("FillOrder #{val} is not supported") if val != 1
        when 273
          data_offset = val.to_i64 if count == 1
        when 274
          raise ::IO::Error.new("Orientation #{val} is not supported") if val != 1
        when 279
          data_length = val.to_i64 if count == 1
        when 292
          if (val & 1) != 0
            k = 50 # T4 2D - arbitrary positive K value
          end
          raise ::IO::Error.new("CCITT Group 3 'uncompressed mode' is not supported") if (val & 4) != 0
          raise ::IO::Error.new("CCITT Group 3 'fill bits before EOL' is not supported") if (val & 2) != 0
        when 324
          data_offset = val.to_i64 if count == 1
        when 325
          data_length = val.to_i64 if count == 1
        end
      end

      if k == -1000
        raise ::IO::Error.new("First image in tiff is not CCITT T4 or T6 compressed")
      end
      if data_offset == 0
        raise ::IO::Error.new("First image in tiff is not a single tile/strip")
      end

      params.set_int(Pdfbox::Cos::Name.new("K"), k)

      reader.seek(data_offset)
      buffer = Bytes.new(data_length)
      read = 0_i64
      while read < data_length
        count = reader.read(buffer[read, (data_length - read).to_i])
        break if count <= 0
        read += count
      end
      buffer[0, read.to_i]
    end

    private def self.read_short(endianness : Char, reader : Pdfbox::IO::RandomAccessRead) : Int32
      b0 = (reader.read || 0_u8).to_i
      b1 = (reader.read || 0_u8).to_i
      if endianness == 'I'
        b0 | (b1 << 8)
      else
        (b0 << 8) | b1
      end
    end

    private def self.read_long(endianness : Char, reader : Pdfbox::IO::RandomAccessRead) : Int64
      b0 = (reader.read || 0_u8).to_i
      b1 = (reader.read || 0_u8).to_i
      b2 = (reader.read || 0_u8).to_i
      b3 = (reader.read || 0_u8).to_i
      if endianness == 'I'
        (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)).to_i64
      else
        ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3).to_i64
      end
    end
  end
end

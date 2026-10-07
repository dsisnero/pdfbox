require "log"

module Pdfbox::Filter
  # Decodes image data encoded with Group 3 or Group 4 CCITT facsimile (fax)
  # encoding. Java: org.apache.pdfbox.filter.CCITTFaxFilter
  class CCITTFaxFilter < Filter
    Log = ::Log.for(self)

    def decode(encoded : Bytes, decode_params : Pdfbox::Cos::Dictionary?, width : Int32, height : Int32) : Bytes
      decode_parms = decode_params || Pdfbox::Cos::Dictionary.new

      cols = decode_parms.get_int(Pdfbox::Cos::Name.new("Columns"), 1728).to_i32
      rows = decode_parms.get_int(Pdfbox::Cos::Name.new("Rows"), 0).to_i32
      if rows > 0 && height > 0
        # PDFBOX-771, PDFBOX-3727: rows in DecodeParms sometimes contains an incorrect value
        rows = height
      else
        rows = Math.max(rows, height)
      end

      k = decode_parms.get_int(Pdfbox::Cos::Name.new("K"), 0).to_i32
      encoded_byte_align = boolean_parm(decode_parms, Pdfbox::Cos::Name.new("ENCODED_BYTE_ALIGN"), false)
      array_size = (cols + 7) // 8 * rows

      type = if k == 0
               # Group 3 1D or Modified Huffman RLE. The type detection below
               # mirrors Java: default to T4, but scan for a leading EOL and use
               # RLE if none is found.
               detect_type_1d(encoded)
             elsif k > 0
               TIFFExtension::COMPRESSION_CCITT_T4
             else
               TIFFExtension::COMPRESSION_CCITT_T6
             end

      tiff_options = 0_i64
      tiff_options = TIFFExtension::GROUP3OPT_2DENCODING.to_i64 if k > 0

      decoder = CCITTFaxDecoderStream.new(::IO::Memory.new(encoded), cols, type, tiff_options, encoded_byte_align)

      decompressed = Bytes.new(array_size)
      pos = 0
      loop do
        b = decoder.read_byte
        break if pos >= decompressed.size
        decompressed[pos] = b.to_u8
        pos += 1
      end

      # invert bitmap
      black_is_one = boolean_parm(decode_parms, Pdfbox::Cos::Name.new("BlackIs1"), false)
      invert_bitmap(decompressed) unless black_is_one

      decompressed
    end

    # Encodes image data to Group 4. Java: CCITTFaxFilter#encode, which reads
    # Columns/Rows from the decode parameters and pipes through
    # CCITTFaxEncoderStream.
    def encode(input : Bytes, parameters : Pdfbox::Cos::Dictionary?) : Bytes
      cols = parameters.try(&.get_int(Pdfbox::Cos::Name.new("Columns"), 0).to_i32) || 0
      rows = parameters.try(&.get_int(Pdfbox::Cos::Name.new("Rows"), 0).to_i32) || 0

      io = ::IO::Memory.new
      encoder = CCITTFaxEncoderStream.new(io, cols, rows, TIFFExtension::FILL_LEFT_TO_RIGHT)
      encoder.write(input)
      io.to_slice
    end

    private def boolean_parm(dict : Pdfbox::Cos::Dictionary, key : Pdfbox::Cos::Name, default : Bool) : Bool
      value = dict[key]?
      value = value.object if value.is_a?(Pdfbox::Cos::Object)
      value.as?(Pdfbox::Cos::Boolean).try(&.value) || default
    end

    # Determines the compression type for K == 0 (Group 3 1D vs Modified
    # Huffman RLE) by scanning the stream for an EOL marker.
    private def detect_type_1d(encoded : Bytes) : Int32
      type = TIFFExtension::COMPRESSION_CCITT_T4
      # leading EOL (0b000000000001) not found, search further and try RLE if not found
      if encoded.size < 2 || encoded[0] != 0_u8 || ((encoded[1] >> 4) != 1 && encoded[1] != 1)
        type = TIFFExtension::COMPRESSION_CCITT_MODIFIED_HUFFMAN_RLE
        bytes_read = [encoded.size, 20].min
        b = (((encoded[0]? || 0_u8).to_i32 << 8) + (encoded[1]? || 0_u8).to_i32) >> 4
        i = 12
        while i < bytes_read * 8
          b = (b << 1) + ((encoded[i // 8] >> (7 - (i % 8))) & 0x01)
          if (b & 0xFFF) == 1
            type = TIFFExtension::COMPRESSION_CCITT_T4
            break
          end
          i += 1
        end
      end
      type
    end

    private def invert_bitmap(buffer_data : Bytes) : Nil
      i = 0
      while i < buffer_data.size
        buffer_data[i] = (~buffer_data[i] & 0xFF).to_u8
        i += 1
      end
    end
  end
end

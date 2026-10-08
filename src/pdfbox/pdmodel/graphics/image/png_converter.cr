module Pdfbox::Pdmodel::Graphics::Image
  # Parses and validates PNG chunk structure so a PNG can later be converted into a
  # PDImageXObject by copying the image data directly into PDF streams. This port covers the
  # pure validation surface (CRC-32, chunk sanity, converter state, render-intent mapping).
  # Port of Apache PDFBox PNGConverter (validation parts).
  module PNGConverter
    extend self

    # Chunk Type definitions (big-endian four-byte codes).
    CHUNK_IHDR = 0x49484452_u32
    CHUNK_IDAT = 0x49444154_u32
    CHUNK_PLTE = 0x504C5445_u32
    CHUNK_IEND = 0x49454E44_u32
    CHUNK_TRNS = 0x74524E53_u32
    CHUNK_CHRM = 0x6348524D_u32
    CHUNK_GAMA = 0x67414D41_u32
    CHUNK_ICCP = 0x69434350_u32
    CHUNK_SBIT = 0x73424954_u32
    CHUNK_SRGB = 0x73524742_u32
    CHUNK_TEXT = 0x74455874_u32
    CHUNK_ZTXT = 0x7A545874_u32
    CHUNK_ITXT = 0x69545874_u32
    CHUNK_KBKG = 0x6B424B47_u32
    CHUNK_HIST = 0x68495354_u32
    CHUNK_PHYS = 0x70485973_u32
    CHUNK_SPLT = 0x73504C54_u32
    CHUNK_TIME = 0x74494D45_u32

    # Table of CRCs of all 8-bit messages.
    CRC_TABLE = make_crc_table

    # Holds the information about a chunk.
    class Chunk
      # The whole byte array shared across chunks of one file.
      property bytes : Bytes = Bytes.empty
      # The chunk type, see the CHUNK_??? constants.
      property chunk_type : UInt32 = 0_u32
      # The CRC of the chunk data, as stored in the PNG stream (Java int value).
      property crc : Int32 = 0
      # The start index of the chunk data within bytes.
      property start : Int32 = 0
      # The length of the data within the byte array.
      property length : Int32 = 0

      # Returns a byte-array with only the data of the chunk.
      def data : Bytes
        @bytes[@start, @length]
      end
    end

    # Holds all relevant chunks of the PNG.
    class PNGConverterState
      property idats = [] of Chunk
      property ihdr : Chunk?
      property plte : Chunk?
      property iccp : Chunk?
      property trns : Chunk?
      property srgb : Chunk?
      property gama : Chunk?
      property chrm : Chunk?

      # Parsed header fields.
      property width : Int32 = 0
      property height : Int32 = 0
      property bits_per_component : Int32 = 0
    end

    NAME_WIDTH       = Pdfbox::Cos::Name.new("Width")
    NAME_HEIGHT      = Pdfbox::Cos::Name.new("Height")
    NAME_BPC         = Pdfbox::Cos::Name.new("BitsPerComponent")
    NAME_COLORSPACE  = Pdfbox::Cos::Name.new("ColorSpace")
    NAME_FILTER      = Pdfbox::Cos::Name.new("Filter")
    NAME_DECODEPARMS = Pdfbox::Cos::Name.new("DecodeParms")
    NAME_INTENT      = Pdfbox::Cos::Name.new("Intent")
    NAME_SMASK       = Pdfbox::Cos::Name.new("SMask")

    # Converts a PNG byte stream directly into a PDImageXObject without recoding
    # the image, or returns nil when the PNG cannot be handled.
    # Java: PNGConverter#convertPNGImage.
    def convert_png_image(document : Pdfbox::Pdmodel::Document, image_data : Bytes) : PDImageXObject?
      state = parse_png_chunks(image_data)
      return nil unless state && check_converter_state(state)

      convert_png(document, state)
    end

    # Parses the PNG chunks into the converter state, or nil on malformed input.
    # Java: PNGConverter#parsePNGChunks.
    def parse_png_chunks(image_data : Bytes) : PNGConverterState?
      return nil if image_data.size < 20

      state = PNGConverterState.new
      ptr = 8
      first_chunk_type = read_int(image_data, ptr + 4).to_u32!
      return nil unless first_chunk_type == CHUNK_IHDR

      while ptr + 12 <= image_data.size
        chunk_length = read_int(image_data, ptr)
        chunk_type = read_int(image_data, ptr + 4).to_u32!
        ptr += 8

        return nil if ptr + chunk_length + 4 > image_data.size

        chunk = Chunk.new
        chunk.chunk_type = chunk_type
        chunk.bytes = image_data
        chunk.start = ptr
        chunk.length = chunk_length

        case chunk_type
        when CHUNK_IHDR
          return nil if state.ihdr
          state.ihdr = chunk
        when CHUNK_IDAT
          state.idats << chunk
        when CHUNK_PLTE
          return nil if state.plte
          state.plte = chunk
        when CHUNK_IEND
          return state
        when CHUNK_TRNS
          return nil if state.trns
          state.trns = chunk
        when CHUNK_GAMA
          state.gama = chunk
        when CHUNK_CHRM
          state.chrm = chunk
        when CHUNK_ICCP
          state.iccp = chunk
        when CHUNK_SRGB
          state.srgb = chunk
        else
          # sBIT and metadata chunks are ignored.
        end

        ptr += chunk_length
        chunk.crc = read_int(image_data, ptr)
        ptr += 4
      end
      nil
    end

    # Validates the IHDR fields and dispatches on the PNG color type.
    private def convert_png(document : Pdfbox::Pdmodel::Document, state : PNGConverterState) : PDImageXObject?
      ihdr = state.ihdr || return nil
      start = ihdr.start
      width = read_int(ihdr.bytes, start)
      height = read_int(ihdr.bytes, start + 4)
      bit_depth = ihdr.bytes[start + 8] & 0xFF
      color_type = ihdr.bytes[start + 9] & 0xFF
      compression_method = ihdr.bytes[start + 10] & 0xFF
      filter_method = ihdr.bytes[start + 11] & 0xFF
      interlace_method = ihdr.bytes[start + 12] & 0xFF

      return nil unless [1, 2, 4, 8, 16].includes?(bit_depth)
      return nil if width <= 0 || height <= 0
      return nil unless compression_method == 0
      return nil unless filter_method == 0
      return nil unless interlace_method == 0

      state.width = width
      state.height = height
      state.bits_per_component = bit_depth

      case color_type
      when 0 # Grayscale
        nil
      when 2 # Truecolor
        return nil if state.trns
        build_image_object(document, state)
      when 3 # Indexed
        build_index_image(document, state)
      when 4, 6 # Grayscale+alpha / truecolor+alpha
        nil
      else
        nil
      end
    end

    # Builds the base image object from the IDAT data and profile information.
    private def build_image_object(document : Pdfbox::Pdmodel::Document, state : PNGConverterState) : PDImageXObject?
      encoded = get_idat_data(state)
      color_space = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE

      dict = Pdfbox::Cos::Dictionary.new
      dict.set_int(NAME_WIDTH, state.width)
      dict.set_int(NAME_HEIGHT, state.height)
      dict.set_int(NAME_BPC, state.bits_per_component)
      dict.set_name(NAME_COLORSPACE, "DeviceRGB")
      dict.set_name(NAME_FILTER, "FlateDecode")
      dict[NAME_DECODEPARMS] = build_decode_params(state, color_space)

      stream = Pdfbox::Cos::Stream.new(dict.entries, encoded)
      image = PDImageXObject.new(document, dict, stream)

      has_icc_color_profile = !state.srgb.nil? || !state.iccp.nil?

      if (gama = state.gama) && !has_icc_color_profile
        return nil if gama.length != 4
        gamma = read_png_float(gama.bytes, gama.start)
        # The gamma is stored as 1 / gamma; only 2.2 (sRGB) is handled.
        return nil if (gamma - (1.0_f32 / 2.2_f32)).abs > 0.00001
      end

      if srgb = state.srgb
        return nil if srgb.length != 1
        render_intent = srgb.bytes[srgb.start].to_i32
        if value = map_png_render_intent(render_intent)
          dict[NAME_INTENT] = value
        end
      end

      if (chrm = state.chrm) && !has_icc_color_profile
        return nil if chrm.length != 32
        return nil # cHRM chunks are not handled.
      end

      if state.iccp || state.srgb
        cos_stream = create_cos_stream_with_icc_profile(color_space, state)
        return nil unless cos_stream

        array = Pdfbox::Cos::Array.new
        array.add(Pdfbox::Cos::Name.new("ICCBased"))
        array.add(cos_stream)
        image.color_space = Pdfbox::Pdmodel::Graphics::Color::PDICCBased.new(array)
      end

      image
    end

    # Builds an indexed image: base image + /Indexed color space + optional SMask.
    private def build_index_image(document : Pdfbox::Pdmodel::Document, state : PNGConverterState) : PDImageXObject?
      plte = state.plte
      return nil unless plte
      return nil unless plte.length % 3 == 0
      return nil if state.bits_per_component > 8

      image = build_image_object(document, state)
      return nil unless image

      high_val = (plte.length // 3) - 1
      return nil if high_val > 255

      setup_indexed_color_space(document, plte, image, high_val)

      if state.trns
        image.cos_object[NAME_SMASK] = build_transparency_mask_from_indexed_data(document, image, state)
      end

      image
    end

    # Replaces the image color space with /Indexed and attaches the lookup table.
    private def setup_indexed_color_space(document : Pdfbox::Pdmodel::Document, lookup_table : Chunk,
                                          image : PDImageXObject, high_val : Int32) : Nil
      indexed_array = Pdfbox::Cos::Array.new
      indexed_array.add(Pdfbox::Cos::Name.new("Indexed"))
      indexed_array.add(image.color_space.cos_object)

      if dp = image.cos_object.get_dictionary(NAME_DECODEPARMS)
        dp.set_int(Pdfbox::Cos::Name.new("Colors"), 1)
      end

      indexed_array.add(Pdfbox::Cos::Integer.new(high_val))

      color_table = Pdfbox::Cos::Stream.new
      output = color_table.create_output_stream(Pdfbox::Cos::Name.new("FlateDecode"))
      output.write(lookup_table.data)
      output.close
      indexed_array.add(color_table)

      image.color_space = Pdfbox::Pdmodel::Graphics::Color::PDIndexed.new(indexed_array)
    end

    # Builds the 8-bit DeviceGray soft mask from the indexed alpha table.
    private def build_transparency_mask_from_indexed_data(document : Pdfbox::Pdmodel::Document,
                                                          image : PDImageXObject,
                                                          state : PNGConverterState) : Pdfbox::Cos::Stream
      image_dict = Pdfbox::Cos::Dictionary.new
      image_dict.set_name(NAME_FILTER, "FlateDecode")
      image_dict[NAME_DECODEPARMS] = build_decode_params(state, Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)

      stream = Pdfbox::Cos::Stream.new(image_dict.entries, get_idat_data(state))
      decoded_idat = stream.create_input_stream.gets_to_end.to_slice

      length = image.width * image.height
      bytes = Bytes.new(length)
      transparency_table = state.trns.try(&.data) || Bytes.empty
      bits_per_component = state.bits_per_component
      bit_padding = (bits_per_component * state.width) % 8

      bit_pos = 0
      length.times do |i|
        idx = 0
        bits_per_component.times do
          byte_pos = bit_pos // 8
          bit = 7 - (bit_pos % 8)
          idx = (idx << 1) | ((decoded_idat[byte_pos] >> bit) & 1)
          bit_pos += 1
        end
        bytes[i] = idx < transparency_table.size ? transparency_table[idx] : 0xFF_u8
        bit_pos += bit_padding if (i + 1) % state.width == 0
      end

      mask = LosslessFactory.prepare_image_x_object(document, bytes, image.width, image.height, 8,
        Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
      mask.stream || raise ::IO::Error.new("transparency mask has no stream")
    end

    private def build_decode_params(state : PNGConverterState, color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace) : Pdfbox::Cos::Dictionary
      decode_params = Pdfbox::Cos::Dictionary.new
      decode_params.set_int(NAME_BPC, state.bits_per_component)
      decode_params.set_int(Pdfbox::Cos::Name.new("Predictor"), 15)
      decode_params.set_int(Pdfbox::Cos::Name.new("Columns"), state.width)
      decode_params.set_int(Pdfbox::Cos::Name.new("Colors"), color_space.number_of_components)
      decode_params
    end

    # Builds the ICCBased profile stream: the raw iCCP profile, or the bundled
    # sRGB profile when only the sRGB chunk is present.
    private def create_cos_stream_with_icc_profile(color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace,
                                                   state : PNGConverterState) : Pdfbox::Cos::Stream?
      number_of_components = color_space.number_of_components
      cos_stream = Pdfbox::Cos::Stream.new
      cos_stream.set_int(Pdfbox::Cos::Name.new("N"), number_of_components)
      cos_stream.set_name(Pdfbox::Cos::Name.new("Alternate"), number_of_components == 1 ? "DeviceGray" : "DeviceRGB")
      cos_stream.set_name(NAME_FILTER, "FlateDecode")

      if iccp = state.iccp
        icc_profile_data_start = 0
        while icc_profile_data_start < 80 && icc_profile_data_start < iccp.length
          break if iccp.bytes[iccp.start + icc_profile_data_start] == 0
          icc_profile_data_start += 1
        end
        icc_profile_data_start += 1
        return nil if icc_profile_data_start >= iccp.length

        compression_method = iccp.bytes[iccp.start + icc_profile_data_start]
        return nil unless compression_method == 0
        icc_profile_data_start += 1

        raw = cos_stream.create_raw_output_stream
        raw.write(iccp.bytes[iccp.start + icc_profile_data_start, iccp.length - icc_profile_data_start])
        raw.close
      else
        output = cos_stream.create_output_stream(Pdfbox::Cos::Name.new("FlateDecode"))
        output.write(SRGBICCProfile::BYTES)
        output.close
      end

      cos_stream
    end

    # Concatenates the IDAT chunk data (Java MultipleInputStream).
    private def get_idat_data(state : PNGConverterState) : Bytes
      size = 0
      state.idats.each { |idat| size += idat.length }
      buffer = Bytes.new(size)
      pos = 0
      state.idats.each do |idat|
        idat.data.copy_to(buffer[pos, idat.length])
        pos += idat.length
      end
      buffer
    end

    private def read_int(data : Bytes, offset : Int32) : Int32
      b1 = (data[offset] & 0xFF).to_i32 << 24
      b2 = (data[offset + 1] & 0xFF).to_i32 << 16
      b3 = (data[offset + 2] & 0xFF).to_i32 << 8
      b4 = (data[offset + 3] & 0xFF).to_i32
      b1 | b2 | b3 | b4
    end

    private def read_png_float(bytes : Bytes, offset : Int32) : Float32
      read_int(bytes, offset).to_f32 / 100000.0_f32
    end

    # Maps a PNG sRGB rendering intent to a PDF render-intent name, or nil.
    # See https://www.w3.org/TR/2003/REC-PNG-20031110/#11sRGB
    def map_png_render_intent(render_intent : Int32) : Pdfbox::Cos::Name?
      case render_intent
      when 0 then Pdfbox::Cos::Name.new("Perceptual")
      when 1 then Pdfbox::Cos::Name.new("RelativeColorimetric")
      when 2 then Pdfbox::Cos::Name.new("Saturation")
      when 3 then Pdfbox::Cos::Name.new("AbsoluteColorimetric")
      end
    end

    # Checks if the converter state is sane, i.e. all chunks validate.
    def check_converter_state(state : PNGConverterState?) : Bool
      return false unless state

      ihdr = state.ihdr
      return false if ihdr.nil? || !check_chunk_sane(ihdr)
      return false unless check_chunk_sane(state.plte)
      return false unless check_chunk_sane(state.iccp)
      return false unless check_chunk_sane(state.trns)
      return false unless check_chunk_sane(state.srgb)
      return false unless check_chunk_sane(state.chrm)
      return false unless check_chunk_sane(state.gama)

      # Check the IDATs
      return false if state.idats.empty?
      state.idats.each do |idat|
        return false unless check_chunk_sane(idat)
      end
      true
    end

    # Checks if the chunk is sane, i.e. CRC matches and offsets and lengths are within
    # the byte array. A nil chunk can not be wrong (the chunk does not exist).
    def check_chunk_sane(chunk : Chunk?) : Bool
      return true if chunk.nil?

      if chunk.start + chunk.length > chunk.bytes.size
        return false
      end

      if chunk.start < 4
        return false
      end

      # We must include the chunk type in the CRC calculation
      our_crc = crc(chunk.bytes, chunk.start - 4, chunk.length + 4)
      our_crc == chunk.crc
    end

    # Returns the CRC of the bytes buf[offset..(offset+len-1)]. Mirrors Java's 32-bit
    # signed int result.
    def crc(buf : Bytes, offset : Int32, len : Int32) : Int32
      (~update_crc(buf, offset, len)).to_i32!
    end

    # Make the table for a fast CRC.
    private def self.make_crc_table : Array(UInt32)
      table = Array(UInt32).new(256, 0_u32)
      256.times do |i|
        c = i.to_u32
        8.times do
          if (c & 1) != 0
            c = 0xEDB88320_u32 ^ (c >> 1)
          else
            c = c >> 1
          end
        end
        table[i] = c
      end
      table
    end

    # Updates a running CRC with the bytes buf[offset..(offset+len-1)]. The CRC should
    # be initialized to all 1's; the transmitted value is the 1's complement of the
    # final running CRC.
    private def update_crc(buf : Bytes, offset : Int32, len : Int32) : UInt32
      c = 0xFFFFFFFF_u32
      end_index = offset + len
      (offset...end_index).each do |i|
        c = CRC_TABLE[(c ^ buf[i].to_u32) & 0xFF] ^ (c >> 8)
      end
      c
    end
  end
end

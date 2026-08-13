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

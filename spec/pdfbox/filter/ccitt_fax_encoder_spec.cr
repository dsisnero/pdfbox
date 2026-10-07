require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/CCITTFaxEncoderStream.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/CCITTFaxFilter.java (encode)
#
# Java ships no unit test for the G4 encoder (TestFilters explicitly skips
# CCITTFaxFilter round-tripping), so these specs pin the encoder's observable
# contract two ways:
#   1. an exact bit-stream assertion for a trivial all-white row, derived from
#      the deterministic T.6 algorithm; and
#   2. round-trips through the already-Java-validated CCITTFaxDecoderStream.

module Pdfbox::Filter
  CCITT_ENCODER_IMAGE_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image"

  # Extracts (cols, rows, strip) from the single-strip ccittg4.tif fixture.
  def self.read_g4_strip(path : String) : {Int32, Int32, Bytes}
    bytes = File.read(path).to_slice
    io = ::IO::Memory.new(bytes)
    fmt = bytes[0] == 0x49 ? ::IO::ByteFormat::LittleEndian : ::IO::ByteFormat::BigEndian
    io.skip(4)
    ifd_offset = io.read_bytes(Int32, fmt)
    io.seek(ifd_offset)
    count = io.read_bytes(Int16, fmt)
    offset = 0_i64
    byte_count = 0_i64
    cols = 0
    rows = 0
    count.times do
      tag = io.read_bytes(Int16, fmt)
      type = io.read_bytes(Int16, fmt)
      io.read_bytes(Int32, fmt)
      val = if type == 3
              v = io.read_bytes(Int16, fmt)
              io.read_bytes(Int16, fmt)
              v.to_i32
            else
              io.read_bytes(Int32, fmt)
            end
      case tag
      when 256 then cols = val
      when 257 then rows = val
      when 273 then offset = val.to_i64
      when 279 then byte_count = val.to_i64
      end
    end
    {cols, rows, bytes[offset.to_i32, byte_count.to_i32]}
  end

  private def self.g4_decode_params(cols : Int32, rows : Int32, black_is_one : Bool) : Pdfbox::Cos::Dictionary
    params = Pdfbox::Cos::Dictionary.new
    params[Pdfbox::Cos::Name.new("Columns")] = Pdfbox::Cos::Integer.new(cols)
    params[Pdfbox::Cos::Name.new("Rows")] = Pdfbox::Cos::Integer.new(rows)
    params[Pdfbox::Cos::Name.new("K")] = Pdfbox::Cos::Integer.new(-1)
    params[Pdfbox::Cos::Name.new("BlackIs1")] = Pdfbox::Cos::Boolean.get(black_is_one)
    params
  end

  private def self.g4_encode_params(cols : Int32, rows : Int32) : Pdfbox::Cos::Dictionary
    params = Pdfbox::Cos::Dictionary.new
    params[Pdfbox::Cos::Name.new("Columns")] = Pdfbox::Cos::Integer.new(cols)
    params[Pdfbox::Cos::Name.new("Rows")] = Pdfbox::Cos::Integer.new(rows)
    params
  end

  private def self.decode_g4(strip : Bytes, cols : Int32, rows : Int32, black_is_one : Bool) : Bytes
    CCITTFaxFilter.new.decode(strip, g4_decode_params(cols, rows, black_is_one), cols, rows)
  end

  private def self.encode_g4(bitmap : Bytes, cols : Int32, rows : Int32) : Bytes
    CCITTFaxFilter.new.encode(bitmap, g4_encode_params(cols, rows))
  end

  describe CCITTFaxEncoderStream do
    it "emits the exact T.6 bit stream for a single all-white row" do
      io = ::IO::Memory.new
      encoder = CCITTFaxEncoderStream.new(io, 8, 1, TIFFExtension::FILL_LEFT_TO_RIGHT)
      encoder.write(Bytes[0x00_u8])

      # VMODE0 ("1") + EOL + EOL, padded to a byte boundary.
      io.to_slice.should eq(Bytes[0x80_u8, 0x08_u8, 0x00_u8, 0x80_u8])
    end

    it "round-trips a decoded ccittg4.tif bitmap" do
      cols, rows, strip = read_g4_strip(SpecPaths.resolve("#{CCITT_ENCODER_IMAGE_DIR}/ccittg4.tif"))
      original = decode_g4(strip, cols, rows, true)
      original.size.should eq((cols + 7) // 8 * rows)

      encoded = encode_g4(original, cols, rows)
      decode_g4(encoded, cols, rows, true).should eq(original)
    end

    it "round-trips synthetic alternating bitmaps" do
      cols = 17
      rows = 9
      row_bytes = (cols + 7) // 8
      bitmap = Bytes.new(row_bytes * rows)
      (0...rows).each do |r|
        (0...cols).each do |c|
          black = ((r + c) % 3 == 0) || (r.odd? && c.even?)
          bitmap[r * row_bytes + c // 8] |= (1_u8 << (7 - (c % 8))) if black
        end
      end

      encoded = encode_g4(bitmap, cols, rows)
      decode_g4(encoded, cols, rows, true).should eq(bitmap)
    end

    it "round-trips an all-black bitmap" do
      cols = 16
      rows = 4
      row_bytes = (cols + 7) // 8
      bitmap = Bytes.new(row_bytes * rows, 0xff_u8)

      encoded = encode_g4(bitmap, cols, rows)
      decode_g4(encoded, cols, rows, true).should eq(bitmap)
    end
  end
end

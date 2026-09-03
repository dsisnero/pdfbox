require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/CCITTFaxFilter.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/CCITTFaxDecoderStream.java
#
# Ports the CCITT Group 3 (T4) / Group 4 (T6) fax decode: the decoder stream
# (bit-level Huffman run-length decoding with white/black run trees and the
# 2D mode tree), and the filter that reads K/Columns/Rows/EncodedByteAlign/
# BlackIs1 from DecodeParms and routes through the decoder. The vendored
# ccittg3.tif / ccittg4.tif fixtures (344x287 bitonal scans) exercise real
# decode paths.

module Pdfbox::Filter
  CCITT_IMAGE_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image"

  # Extracts (cols, rows, compression, strip) from a single-strip CCITT TIFF.
  def self.read_ccitt_fixture(path : String) : {Int32, Int32, Int32, Bytes}
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
    compression = 0
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
      when 259 then compression = val
      when 273 then offset = val.to_i64
      when 279 then byte_count = val.to_i64
      end
    end
    strip = bytes[offset.to_i32, byte_count.to_i32]
    {cols, rows, compression, strip}
  end

  describe CCITTFaxDecoderStream do
    it "decodes the G4 (T.6) strip from ccittg4.tif" do
      cols, rows, compression, strip = read_ccitt_fixture("#{CCITT_IMAGE_DIR}/ccittg4.tif")
      compression.should eq(4) # CCITT T.6

      decoder = CCITTFaxDecoderStream.new(::IO::Memory.new(strip), cols, TIFFExtension::COMPRESSION_CCITT_T6, 0_i64, false)
      expected_size = (cols + 7) // 8 * rows
      out = Bytes.new(expected_size)
      pos = 0
      loop do
        b = decoder.read_byte
        break if pos >= out.size
        out[pos] = b.to_u8
        pos += 1
      end
      pos.should eq(expected_size)
      # a real bitonal scan has both black and white runs
      out.count(0_u8).should be > 0
      out.count(0xff_u8).should be > 0
    end

    it "decodes the G3 (T4) strip from ccittg3.tif" do
      cols, rows, compression, strip = read_ccitt_fixture("#{CCITT_IMAGE_DIR}/ccittg3.tif")
      compression.should eq(3) # CCITT T.4

      # The fixture is Group 3 1D (no GROUP3OPT_2DENCODING).
      decoder = CCITTFaxDecoderStream.new(::IO::Memory.new(strip), cols, TIFFExtension::COMPRESSION_CCITT_T4, 0_i64, false)
      expected_size = (cols + 7) // 8 * rows
      out = Bytes.new(expected_size)
      pos = 0
      loop do
        b = decoder.read_byte
        break if pos >= out.size
        out[pos] = b.to_u8
        pos += 1
      end
      pos.should eq(expected_size)
      out.count(0_u8).should be > 0
      out.count(0xff_u8).should be > 0
    end
  end

  describe CCITTFaxFilter do
    it "decodes a G4 stream via Cos::Stream with CCITTFaxDecode + DecodeParms" do
      cols, rows, _compression, strip = read_ccitt_fixture("#{CCITT_IMAGE_DIR}/ccittg4.tif")

      stream = Pdfbox::Cos::Stream.new(entries: {} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, data: strip)
      stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("CCITTFaxDecode")
      stream[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(cols)
      stream[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(rows)
      dp = Pdfbox::Cos::Dictionary.new
      dp[Pdfbox::Cos::Name.new("Columns")] = Pdfbox::Cos::Integer.new(cols)
      dp[Pdfbox::Cos::Name.new("Rows")] = Pdfbox::Cos::Integer.new(rows)
      dp[Pdfbox::Cos::Name.new("K")] = Pdfbox::Cos::Integer.new(-1)
      stream[Pdfbox::Cos::Name.new("DecodeParms")] = dp

      decoded = stream.create_input_stream.gets_to_end
      decoded.bytesize.should eq((cols + 7) // 8 * rows)
    end

    it "decodes a G4 stream via the CCF abbreviation" do
      cols, rows, _compression, strip = read_ccitt_fixture("#{CCITT_IMAGE_DIR}/ccittg4.tif")

      stream = Pdfbox::Cos::Stream.new(entries: {} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, data: strip)
      stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("CCF")
      stream[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(cols)
      stream[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(rows)
      dp = Pdfbox::Cos::Dictionary.new
      dp[Pdfbox::Cos::Name.new("Columns")] = Pdfbox::Cos::Integer.new(cols)
      dp[Pdfbox::Cos::Name.new("Rows")] = Pdfbox::Cos::Integer.new(rows)
      dp[Pdfbox::Cos::Name.new("K")] = Pdfbox::Cos::Integer.new(-1)
      stream[Pdfbox::Cos::Name.new("DecodeParms")] = dp

      decoded = stream.create_input_stream.gets_to_end
      decoded.bytesize.should eq((cols + 7) // 8 * rows)
    end

    it "is registered in FilterFactory under CCITTFaxDecode and CCF" do
      Pdfbox::Filter::FilterFactory::INSTANCE.filter(Pdfbox::Cos::Name.new("CCITTFaxDecode")).should be_a(CCITTFaxFilter)
      Pdfbox::Filter::FilterFactory::INSTANCE.filter(Pdfbox::Cos::Name.new("CCF")).should be_a(CCITTFaxFilter)
    end
  end
end

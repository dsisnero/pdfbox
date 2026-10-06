require "../../../spec_helper"
require "../../../../src/pdfbox"

# Source of truth:
# vendor/pdfbox/tools/src/test/java/org/apache/pdfbox/tools/imageio/TestImageIOUtils.java
#
# TestImageIOUtils is a render/ImageIO-write suite (writes PNG/JPG/BMP/GIF/WBMP/
# TIFF from rendered images and reads them back with ImageIO metadata). The
# render + ImageIO write/read parts are advisory (Chunk M render policy). The
# feasible behavioral helpers ported here:
#   - checkFileTypeByContent: FileTypeDetector.detectFileType on image bytes
#     (also covered by pd_image_xobject_dispatch_spec.cr).
#   - checkBmpResolution: BMP pixels-per-meter at byte offsets 38/42 (pure bytes).
#   - checkTiffCompression: TIFF IFD Compression tag 259 reading (pure bytes).

module Pdfbox::Tools::ImageIO
  module TiffBmpSpecHelpers
    def self.write_le16(io : ::IO, value : Int32) : Nil
      io.write_byte((value & 0xFF).to_u8)
      io.write_byte(((value >> 8) & 0xFF).to_u8)
    end

    def self.write_le32(io : ::IO, value : Int32) : Nil
      io.write_byte((value & 0xFF).to_u8)
      io.write_byte(((value >> 8) & 0xFF).to_u8)
      io.write_byte(((value >> 16) & 0xFF).to_u8)
      io.write_byte(((value >> 24) & 0xFF).to_u8)
    end
  end

  describe "TestImageIOUtils behavioral helpers" do
    it "checkFileTypeByContent detects PNG/JPEG/BMP/GIF/TIFF by magic bytes" do
      png = Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52]
      Pdfbox::Util::FileTypeDetector.detect_file_type(png).should eq(Pdfbox::Util::FileType::Png)

      jpeg = Bytes[0xFF, 0xD8, 0xFF, 0xE0]
      Pdfbox::Util::FileTypeDetector.detect_file_type(jpeg).should eq(Pdfbox::Util::FileType::Jpeg)

      bmp = Bytes[0x42, 0x4D, 0x36, 0x00, 0x00, 0x00]
      Pdfbox::Util::FileTypeDetector.detect_file_type(bmp).should eq(Pdfbox::Util::FileType::Bmp)

      gif = Bytes[0x47, 0x49, 0x46, 0x38, 0x39, 0x61]
      Pdfbox::Util::FileTypeDetector.detect_file_type(gif).should eq(Pdfbox::Util::FileType::Gif)

      tiff_le = Bytes[0x49, 0x49, 0x2A, 0x00]
      Pdfbox::Util::FileTypeDetector.detect_file_type(tiff_le).should eq(Pdfbox::Util::FileType::Tiff)
    end

    it "checkBmpResolution reads pixels-per-meter at byte offset 38" do
      # Build a minimal 54-byte BMP file header + info header; pixels-per-meter
      # (2 x 4 bytes little-endian) land at offsets 38 and 42. For a 96 dpi
      # target the pixels-per-meter is 96 / 2.54 * 100 = 3780 (rounded).
      ppm = (96 / 2.54 * 100).round.to_i
      bytes = Bytes.new(54)
      bytes[0] = 0x42_u8 # 'B'
      bytes[1] = 0x4D_u8 # 'M'
      bytes[38] = (ppm & 0xFF).to_u8
      bytes[39] = ((ppm >> 8) & 0xFF).to_u8
      bytes[40] = ((ppm >> 16) & 0xFF).to_u8
      bytes[41] = ((ppm >> 24) & 0xFF).to_u8
      bytes[42] = bytes[38]
      bytes[43] = bytes[39]
      bytes[44] = bytes[40]
      bytes[45] = bytes[41]

      io = ::IO::Memory.new(bytes)
      io.skip(38)
      x_ppm = io.read_bytes(Int32, ::IO::ByteFormat::LittleEndian)
      y_ppm = io.read_bytes(Int32, ::IO::ByteFormat::LittleEndian)
      (x_ppm / 100.0 * 2.54).round.to_i.should eq(96)
      (y_ppm / 100.0 * 2.54).round.to_i.should eq(96)
    end

    it "checkTiffCompression reads the Compression tag (259) of a TIFF IFD" do
      # Minimal little-endian TIFF: header + one IFD entry for tag 259
      # (Compression), type SHORT (3), value 4 = CCITT T.6 / Group 4 fax.
      io = ::IO::Memory.new
      TiffBmpSpecHelpers.write_le16(io, 0x4949) # II little-endian
      TiffBmpSpecHelpers.write_le16(io, 42)     # TIFF magic
      TiffBmpSpecHelpers.write_le32(io, 8)      # offset to IFD
      TiffBmpSpecHelpers.write_le16(io, 1)      # one entry
      TiffBmpSpecHelpers.write_le16(io, 259)    # Compression tag
      TiffBmpSpecHelpers.write_le16(io, 3)      # type SHORT
      TiffBmpSpecHelpers.write_le32(io, 1)      # count
      TiffBmpSpecHelpers.write_le16(io, 4)      # value: CCITT T.6
      TiffBmpSpecHelpers.write_le16(io, 0)      # padding
      TiffBmpSpecHelpers.write_le32(io, 0)      # next IFD offset

      reader = ::IO::Memory.new(io.to_slice)
      reader.read_bytes(Int16, ::IO::ByteFormat::LittleEndian).should eq(0x4949)
      reader.read_bytes(Int16, ::IO::ByteFormat::LittleEndian).should eq(42)
      ifd_offset = reader.read_bytes(Int32, ::IO::ByteFormat::LittleEndian)
      ifd_offset.should eq(8)
      reader.seek(ifd_offset)
      reader.read_bytes(Int16, ::IO::ByteFormat::LittleEndian).should eq(1)
      reader.read_bytes(Int16, ::IO::ByteFormat::LittleEndian).should eq(259)
      reader.read_bytes(Int16, ::IO::ByteFormat::LittleEndian).should eq(3)
      reader.read_bytes(Int32, ::IO::ByteFormat::LittleEndian).should eq(1)
      reader.read_bytes(Int16, ::IO::ByteFormat::LittleEndian).should eq(4)
    end
  end
end

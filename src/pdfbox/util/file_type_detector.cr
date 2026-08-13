module Pdfbox::Util
  # Enumeration of supported image file formats.
  # Port of Apache PDFBox FileType.
  enum FileType
    Unknown
    Jpeg
    Tiff
    Psd
    Png
    Bmp
    Gif
    Ico
    Pcx
    Riff
    Arw
    Crw
    Cr2
    Nef
    Orf
    Raf
    Rw2
  end

  # Examines the file's first bytes and estimates the file's type.
  # Port of Apache PDFBox FileTypeDetector (magic-byte signatures).
  module FileTypeDetector
    extend self

    # Each entry is a (signature prefix, file type) pair. Signatures are matched
    # against the leading bytes of the input, longest prefix wins.
    private SIGNATURES = [
      {[0xFF_u8, 0xD8_u8], FileType::Jpeg},
      {[0x49_u8, 0x49_u8, 0x2A_u8, 0x00_u8], FileType::Tiff}, # "II" little endian
      {[0x4D_u8, 0x4D_u8, 0x00_u8, 0x2A_u8], FileType::Tiff}, # "MM" big endian
      {[0x38_u8, 0x42_u8, 0x50_u8, 0x53_u8], FileType::Psd},  # "8BPS"
      {[0x89_u8, 0x50_u8, 0x4E_u8, 0x47_u8, 0x0D_u8, 0x0A_u8, 0x1A_u8, 0x0A_u8,
        0x00_u8, 0x00_u8, 0x00_u8, 0x0D_u8, 0x49_u8, 0x48_u8, 0x44_u8, 0x52_u8], FileType::Png},
      {[0x42_u8, 0x4D_u8], FileType::Bmp},                                     # "BM"
      {[0x47_u8, 0x49_u8, 0x46_u8, 0x38_u8, 0x37_u8, 0x61_u8], FileType::Gif}, # "GIF87a"
      {[0x47_u8, 0x49_u8, 0x46_u8, 0x38_u8, 0x39_u8, 0x61_u8], FileType::Gif}, # "GIF89a"
      {[0x00_u8, 0x00_u8, 0x01_u8, 0x00_u8], FileType::Ico},
      {[0x0A_u8, 0x00_u8, 0x01_u8], FileType::Pcx},
      {[0x0A_u8, 0x02_u8, 0x01_u8], FileType::Pcx},
      {[0x0A_u8, 0x03_u8, 0x01_u8], FileType::Pcx},
      {[0x0A_u8, 0x05_u8, 0x01_u8], FileType::Pcx},
      {[0x52_u8, 0x49_u8, 0x46_u8, 0x46_u8], FileType::Riff}, # "RIFF"
      {[0x49_u8, 0x49_u8, 0x1A_u8, 0x00_u8, 0x00_u8, 0x00_u8,
        0x48_u8, 0x45_u8, 0x41_u8, 0x50_u8, 0x43_u8, 0x43_u8, 0x44_u8, 0x52_u8], FileType::Crw},
      {[0x49_u8, 0x49_u8, 0x2A_u8, 0x00_u8, 0x10_u8, 0x00_u8, 0x00_u8, 0x00_u8, 0x43_u8, 0x52_u8], FileType::Cr2},
      {[0x4D_u8, 0x4D_u8, 0x00_u8, 0x2A_u8, 0x00_u8, 0x00_u8, 0x00_u8, 0x80_u8, 0x00_u8], FileType::Nef},
      {[0x49_u8, 0x49_u8, 0x52_u8, 0x4F_u8, 0x08_u8, 0x00_u8], FileType::Orf},
      {[0x49_u8, 0x49_u8, 0x52_u8, 0x53_u8, 0x08_u8, 0x00_u8], FileType::Orf},
      {[0x46_u8, 0x55_u8, 0x4A_u8, 0x49_u8, 0x46_u8, 0x49_u8, 0x4C_u8, 0x4D_u8, 0x43_u8, 0x43_u8,
        0x44_u8, 0x2D_u8, 0x52_u8, 0x41_u8, 0x57_u8], FileType::Raf}, # "FUJIFILMCCD-RAW"
      {[0x49_u8, 0x49_u8, 0x55_u8, 0x00_u8], FileType::Rw2},
    ] of Tuple(Array(UInt8), FileType)

    # Estimates the file type from the leading bytes.
    def detect_file_type(bytes : Bytes) : FileType
      matches = SIGNATURES.select do |signature, _type|
        prefix_matches?(signature, bytes)
      end
      return FileType::Unknown if matches.empty?

      longest = matches.max_by { |signature, _type| signature.size }
      longest[1]
    end

    private def prefix_matches?(signature : Array(UInt8), bytes : Bytes) : Bool
      return false if bytes.size < signature.size
      signature.each_with_index do |byte, index|
        return false unless bytes[index] == byte
      end
      true
    end
  end
end

require "./byte_trie"

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
  # Port of Apache PDFBox FileTypeDetector (magic-byte signatures stored in a
  # ByteTrie, most specific match wins).
  module FileTypeDetector
    extend self

    private ROOT = begin
      trie = ByteTrie(FileType).new
      trie.set_default_value(FileType::Unknown)

      # https://en.wikipedia.org/wiki/List_of_file_signatures
      trie.add_path(FileType::Jpeg, Bytes[0xFF, 0xD8])
      trie.add_path(FileType::Tiff, "II".to_slice, Bytes[0x2A, 0x00])
      trie.add_path(FileType::Tiff, "MM".to_slice, Bytes[0x00, 0x2A])
      trie.add_path(FileType::Psd, "8BPS".to_slice)
      trie.add_path(FileType::Png, Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52])
      # TODO technically there are other very rare magic numbers for OS/2 BMP files...
      trie.add_path(FileType::Bmp, "BM".to_slice)
      trie.add_path(FileType::Gif, "GIF87a".to_slice)
      trie.add_path(FileType::Gif, "GIF89a".to_slice)
      trie.add_path(FileType::Ico, Bytes[0x00, 0x00, 0x01, 0x00])
      # multiple PCX versions, explicitly listed
      trie.add_path(FileType::Pcx, Bytes[0x0A, 0x00, 0x01])
      trie.add_path(FileType::Pcx, Bytes[0x0A, 0x02, 0x01])
      trie.add_path(FileType::Pcx, Bytes[0x0A, 0x03, 0x01])
      trie.add_path(FileType::Pcx, Bytes[0x0A, 0x05, 0x01])
      trie.add_path(FileType::Riff, "RIFF".to_slice)
      trie.add_path(FileType::Crw, "II".to_slice, Bytes[0x1A, 0x00, 0x00, 0x00], "HEAPCCDR".to_slice)
      trie.add_path(FileType::Cr2, "II".to_slice, Bytes[0x2A, 0x00, 0x10, 0x00, 0x00, 0x00, 0x43, 0x52])
      trie.add_path(FileType::Nef, "MM".to_slice, Bytes[0x00, 0x2A, 0x00, 0x00, 0x00, 0x80, 0x00])
      trie.add_path(FileType::Orf, "IIRO".to_slice, Bytes[0x08, 0x00])
      trie.add_path(FileType::Orf, "IIRS".to_slice, Bytes[0x08, 0x00])
      trie.add_path(FileType::Raf, "FUJIFILMCCD-RAW".to_slice)
      trie.add_path(FileType::Rw2, "II".to_slice, Bytes[0x55, 0x00])
      trie
    end

    # Estimates the file type from the leading bytes.
    def detect_file_type(bytes : Bytes) : FileType
      ROOT.find(bytes) || FileType::Unknown
    end
  end
end

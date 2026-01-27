require "compress/zlib"
require "compress/deflate"

module Pdfbox::Pdfparser
  # Base class for PDF parsing errors
  class ParseError < Pdfbox::PDFError; end

  # Raised when PDF syntax is invalid
  class SyntaxError < ParseError; end

  # Raised when PDF is encrypted and password is required
  class EncryptedPDFError < ParseError; end

  # Raised when PDF version is not supported
  class UnsupportedVersionError < ParseError; end
end

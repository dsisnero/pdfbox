# PDFBox Crystal - A Crystal port of Apache PDFBox
#
# This library provides PDF document manipulation capabilities for Crystal,
# ported from the Apache PDFBox Java library.
module Pdfbox
  VERSION = "0.1.0"

  # Base exception class for PDFBox errors
  class Error < Exception; end

  # Raised when a PDF document cannot be loaded or parsed
  class PDFError < Error; end

  # Raised when a PDF operation is not supported
  class UnsupportedFeatureError < Error; end
end

# Require all PDFBox modules
require "./pdfbox/cos"
require "./pdfbox/pdmodel"
require "./pdfbox/io"
require "./pdfbox/pdfparser"
require "./pdfbox/pdfwriter"
require "./fontbox"
require "./xmpbox"
require "./tools"

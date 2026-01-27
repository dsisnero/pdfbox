module Pdfbox::Pdfparser
  # Parser for COS objects
  class COSParser
    @scanner : PDFScanner

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      @scanner = PDFScanner.new(source)
    end

    # Parse a COS literal string from the input
    def parse_cos_literal_string : Pdfbox::Cos::String
      Pdfbox::Cos::String.new(@scanner.read_literal_string)
    end
  end
end

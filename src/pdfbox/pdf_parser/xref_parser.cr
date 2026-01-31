# XrefParser - Parser to read the cross reference table of a PDF
# Similar to Apache PDFBox XrefParser
require "./xref_trailer_resolver"

module Pdfbox::Pdfparser
  class XrefParser
    Log = ::Log.for(self)

    private X                     = 'x'.ord
    private XREF_TABLE            = ['x'.ord, 'r'.ord, 'e'.ord, 'f'.ord]
    private STARTXREF             = ['s'.ord, 't'.ord, 'a'.ord, 'r'.ord, 't'.ord, 'x'.ord, 'r'.ord, 'e'.ord, 'f'.ord]
    private MINIMUM_SEARCH_OFFSET = 6_i64

    # Collects all Xref/trailer objects and resolves them into single
    # object using startxref reference.
    @xref_trailer_resolver : XrefTrailerResolver

    @parser : COSParser
    @source : Pdfbox::IO::RandomAccessRead

    # Default constructor.
    #
    # @param cos_parser the parser to be used to read the pdf.
    def initialize(cos_parser : COSParser)
      @parser = cos_parser
      @source = cos_parser.source
      @xref_trailer_resolver = XrefTrailerResolver.new
    end

    # Returns the resulting cross reference table.
    def xref_table : Hash(Cos::ObjectKey, Int64)
      @xref_trailer_resolver.xref_table || Hash(Cos::ObjectKey, Int64).new
    end

    # Returns the resolved trailer dictionary.
    def trailer : Cos::Dictionary?
      @xref_trailer_resolver.trailer
    end
  end
end

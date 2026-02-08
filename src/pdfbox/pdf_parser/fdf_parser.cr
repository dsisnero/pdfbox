# FDFParser for parsing Forms Data Format (FDF) files
# Similar to Apache PDFBox FDFParser
require "./cos_parser"

module Pdfbox::Pdfparser
  class FDFParser < COSParser
    # Constructs parser for given source
    # @param source the source of the pdf to be parsed
    def initialize(source : Pdfbox::IO::RandomAccessRead)
      super(source)
    end

    # The initial parse will first parse only the trailer, the xrefstart and all xref tables to have a pointer (offset)
    # to all the pdf's objects. It can handle linearized pdfs, which will have an xref at the end pointing to an xref
    # at the beginning of the file. Last the root object is parsed.
    private def initial_parse : Nil
      trailer = retrieve_trailer
      unless trailer
        raise ::IO::Error.new("Missing trailer")
      end

      root = trailer[Cos::Name.new("Root")]?
      unless root && root.is_a?(Cos::Dictionary)
        raise ::IO::Error.new("Missing root object specification in trailer.")
      end
      @initial_parse_done = true
    end

    # Parse FDF header (similar to PDF header)
    # @return true if header contains valid FDF version info
    private def parse_fdf_header : Bool
      # TODO: Implement FDF header parsing
      # Should check for "%FDF-1.2" or similar
      true
    end

    # This will parse the stream and populate the FDFDocument object.
    # @return the parsed FDFDocument
    # @raise ::IO::Error if there is an error reading from the stream or corrupt data is found.
    def parse : FDFDocument
      # set to false if all is processed
      exception_occurred = true
      begin
        unless parse_fdf_header
          raise ::IO::Error.new("Error: Header doesn't contain versioninfo")
        end
        initial_parse
        exception_occurred = false
        # TODO: Create and return FDFDocument
        FDFDocument.new
      ensure
        if exception_occurred && (document = @document)
          # close document quietly
          document.close rescue nil
          @document = nil
        end
      end
    end
  end

  # Dummy FDFDocument class for now
  class FDFDocument
    def initialize
    end
  end
end

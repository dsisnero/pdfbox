# This class represents metadata for various objects in a PDF document
module Pdfbox::Pdmodel::Common
  class PDMetadata < PDStream
    # Constructor wrapping a COSStream
    # This will NOT set up the /Type and /Subtype entries
    def initialize(stream : Cos::Stream)
      super(stream)
    end

    # Extract the XMP metadata
    # Returns a stream to get the xmp data from
    def export_xmp_metadata : IO
      create_input_stream
    end

    # Import an XMP stream into the PDF document
    def import_xmp_metadata(xmp : Bytes) : Nil
      io = create_output_stream
      io.write(xmp)
      io.close
    end
  end
end

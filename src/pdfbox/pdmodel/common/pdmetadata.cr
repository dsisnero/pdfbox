require "../../../xmpbox"

# This class represents metadata for various objects in a PDF document
module Pdfbox::Pdmodel::Common
  class PDMetadata < PDStream
    # Constructor wrapping a COSStream
    # This will NOT set up the /Type and /Subtype entries
    def initialize(stream : Cos::Stream)
      super(stream)
    end

    # Creates a new PDMetadata object with /Type and /Subtype entries for document-level metadata
    def initialize(document : Pdmodel::PDDocument)
      super(document)
      cos_object[Cos::Name::TYPE] = Cos::Name.new("Metadata")
      cos_object[Cos::Name::SUBTYPE] = Cos::Name.new("XML")
    end

    # Constructor with input stream
    def initialize(document : Pdmodel::PDDocument, input : IO)
      super(document, input)
      cos_object[Cos::Name::TYPE] = Cos::Name.new("Metadata")
      cos_object[Cos::Name::SUBTYPE] = Cos::Name.new("XML")
    end

    # Extract the XMP metadata
    # Returns a stream to get the xmp data from
    def export_xmp_metadata : ::IO
      create_input_stream
    end

    # Import an XMP stream into the PDF document
    def import_xmp_metadata(xmp : Bytes) : Nil
      io = create_output_stream
      io.write(xmp)
      io.close
    end

    # Parse XMP metadata using XmpBox
    def xmp_metadata : Xmpbox::XMPMetadata?
      input = export_xmp_metadata
      return nil if input.as(IO::Memory).size.zero?
      parser = Xmpbox::Xml::DomXmpParser.new
      parser.strict_parsing = false
      parser.parse(input)
    rescue
      nil
    end

    # Serialize XMP metadata and store in the PDF
    def xmp_metadata=(xmp : Xmpbox::XMPMetadata) : Nil
      serializer = Xmpbox::Xml::XmpSerializer.new
      xml = serializer.serialize(xmp)
      import_xmp_metadata(xml.to_slice)
    end

    # Creates a new PDMetadata with default XMP skeleton
    def self.create_with_xmp(document : Pdmodel::PDDocument) : PDMetadata
      meta = new(document)
      xmp = Xmpbox::XMPMetadata.create_xmp_metadata
      meta.xmp_metadata = xmp
      meta
    end
  end
end

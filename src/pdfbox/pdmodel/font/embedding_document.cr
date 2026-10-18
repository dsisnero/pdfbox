# Shared support for embedding fonts into a document.
#
# Apache PDFBox has a single PDDocument type. The Crystal port grew two: the real
# `Pdfbox::Pdmodel::Document` (returned by `Loader.load_pdf` and `Document.create`)
# and the legacy `Pdfbox::Pdmodel::PDDocument` stub. Font embedders accept either;
# the legacy document owns a `Cos::Document` that registers streams, while the real
# document has no stream registry, so its font streams are detached and picked up by
# the writer through the font descriptor.
require "../document"
require "../../cos"
require "../common/pdstream"

module Pdfbox::Pdmodel::Font
  alias EmbeddingDocument = Pdfbox::Pdmodel::Document | Pdfbox::Pdmodel::PDDocument

  module Embedding
    extend self

    # Creates an unfiltered font-file stream over the given data.
    # Java `new PDStream(document, input)`.
    def font_file_stream(doc : EmbeddingDocument, data : ::IO) : Pdfbox::Pdmodel::Common::PDStream
      case doc
      when Pdfbox::Pdmodel::PDDocument
        Pdfbox::Pdmodel::Common::PDStream.new(doc, data)
      else
        buffer = ::IO::Memory.new
        ::IO.copy(data, buffer)
        Pdfbox::Pdmodel::Common::PDStream.new(Pdfbox::Cos::Stream.new(data: buffer.to_slice))
      end
    end

    # Creates an empty stream that the caller writes into through
    # `create_output_stream(filter)` (used for the compressed Type 1 font file).
    # Java `new PDStream(document)`.
    def empty_stream(doc : EmbeddingDocument) : Pdfbox::Pdmodel::Common::PDStream
      case doc
      when Pdfbox::Pdmodel::PDDocument
        Pdfbox::Pdmodel::Common::PDStream.new(doc.document)
      else
        Pdfbox::Pdmodel::Common::PDStream.new(Pdfbox::Cos::Stream.new)
      end
    end
  end
end

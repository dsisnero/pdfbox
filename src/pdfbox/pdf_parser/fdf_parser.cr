require "./cos_parser"
require "../pdmodel/fdf"

module Pdfbox::Pdfparser
  class FDFParser < COSParser
    def initialize(source : Pdfbox::IO::RandomAccessRead)
      super(source)
    end

    def parse : Pdfbox::Pdmodel::Fdf::FDFDocument
      source.rewind
      header = read_line
      unless header.starts_with?("%FDF-")
        raise ::IO::Error.new("Error: Header doesn't contain versioninfo")
      end

      source.rewind
      content = String.new(source.read_all)
      Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(content)
    end
  end
end

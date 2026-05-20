# Loader for encryption tests
require "./pdmodel"
require "./pdf_parser/fdf_parser"
require "./pdf_parser/parser"
require "./io"

module Pdfbox
  module Loader
    def self.load_pdf(data : Bytes, password : String = "") : Pdmodel::Document
      source = Pdfbox::IO::RandomAccessReadBuffer.new(data)
      parser = Pdfbox::Pdfparser::Parser.new(source)
      parser.lenient = true
      document = parser.parse(password)
      # Attempt decryption for encrypted documents, including empty-password attempts.
      document.decrypt(password)
      # Store original bytes for incremental save support
      document.source_bytes = data
      document
    end

    def self.load_pdf(path : String, password : String = "") : Pdmodel::Document
      data = File.read(path).to_slice
      load_pdf(data, password)
    end

    def self.load_fdf(path : String) : Pdmodel::Fdf::FDFDocument
      File.open(path) do |file|
        load_fdf(file)
      end
    end

    def self.load_xfdf(path : String) : Pdmodel::Fdf::FDFDocument
      File.open(path) do |file|
        load_xfdf(file)
      end
    end

    def self.load_fdf(input : ::IO) : Pdmodel::Fdf::FDFDocument
      read_buffer = Pdfbox::IO::RandomAccessReadBuffer.new(input)
      parser = Pdfbox::Pdfparser::FDFParser.new(read_buffer)
      parser.parse
    ensure
      read_buffer.try(&.close)
    end

    def self.load_xfdf(input : ::IO) : Pdmodel::Fdf::FDFDocument
      Pdmodel::Fdf::FDFDocument.from_xfdf(input.gets_to_end)
    end
  end
end

# Loader for encryption tests
require "./pdmodel"
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
      document
    end

    def self.load_pdf(path : String, password : String = "") : Pdmodel::Document
      data = File.read(path).to_slice
      load_pdf(data, password)
    end
  end
end

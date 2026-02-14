# Loader placeholder for encryption tests
require "./pdmodel"

module Pdfbox
  module Loader
    def self.load_pdf(data : Bytes, password : String = "") : Pdmodel::Document
      Pdmodel::Document.new
    end

    def self.load_pdf(path : String, password : String = "") : Pdmodel::Document
      data = File.read(path).to_slice
      load_pdf(data, password)
    end
  end
end

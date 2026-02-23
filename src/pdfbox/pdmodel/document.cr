# PDDocument placeholder for encryption tests
require "./encryption"
require "../cos"

module Pdfbox::Pdmodel
  class PDDocument
    @access_permission = Encryption::AccessPermission.new
    @cos_document = Cos::Document.new

    def initialize(@data : Bytes, @password : String = "")
    end

    def document : Cos::Document
      @cos_document
    end

    def current_access_permission : Encryption::AccessPermission
      @access_permission
    end

    def close : Nil
      # nothing
    end
  end
end

# PDDocument placeholder for encryption tests
require "./encryption"

module Pdfbox::Pdmodel
  class PDDocument
    @access_permission = Encryption::AccessPermission.new

    def initialize(@data : Bytes, @password : String = "")
    end

    def current_access_permission : Encryption::AccessPermission
      @access_permission
    end

    def close : Nil
      # nothing
    end
  end
end

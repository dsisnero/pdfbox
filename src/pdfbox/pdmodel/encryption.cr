# Encryption types for PDFBox Crystal
require "../cos"

module Pdfbox::Pdmodel::Encryption
  # Basic view of access permission
  class AccessPermission
    def initialize(@owner_permission : Bool = true)
    end

    def owner_permission? : Bool
      @owner_permission
    end
  end

  class ProtectionPolicy
  end

  class StandardProtectionPolicy < ProtectionPolicy
    def initialize(@length : Int32 = 40)
    end

    def length : Int32
      @length
    end
  end

  class DecryptionMaterial
  end

  class StandardDecryptionMaterial < DecryptionMaterial
    def initialize(@password : String)
    end

    def password : String
      @password
    end
  end

  class PublicKeyDecryptionMaterial < DecryptionMaterial
    def initialize(@key_store : ::IO, @alias : String?, @password : String)
    end

    def key_store : ::IO
      @key_store
    end

    def alias : String?
      @alias
    end
  end

  class SecurityHandler
    def prepare_for_decryption(encryption : PDEncryption, document_id : Bytes?, material : DecryptionMaterial) : Nil
    end

    def current_access_permission : AccessPermission
      AccessPermission.new
    end

    def decrypt(obj : Pdfbox::Cos::Base?, _obj_num : Int64, _gen_num : Int64) : Pdfbox::Cos::Base?
      obj
    end

    def decrypt_stream(stream : Pdfbox::Cos::Stream, _obj_num : Int64, _gen_num : Int64) : Nil
    end
  end

  class StandardSecurityHandler < SecurityHandler
    FILTER = "Standard"

    def initialize(@policy : StandardProtectionPolicy = StandardProtectionPolicy.new)
      @access_permission = AccessPermission.new
    end

    def current_access_permission : AccessPermission
      @access_permission
    end
  end

  class SecurityHandlerFactory
    PROPERTY = "SecurityHandlerFactory"
    @@instance : SecurityHandlerFactory?

    private def initialize
      @name_to_handler = {
        StandardSecurityHandler::FILTER => StandardSecurityHandler,
      }
    end

    def self.instance : SecurityHandlerFactory
      @@instance ||= new
    end

    def new_security_handler_for_filter(name : String) : SecurityHandler?
      handler_class = @name_to_handler[name]
      handler_class.new if handler_class
    end
  end

  class PDEncryption
    @dictionary : Pdfbox::Cos::Dictionary
    property security_handler : SecurityHandler?

    def initialize(dictionary : Pdfbox::Cos::Dictionary? = nil)
      @dictionary = dictionary || Pdfbox::Cos::Dictionary.new
      filter_name = filter
      @security_handler = SecurityHandlerFactory.instance.new_security_handler_for_filter(filter_name)
    end

    def filter : String
      entry = @dictionary[Pdfbox::Cos::Name.new("Filter")]
      if entry.is_a?(Pdfbox::Cos::Name)
        entry.value
      else
        StandardSecurityHandler::FILTER
      end
    end

    def dictionary : Pdfbox::Cos::Dictionary
      @dictionary
    end
  end
end

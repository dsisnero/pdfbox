# Encryption-related stubs for PDFBox Crystal
# These are placeholders to mirror Apache PDFBox types.
module Pdfbox::Pdmodel::Encryption
  class AccessPermission
  end

  class ProtectionPolicy
  end

  class DecryptionMaterial
  end

  class StandardDecryptionMaterial < DecryptionMaterial
    def initialize(@password : String)
    end
  end

  class PublicKeyDecryptionMaterial < DecryptionMaterial
  end

  class PDEncryption
    property security_handler : SecurityHandler?
  end

  class SecurityHandler
    def decrypt(obj : Pdfbox::Cos::Base?, _obj_num : Int64, _gen_num : Int64) : Pdfbox::Cos::Base?
      obj
    end

    def decrypt_stream(stream : Pdfbox::Cos::Stream, _obj_num : Int64, _gen_num : Int64) : Nil
    end
  end
end

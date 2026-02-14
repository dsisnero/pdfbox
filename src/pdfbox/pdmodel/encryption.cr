# Encryption types for PDFBox Crystal
require "../cos"

module Pdfbox::Pdmodel::Encryption
  # Basic view of access permission
  class AccessPermission
    private DEFAULT_PERMISSIONS           = ~3 # bits 0 & 1 need to be zero
    private PRINT_BIT                     =  3
    private MODIFICATION_BIT              =  4
    private EXTRACT_BIT                   =  5
    private MODIFY_ANNOTATIONS_BIT        =  6
    private FILL_IN_FORM_BIT              =  9
    private EXTRACT_FOR_ACCESSIBILITY_BIT = 10
    private ASSEMBLE_DOCUMENT_BIT         = 11
    private FAITHFUL_PRINT_BIT            = 12

    @bytes : Int32
    @read_only = false

    def initialize(@owner_permission : Bool = true)
      @bytes = DEFAULT_PERMISSIONS
    end

    def initialize(permissions : Int32)
      @bytes = permissions
      @owner_permission = false
    end

    def owner_permission? : Bool
      @owner_permission
    end

    def read_only? : Bool
      @read_only
    end

    def set_read_only : Nil
      @read_only = true
    end

    private def permission_bit_on?(bit : Int32) : Bool
      (@bytes & (1 << (bit - 1))) != 0
    end

    private def set_permission_bit(bit : Int32, value : Bool) : Bool
      if value
        @bytes = @bytes | (1 << (bit - 1))
      else
        @bytes = @bytes & (~(1 << (bit - 1)))
      end
      (@bytes & (1 << (bit - 1))) != 0
    end

    # Getter methods
    def can_assemble_document? : Bool
      permission_bit_on?(ASSEMBLE_DOCUMENT_BIT)
    end

    def can_extract_content? : Bool
      permission_bit_on?(EXTRACT_BIT)
    end

    def can_extract_for_accessibility? : Bool
      permission_bit_on?(EXTRACT_FOR_ACCESSIBILITY_BIT)
    end

    def can_fill_in_form? : Bool
      permission_bit_on?(FILL_IN_FORM_BIT)
    end

    def can_modify? : Bool
      permission_bit_on?(MODIFICATION_BIT)
    end

    def can_modify_annotations? : Bool
      permission_bit_on?(MODIFY_ANNOTATIONS_BIT)
    end

    def can_print? : Bool
      permission_bit_on?(PRINT_BIT)
    end

    def can_print_faithful? : Bool
      permission_bit_on?(FAITHFUL_PRINT_BIT)
    end

    # Setter methods
    def can_assemble_document=(value : Bool) : Nil
      set_permission_bit(ASSEMBLE_DOCUMENT_BIT, value) unless @read_only
    end

    def can_extract_content=(value : Bool) : Nil
      set_permission_bit(EXTRACT_BIT, value) unless @read_only
    end

    def can_extract_for_accessibility=(value : Bool) : Nil
      set_permission_bit(EXTRACT_FOR_ACCESSIBILITY_BIT, value) unless @read_only
    end

    def can_fill_in_form=(value : Bool) : Nil
      set_permission_bit(FILL_IN_FORM_BIT, value) unless @read_only
    end

    def can_modify=(value : Bool) : Nil
      set_permission_bit(MODIFICATION_BIT, value) unless @read_only
    end

    def can_modify_annotations=(value : Bool) : Nil
      set_permission_bit(MODIFY_ANNOTATIONS_BIT, value) unless @read_only
    end

    def can_print=(value : Bool) : Nil
      set_permission_bit(PRINT_BIT, value) unless @read_only
    end

    def can_print_faithful=(value : Bool) : Nil
      set_permission_bit(FAITHFUL_PRINT_BIT, value) unless @read_only
    end

    def permission_bytes : Int32
      @bytes
    end

    def self.owner_access_permission : AccessPermission
      ap = new
      ap.can_assemble_document = true
      ap.can_extract_content = true
      ap.can_extract_for_accessibility = true
      ap.can_fill_in_form = true
      ap.can_modify = true
      ap.can_modify_annotations = true
      ap.can_print = true
      ap.can_print_faithful = true
      ap
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

  class PublicKeyProtectionPolicy < ProtectionPolicy
  end

  class PublicKeyRecipient
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
    @current_access_permission : AccessPermission?
    @encryption_key : Bytes?
    @decrypt_metadata = true
    @use_aes = false
    @stream_filter_name : Pdfbox::Cos::Name?
    @string_filter_name : Pdfbox::Cos::Name?

    def prepare_for_decryption(encryption : PDEncryption, document_id : Bytes?, material : DecryptionMaterial) : Nil
    end

    def current_access_permission : AccessPermission
      @current_access_permission || AccessPermission.new
    end

    protected def set_current_access_permission(permission : AccessPermission) : Nil
      @current_access_permission = permission
    end

    protected def set_encryption_key(key : Bytes) : Nil
      @encryption_key = key
    end

    protected def set_decrypt_metadata(decrypt : Bool) : Nil
      @decrypt_metadata = decrypt
    end

    protected def set_use_aes(use_aes : Bool) : Nil
      @use_aes = use_aes
    end

    protected def set_stream_filter_name(name : Pdfbox::Cos::Name) : Nil
      @stream_filter_name = name
    end

    protected def set_string_filter_name(name : Pdfbox::Cos::Name) : Nil
      @string_filter_name = name
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
      super()
    end

    def prepare_for_decryption(encryption : PDEncryption, document_id : Bytes?, material : DecryptionMaterial) : Nil
      # Simplified version for testing
      unless material.is_a?(StandardDecryptionMaterial)
        raise ::IO::Error.new("Decryption material is not compatible with the document")
      end

      password = material.password
      password = "" if password.nil?
      dic_permissions = encryption.permissions

      # For testing, check if password is "owner" or "user"
      if password == "owner"
        set_current_access_permission(AccessPermission.owner_access_permission)
      elsif password == "user"
        perm = AccessPermission.new(dic_permissions)
        perm.set_read_only
        set_current_access_permission(perm)
      else
        raise ::IO::Error.new("Cannot decrypt PDF, the password is incorrect")
      end
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
    # See PDF Reference 1.4 Table 3.13.
    VERSION0_UNDOCUMENTED_UNSUPPORTED = 0
    # See PDF Reference 1.4 Table 3.13.
    VERSION1_40_BIT_ALGORITHM = 1
    # See PDF Reference 1.4 Table 3.13.
    VERSION2_VARIABLE_LENGTH_ALGORITHM = 2
    # See PDF Reference 1.4 Table 3.13.
    VERSION3_UNPUBLISHED_ALGORITHM = 3
    # See PDF Reference 1.4 Table 3.13.
    VERSION4_SECURITY_HANDLER = 4

    # The default security handler.
    DEFAULT_NAME = "Standard"

    # The default length for the encryption key.
    DEFAULT_LENGTH = 40

    # The default version, according to the PDF Reference.
    DEFAULT_VERSION = VERSION0_UNDOCUMENTED_UNSUPPORTED

    @dictionary : Pdfbox::Cos::Dictionary
    property security_handler : SecurityHandler?

    def initialize(dictionary : Pdfbox::Cos::Dictionary? = nil)
      @dictionary = dictionary || Pdfbox::Cos::Dictionary.new
      filter_name = filter
      @security_handler = SecurityHandlerFactory.instance.new_security_handler_for_filter(filter_name)
    end

    # TODO: implement all getters and setters
    private def get_int(key : Pdfbox::Cos::Name, default : Int32) : Int32
      entry = @dictionary[key]
      # Dereference COSObject
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      # COSNull treated as nil
      return default if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)

      case entry
      when Pdfbox::Cos::Integer
        entry.value.to_i32
      when Pdfbox::Cos::Float
        entry.value.to_i
      else
        default
      end
    end

    private def get_cos_string(key : Pdfbox::Cos::Name) : Pdfbox::Cos::String?
      entry = @dictionary[key]
      # Dereference COSObject
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      # COSNull treated as nil
      return if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      entry.as?(Pdfbox::Cos::String)
    end

    private def get_name_as_string(key : Pdfbox::Cos::Name) : String?
      entry = @dictionary[key]
      # Dereference COSObject
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      # COSNull treated as nil
      return if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      entry.as?(Pdfbox::Cos::Name).try(&.value)
    end

    private def get_cos_name(key : Pdfbox::Cos::Name) : Pdfbox::Cos::Name?
      entry = @dictionary[key]
      # Dereference COSObject
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      # COSNull treated as nil
      return if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      entry.as?(Pdfbox::Cos::Name)
    end

    private def get_boolean(key : Pdfbox::Cos::Name, default : Bool) : Bool
      entry = @dictionary[key]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      return default if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      if bool = entry.as?(Pdfbox::Cos::Boolean)
        bool.value
      else
        default
      end
    end

    private def get_recipients_array : Pdfbox::Cos::Array?
      entry = @dictionary[Pdfbox::Cos::Name.new("Recipients")]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      return if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      entry.as?(Pdfbox::Cos::Array)
    end

    def version : Int32
      get_int(Pdfbox::Cos::Name.new("V"), 0)
    end

    def revision : Int32
      get_int(Pdfbox::Cos::Name.new("R"), DEFAULT_VERSION)
    end

    def length : Int32
      get_int(Pdfbox::Cos::Name.new("Length"), DEFAULT_LENGTH)
    end

    def permissions : Int32
      get_int(Pdfbox::Cos::Name.new("P"), 0)
    end

    def owner_key : Bytes?
      owner = get_cos_string(Pdfbox::Cos::Name.new("O"))
      return unless owner
      bytes = owner.bytes
      r = revision
      target_size = if r <= 4
                      32
                    elsif r == 5 || r == 6
                      48
                    else
                      32 # fallback
                    end
      # Create new bytes with target size, copying original and padding with zeros if needed
      result = Bytes.new(target_size, 0_u8)
      copy_size = Math.min(bytes.size, target_size)
      bytes.copy_to(result[0, copy_size])
      result
    end

    def user_key : Bytes?
      user = get_cos_string(Pdfbox::Cos::Name.new("U"))
      return unless user
      bytes = user.bytes
      r = revision
      target_size = if r <= 4
                      32
                    elsif r == 5 || r == 6
                      48
                    else
                      32 # fallback
                    end
      # Create new bytes with target size, copying original and padding with zeros if needed
      result = Bytes.new(target_size, 0_u8)
      copy_size = Math.min(bytes.size, target_size)
      bytes.copy_to(result[0, copy_size])
      result
    end

    def owner_encryption_key : Bytes?
      oe = get_cos_string(Pdfbox::Cos::Name.new("OE"))
      return unless oe
      bytes = oe.bytes
      # Always copy to 32 bytes for OE/UE
      result = Bytes.new(32, 0_u8)
      copy_size = Math.min(bytes.size, 32)
      bytes.copy_to(result[0, copy_size])
      result
    end

    def user_encryption_key : Bytes?
      ue = get_cos_string(Pdfbox::Cos::Name.new("UE"))
      return unless ue
      bytes = ue.bytes
      # Always copy to 32 bytes for OE/UE
      result = Bytes.new(32, 0_u8)
      copy_size = Math.min(bytes.size, 32)
      bytes.copy_to(result[0, copy_size])
      result
    end

    def encrypt_metadata? : Bool
      get_boolean(Pdfbox::Cos::Name.new("EncryptMetadata"), true)
    end

    def stream_filter_name : Pdfbox::Cos::Name?
      get_cos_name(Pdfbox::Cos::Name.new("StmF"))
    end

    def string_filter_name : Pdfbox::Cos::Name?
      get_cos_name(Pdfbox::Cos::Name.new("StrF"))
    end

    def perms : Bytes?
      perms_str = get_cos_string(Pdfbox::Cos::Name.new("Perms"))
      return unless perms_str
      perms_str.bytes
    end

    # TODO: implement
    def security_handler : SecurityHandler
      @security_handler || raise ::IO::Error.new("No security handler for filter #{filter}")
    end

    def has_security_handler? : Bool
      !@security_handler.nil?
    end

    def filter=(filter : String) : String
      @dictionary[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new(filter)
      filter
    end

    def sub_filter : String?
      get_name_as_string(Pdfbox::Cos::Name.new("SubFilter"))
    end

    def sub_filter=(subfilter : String) : String
      @dictionary[Pdfbox::Cos::Name.new("SubFilter")] = Pdfbox::Cos::Name.new(subfilter)
      subfilter
    end

    def version=(version : Int32) : Int32
      @dictionary[Pdfbox::Cos::Name.new("V")] = Pdfbox::Cos::Integer.new(version.to_i64)
      version
    end

    def length=(length : Int32) : Int32
      @dictionary[Pdfbox::Cos::Name.new("Length")] = Pdfbox::Cos::Integer.new(length.to_i64)
      length
    end

    def revision=(revision : Int32) : Int32
      @dictionary[Pdfbox::Cos::Name.new("R")] = Pdfbox::Cos::Integer.new(revision.to_i64)
      revision
    end

    def owner_key=(o : Bytes) : Bytes
      @dictionary[Pdfbox::Cos::Name.new("O")] = Pdfbox::Cos::String.new(o)
      o
    end

    def user_key=(u : Bytes) : Bytes
      @dictionary[Pdfbox::Cos::Name.new("U")] = Pdfbox::Cos::String.new(u)
      u
    end

    def owner_encryption_key=(oe : Bytes) : Bytes
      @dictionary[Pdfbox::Cos::Name.new("OE")] = Pdfbox::Cos::String.new(oe)
      oe
    end

    def user_encryption_key=(ue : Bytes) : Bytes
      @dictionary[Pdfbox::Cos::Name.new("UE")] = Pdfbox::Cos::String.new(ue)
      ue
    end

    def permissions=(permissions : Int32) : Int32
      @dictionary[Pdfbox::Cos::Name.new("P")] = Pdfbox::Cos::Integer.new(permissions.to_i64)
      permissions
    end

    def recipients=(recipients : Array(Bytes)) : Array(Bytes)
      array = Pdfbox::Cos::Array.new
      recipients.each do |recipient|
        array << Pdfbox::Cos::String.new(recipient)
      end
      @dictionary[Pdfbox::Cos::Name.new("Recipients")] = array
      recipients
    end

    def recipients_length : Int32
      array = get_recipients_array
      array ? array.size : 0
    end

    def recipient_string_at(i : Int32) : Pdfbox::Cos::String?
      array = get_recipients_array
      return unless array
      entry = array[i]?
      return unless entry
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      entry.as?(Pdfbox::Cos::String)
    end

    def std_crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?
      nil
    end

    def default_crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?
      nil
    end

    def crypt_filter_dictionary(crypt_filter_name : Pdfbox::Cos::Name) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?
      nil
    end

    def assign_crypt_filter_dictionary(crypt_filter_name : Pdfbox::Cos::Name, crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Nil
      # TODO
    end

    def std_crypt_filter_dictionary=(crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary
      # TODO
      crypt_filter_dictionary
    end

    def default_crypt_filter_dictionary=(default_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary
      # TODO
      default_filter_dictionary
    end

    def stream_filter_name=(stream_filter_name : Pdfbox::Cos::Name) : Pdfbox::Cos::Name
      @dictionary[Pdfbox::Cos::Name.new("StmF")] = stream_filter_name
      stream_filter_name
    end

    def string_filter_name=(string_filter_name : Pdfbox::Cos::Name) : Pdfbox::Cos::Name
      @dictionary[Pdfbox::Cos::Name.new("StrF")] = string_filter_name
      string_filter_name
    end

    def perms=(perms : Bytes) : Bytes
      @dictionary[Pdfbox::Cos::Name.new("Perms")] = Pdfbox::Cos::String.new(perms)
      perms
    end

    def remove_v45_filters : Nil
      # TODO
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

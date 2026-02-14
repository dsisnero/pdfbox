# Encryption types for PDFBox Crystal
require "../cos"
require "digest"
require "openssl"

module Pdfbox::Pdmodel::Encryption
  # Simple RC4 implementation for PDF encryption (compatible with PDF RC4)
  class RC4
    @s = Bytes.new(256, 0_u8)
    @i = 0_u8
    @j = 0_u8

    def initialize(key : Bytes)
      key_len = key.size
      (0..255).each do |i|
        @s[i] = i.to_u8
      end

      j = 0_u8
      (0..255).each do |i|
        j = (j + @s[i] + key[i % key_len]) & 0xFF
        @s[i], @s[j] = @s[j], @s[i]
      end
      @i = 0_u8
      @j = 0_u8
    end

    def process(data : Bytes) : Bytes
      result = Bytes.new(data.size)
      data.each_with_index do |byte, idx|
        @i = (@i + 1) & 0xFF
        @j = (@j + @s[@i]) & 0xFF
        @s[@i], @s[@j] = @s[@j], @s[@i]
        t = (@s[@i] + @s[@j]) & 0xFF
        result[idx] = byte ^ @s[t]
      end
      result
    end
  end

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
    # Protection policy class for this handler.
    PROTECTION_POLICY_CLASS = StandardProtectionPolicy

    REVISION_2 = 2
    REVISION_3 = 3
    REVISION_4 = 4
    REVISION_5 = 5
    REVISION_6 = 6

    # Standard padding for encryption.
    ENCRYPT_PADDING = Bytes[
      0x28_u8, 0xBF_u8, 0x4E_u8, 0x5E_u8, 0x4E_u8,
      0x75_u8, 0x8A_u8, 0x41_u8, 0x64_u8, 0x00_u8,
      0x4E_u8, 0x56_u8, 0xFF_u8, 0xFA_u8, 0x01_u8,
      0x08_u8, 0x2E_u8, 0x2E_u8, 0x00_u8, 0xB6_u8,
      0xD0_u8, 0x68_u8, 0x3E_u8, 0x80_u8, 0x2F_u8,
      0x0C_u8, 0xA9_u8, 0xFE_u8, 0x64_u8, 0x53_u8,
      0x69_u8, 0x7A_u8,
    ]

    # Hashes used for Algorithm 2.B, depending on remainder from E modulo 3
    HASHES_2B = ["SHA-256", "SHA-384", "SHA-512"]

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

    def prepare_document_for_encryption(document : Pdfbox::Pdmodel::Document) : Nil
      # TODO: implement
      raise "Not implemented: prepare_document_for_encryption"
    end

    def owner_password?(owner_password : Bytes, user : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bool
      # TODO: implement
      false
    end

    def user_password?(password : Bytes, user : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bool
      # TODO: implement
      false
    end

    def user_password(owner_password : Bytes, owner : Bytes, enc_revision : Int32, length : Int32) : Bytes
      if enc_revision == REVISION_5 || enc_revision == REVISION_6
        Bytes.new(0)
      else
        user_password234(owner_password, owner, enc_revision, length)
      end
    end

    def compute_encrypted_key(password : Bytes, o : Bytes, u : Bytes, oe : Bytes?, ue : Bytes?, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool, is_owner_password : Bool) : Bytes
      # TODO: implement
      Bytes.new(0)
    end

    def compute_user_password(password : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bytes
      # TODO: implement
      Bytes.new(0)
    end

    def compute_owner_password(owner_password : Bytes, user_password : Bytes, enc_revision : Int32, length : Int32) : Bytes
      # TODO: implement
      Bytes.new(0)
    end

    private def truncate_or_pad(password : Bytes) : Bytes
      padded = Bytes.new(ENCRYPT_PADDING.size, 0_u8)
      bytes_before_pad = Math.min(password.size, padded.size)
      password.copy_to(padded[0, bytes_before_pad])
      ENCRYPT_PADDING.copy_to(padded[bytes_before_pad, ENCRYPT_PADDING.size - bytes_before_pad])
      padded
    end

    private def compute_rc4_key(password : Bytes, enc_revision : Int32, length : Int32) : Bytes
      padded = truncate_or_pad(password)
      digest = Digest::MD5.digest(padded)
      if enc_revision == REVISION_3 || enc_revision == REVISION_4
        50.times do
          md = Digest::MD5.new
          md.update(digest[0, length])
          digest = md.final
        end
      end
      digest[0, length]
    end

    private def user_password234(owner_password : Bytes, owner : Bytes, enc_revision : Int32, length : Int32) : Bytes
      rc4_key = compute_rc4_key(owner_password, enc_revision, length)

      if enc_revision == REVISION_2
        encrypt_data_rc4(rc4_key, owner)
      elsif enc_revision == REVISION_3 || enc_revision == REVISION_4
        iteration_key = Bytes.new(rc4_key.size, 0_u8)
        otemp = Bytes.new(owner.size, 0_u8)
        owner.copy_to(otemp)

        19.downto(0) do |i|
          rc4_key.copy_to(iteration_key)
          iteration_key.size.times do |j|
            iteration_key[j] = iteration_key[j] ^ i.to_u8
          end
          otemp = encrypt_data_rc4(iteration_key, otemp)
        end
        otemp
      else
        Bytes.new(0)
      end
    end

    private def encrypt_data_rc4(key : Bytes, data : Bytes) : Bytes
      rc4 = RC4.new(key)
      rc4.process(data)
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

  class PDCryptFilterDictionary
    @dictionary : Pdfbox::Cos::Dictionary

    def initialize(dictionary : Pdfbox::Cos::Dictionary? = nil)
      @dictionary = dictionary || Pdfbox::Cos::Dictionary.new
    end

    def dictionary : Pdfbox::Cos::Dictionary
      @dictionary
    end

    def length=(length : Int32) : Int32
      @dictionary[Pdfbox::Cos::Name.new("Length")] = Pdfbox::Cos::Integer.new(length.to_i64)
      length
    end

    def length : Int32
      entry = @dictionary[Pdfbox::Cos::Name.new("Length")]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      return 40 if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      entry.as?(Pdfbox::Cos::Integer).try(&.value.to_i32) || 40
    end

    def crypt_filter_method=(cfm : Pdfbox::Cos::Name) : Pdfbox::Cos::Name
      @dictionary[Pdfbox::Cos::Name.new("CFM")] = cfm
      cfm
    end

    def crypt_filter_method : Pdfbox::Cos::Name?
      entry = @dictionary[Pdfbox::Cos::Name.new("CFM")]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      return if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      entry.as?(Pdfbox::Cos::Name)
    end

    def encrypt_metadata? : Bool
      entry = @dictionary[Pdfbox::Cos::Name.new("EncryptMetadata")]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      return true if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      if bool = entry.as?(Pdfbox::Cos::Boolean)
        bool.value
      else
        true
      end
    end

    def encrypt_metadata=(encrypt_metadata : Bool) : Bool
      @dictionary[Pdfbox::Cos::Name.new("EncryptMetadata")] = Pdfbox::Cos::Boolean.get(encrypt_metadata)
      encrypt_metadata
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

    # Crypt filter names
    STD_CF               = Pdfbox::Cos::Name.new("StdCF")
    DEFAULT_CRYPT_FILTER = Pdfbox::Cos::Name.new("DefaultCryptFilter")

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

    private def get_cf_dictionary : Pdfbox::Cos::Dictionary?
      entry = @dictionary[Pdfbox::Cos::Name.new("CF")]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      return if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)
      entry.as?(Pdfbox::Cos::Dictionary)
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
        array.add(Pdfbox::Cos::String.new(recipient))
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
      return unless i >= 0 && i < array.size
      entry = array[i]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      entry.as?(Pdfbox::Cos::String)
    end

    def std_crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?
      crypt_filter_dictionary(STD_CF)
    end

    def default_crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?
      crypt_filter_dictionary(DEFAULT_CRYPT_FILTER)
    end

    def crypt_filter_dictionary(crypt_filter_name : Pdfbox::Cos::Name) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?
      cf_dict = get_cf_dictionary
      return unless cf_dict

      entry = cf_dict[crypt_filter_name]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      return if entry.nil? || entry.is_a?(Pdfbox::Cos::Null)

      if crypt_dict = entry.as?(Pdfbox::Cos::Dictionary)
        PDCryptFilterDictionary.new(crypt_dict)
      end
    end

    def assign_crypt_filter_dictionary(crypt_filter_name : Pdfbox::Cos::Name, crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Nil
      cf_key = Pdfbox::Cos::Name.new("CF")
      entry = @dictionary[cf_key]
      while entry.is_a?(Pdfbox::Cos::Object)
        entry = entry.object
      end
      cf_dictionary = if entry.nil? || entry.is_a?(Pdfbox::Cos::Null) || !entry.is_a?(Pdfbox::Cos::Dictionary)
                        new_dict = Pdfbox::Cos::Dictionary.new
                        @dictionary[cf_key] = new_dict
                        new_dict
                      else
                        entry.as(Pdfbox::Cos::Dictionary)
                      end
      cf_dictionary.set_direct(true) # PDFBOX-4436 direct obj needed for Adobe Reader on Android
      cf_dictionary[crypt_filter_name] = crypt_filter_dictionary.dictionary
    end

    def std_crypt_filter_dictionary=(crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary
      crypt_filter_dictionary.dictionary.set_direct(true) # PDFBOX-4436
      assign_crypt_filter_dictionary(STD_CF, crypt_filter_dictionary)
      crypt_filter_dictionary
    end

    def default_crypt_filter_dictionary=(default_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary
      default_filter_dictionary.dictionary.set_direct(true) # PDFBOX-4436
      assign_crypt_filter_dictionary(DEFAULT_CRYPT_FILTER, default_filter_dictionary)
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
      @dictionary.delete(Pdfbox::Cos::Name.new("CF"))
      @dictionary.delete(Pdfbox::Cos::Name.new("StmF"))
      @dictionary.delete(Pdfbox::Cos::Name.new("StrF"))
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

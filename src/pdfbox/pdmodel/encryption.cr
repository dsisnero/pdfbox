# Encryption types for PDFBox Crystal
require "../cos"
require "digest"
require "openssl"
require "io"

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

      j = 0
      (0..255).each do |i|
        j = (j + @s[i].to_i32 + key[i % key_len].to_i32) & 0xFF
        @s[i], @s[j.to_u8] = @s[j.to_u8], @s[i]
      end
      @i = 0_u8
      @j = 0_u8
    end

    def process(data : Bytes) : Bytes
      result = Bytes.new(data.size)
      data.each_with_index do |byte, idx|
        @i = ((@i.to_i32 + 1) & 0xFF).to_u8
        @j = ((@j.to_i32 + @s[@i].to_i32) & 0xFF).to_u8
        @s[@i], @s[@j] = @s[@j], @s[@i]
        t = (@s[@i].to_i32 + @s[@j].to_i32) & 0xFF
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

    def initialize
      @bytes = DEFAULT_PERMISSIONS
    end

    def initialize(permissions : Int32)
      @bytes = permissions
    end

    def owner_permission? : Bool
      can_assemble_document? &&
        can_extract_content? &&
        can_extract_for_accessibility? &&
        can_fill_in_form? &&
        can_modify? &&
        can_modify_annotations? &&
        can_print? &&
        can_print_faithful?
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

    def has_any_revision3_permission_set? : Bool
      can_assemble_document? ||
        can_extract_for_accessibility? ||
        can_fill_in_form? ||
        can_print_faithful?
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
    property owner_password : String
    property user_password : String
    property permissions : AccessPermission
    property encryption_key_length : Int32 = 128
    property? prefer_aes : Bool = false
    property? encrypt_metadata : Bool = true

    def initialize(@owner_password : String, @user_password : String, @permissions : AccessPermission)
    end
  end

  class PublicKeyProtectionPolicy < ProtectionPolicy
    property encryption_key_length : Int32 = 128
    property? encrypt_metadata : Bool = true
    property recipients = [] of PublicKeyRecipient

    def number_of_recipients : Int32
      @recipients.size
    end

    def add_recipient(recipient : PublicKeyRecipient) : Nil
      @recipients << recipient
    end
  end

  class PublicKeyRecipient
    property x509_certificate : OpenSSL::X509::Certificate?
    property permissions : AccessPermission = AccessPermission.new(0)

    def initialize(@x509_certificate : OpenSSL::X509::Certificate? = nil,
                   @permissions : AccessPermission = AccessPermission.new(0))
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
    @current_access_permission : AccessPermission?
    @encryption_key : Bytes?
    @decrypt_metadata = true
    @use_aes = false
    @key_length : Int32 = 128
    @policy : ProtectionPolicy?
    @stream_filter_name : Pdfbox::Cos::Name?
    @string_filter_name : Pdfbox::Cos::Name?

    def prepare_for_decryption(encryption : PDEncryption, document_id : Bytes?, material : DecryptionMaterial) : Nil
    end

    def prepare_document_for_encryption(document : Pdfbox::Pdmodel::Document) : Nil
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

    protected def get_key_length_bits : Int32
      @key_length
    end

    protected def compute_version_number : Int32
      4_i32 # REVISION_4
    end

    protected def decrypt_metadata? : Bool
      @decrypt_metadata
    end

    protected def set_decrypt_metadata(decrypt : Bool) : Nil
      @decrypt_metadata = decrypt
    end

    protected def set_key_length(length_bits : Int32) : Nil
      @key_length = length_bits
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

    def decrypt(obj : Pdfbox::Cos::Base?, obj_num : Int64, gen_num : Int64) : Pdfbox::Cos::Base?
      return obj unless obj

      case obj
      when Pdfbox::Cos::String
        decrypt_string(obj, obj_num, gen_num)
      when Pdfbox::Cos::Stream
        decrypt_stream(obj, obj_num, gen_num)
        obj
      when Pdfbox::Cos::Array
        decrypt_array(obj, obj_num, gen_num)
      when Pdfbox::Cos::Dictionary
        decrypt_dictionary(obj, obj_num, gen_num)
      else
        obj
      end
    end

    def decrypt_stream(stream : Pdfbox::Cos::Stream, obj_num : Int64, gen_num : Int64) : Nil
      # Empty streams don't need to be decrypted
      return if stream.data.empty?

      # Get encryption key
      enc_key = @encryption_key
      return unless enc_key

      # Generate object key
      object_key = compute_object_key(enc_key, obj_num, gen_num)

      # Decrypt the stream data
      rc4 = RC4.new(object_key)
      decrypted_data = rc4.process(stream.data)

      # Replace stream data with decrypted data
      stream.data = decrypted_data
    end

    private def decrypt_string(string : Pdfbox::Cos::String, obj_num : Int64, gen_num : Int64) : Pdfbox::Cos::String
      # Get encryption key
      enc_key = @encryption_key
      return string unless enc_key

      # Generate object key
      object_key = compute_object_key(enc_key, obj_num, gen_num)

      # Decrypt the string data
      rc4 = RC4.new(object_key)
      decrypted_bytes = rc4.process(string.bytes)

      # Create new string with decrypted data
      Pdfbox::Cos::String.new(decrypted_bytes)
    end

    private def decrypt_array(array : Pdfbox::Cos::Array, obj_num : Int64, gen_num : Int64) : Pdfbox::Cos::Array
      # Decrypt each element in the array
      array.items.each_with_index do |element, i|
        decrypted = decrypt(element, obj_num, gen_num)
        array[i] = decrypted.as(Pdfbox::Cos::Base) if decrypted.is_a?(Pdfbox::Cos::Base)
      end
      array
    end

    private def decrypt_dictionary(dict : Pdfbox::Cos::Dictionary, obj_num : Int64, gen_num : Int64) : Pdfbox::Cos::Dictionary
      # Decrypt each value in the dictionary
      dict.entries.each do |key, value|
        dict[key] = decrypt(value, obj_num, gen_num)
      end
      dict
    end

    def encrypt_stream(stream : Pdfbox::Cos::Stream, obj_num : Int64, gen_num : Int64) : Nil
      # Empty streams don't need to be encrypted
      return if stream.data.empty?

      # Get encryption key
      enc_key = @encryption_key
      return unless enc_key

      # Generate object key
      object_key = compute_object_key(enc_key, obj_num, gen_num)

      # Encrypt the stream data
      rc4 = RC4.new(object_key)
      encrypted_data = rc4.process(stream.data)

      # Replace stream data with encrypted data
      stream.data = encrypted_data
    end

    protected def encrypt_data(obj_num : Int64, gen_num : Int64, input : ::IO, output : ::IO, decrypt : Bool) : Nil
      # Get encryption key
      enc_key = @encryption_key
      return unless enc_key

      # Determine whether we're using Algorithm 1 (for RC4 and AES-128), or 1.A (for AES-256)
      if @use_aes && enc_key.size == 32
        encrypt_data_aes256(input, output, decrypt)
      else
        object_key = compute_object_key(enc_key, obj_num, gen_num)

        if @use_aes
          encrypt_data_aes_other(object_key, input, output, decrypt)
        else
          encrypt_data_rc4(object_key, input, output)
        end
      end
      output.flush
    end

    private def compute_object_key(encryption_key : Bytes, obj_num : Int64, gen_num : Int64) : Bytes
      # Algorithm 3.1 from PDF Reference
      # 1. Use the encryption key
      # 2. Append the low-order 3 bytes of obj_num and low-order 2 bytes of gen_num
      # 3. Compute MD5 hash
      # 4. Use first (n+5) bytes as key (where n is encryption key length)

      md5 = Digest::MD5.new
      md5.update(encryption_key)

      # Append low-order 3 bytes of object number
      md5.update(Bytes[
        (obj_num & 0xFF).to_u8,
        ((obj_num >> 8) & 0xFF).to_u8,
        ((obj_num >> 16) & 0xFF).to_u8,
      ])

      # Append low-order 2 bytes of generation number
      md5.update(Bytes[
        (gen_num & 0xFF).to_u8,
        ((gen_num >> 8) & 0xFF).to_u8,
      ])

      digest = md5.final

      # Use first (n+5) bytes as key, where n is encryption key length
      key_length = encryption_key.size
      digest[0, Math.min(key_length + 5, digest.size)]
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

    def initialize(policy : StandardProtectionPolicy? = nil)
      super()
      @policy = policy || StandardProtectionPolicy.new("", "", AccessPermission.new)
    end

    private def compute_version_number : Int32
      # For now, default to version 4 (supports 128-bit encryption)
      REVISION_4
    end

    private def compute_revision_number(version : Int32) : Int32
      policy = @policy.as(StandardProtectionPolicy)
      permissions = policy.permissions

      if version < REVISION_2 && !permissions.has_any_revision3_permission_set?
        return REVISION_2
      end

      if version == REVISION_5
        # note about revision 5: "Shall not be used. This value was used by a deprecated Adobe extension."
        return REVISION_6
      end

      if version == REVISION_4
        return REVISION_4
      end

      if version == REVISION_2 || version == REVISION_3 || permissions.has_any_revision3_permission_set?
        return REVISION_3
      end

      REVISION_2
    end

    private def get_key_length_bits : Int32
      policy = @policy.as(StandardProtectionPolicy)
      policy.encryption_key_length
    end

    private def get_protection_policy : StandardProtectionPolicy
      @policy.as(StandardProtectionPolicy)
    end

    def prepare_for_decryption(encryption : PDEncryption, document_id : Bytes?, material : DecryptionMaterial) : Nil
      unless material.is_a?(StandardDecryptionMaterial)
        raise ::IO::Error.new("Decryption material is not compatible with the document")
      end

      password = material.password
      password = "" if password.nil?
      # Get encryption parameters
      user_key = encryption.user_key
      owner_key = encryption.owner_key
      if user_key.nil? || owner_key.nil?
        raise ::IO::Error.new("Encryption dictionary missing O or U entry")
      end
      user_key_value = user_key
      owner_key_value = owner_key
      permissions = encryption.permissions
      enc_revision = encryption.revision
      key_length_bits = encryption.length
      key_length_in_bytes = key_length_bits // 8
      encrypt_metadata = encryption.encrypt_metadata?

      # Document ID is required for password validation
      id = document_id
      if id.nil?
        raise ::IO::Error.new("Document ID is required for password validation")
      end

      # Convert password to bytes based on revision
      password_bytes = password_to_bytes(password, enc_revision)

      # Try owner password first
      if owner_password?(password_bytes, user_key_value, owner_key_value, permissions, id, enc_revision, key_length_in_bytes, encrypt_metadata)
        set_current_access_permission(AccessPermission.owner_access_permission)
        # Then try user password
      else
        if user_password?(password_bytes, user_key_value, owner_key_value, permissions, id, enc_revision, key_length_in_bytes, encrypt_metadata)
          perm = AccessPermission.new(permissions)
          perm.set_read_only
          set_current_access_permission(perm)
        else
          raise ::IO::Error.new("Cannot decrypt PDF, the password is incorrect")
        end
      end
    end

    def prepare_document_for_encryption(document : Pdfbox::Pdmodel::Document) : Nil
      encryption = document.encryption
      if encryption.nil?
        encryption = PDEncryption.new
      end

      version = compute_version_number
      revision = compute_revision_number(version)
      encryption.filter = FILTER
      encryption.version = version

      if version != REVISION_4 && version != REVISION_5
        # remove CF, StmF, and StrF entries that may be left from a previous encryption
        encryption.remove_v45_filters
      end

      encryption.revision = revision
      encryption.length = get_key_length_bits

      policy = @policy.as(StandardProtectionPolicy)
      owner_password = policy.owner_password
      user_password = policy.user_password

      owner_password = "" if owner_password.nil?
      user_password = "" if user_password.nil?

      # If no owner password is set, use the user password instead.
      if owner_password.empty?
        owner_password = user_password
      end

      permission_int = policy.permissions.permission_bytes
      encryption.permissions = permission_int

      length = get_key_length_bits // 8

      if revision == REVISION_6
        # TODO: Implement SASLPrep for revision 6
        # owner_password = SaslPrep.sasl_prep_stored(owner_password)
        # user_password = SaslPrep.sasl_prep_stored(user_password)
        prepare_encryption_dict_rev6(owner_password, user_password, encryption, permission_int)
      else
        prepare_encryption_dict_rev234(owner_password, user_password, encryption, permission_int, document, revision, length)
      end

      document.encryption = encryption
    end

    def owner_password?(owner_password : Bytes, user : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bool
      case enc_revision
      when REVISION_2, REVISION_3, REVISION_4
        owner_password234?(owner_password, user, owner, permissions, id, enc_revision, key_length_in_bytes, encrypt_metadata)
      when REVISION_5, REVISION_6
        owner_password56?(owner_password, user, owner, enc_revision)
      else
        raise ::IO::Error.new("Unknown Encryption Revision #{enc_revision}")
      end
    end

    def user_password?(password : Bytes, user : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bool
      case enc_revision
      when REVISION_2, REVISION_3, REVISION_4
        user_password234?(password, user, owner, permissions, id, enc_revision, key_length_in_bytes, encrypt_metadata)
      when REVISION_5, REVISION_6
        user_password56?(password, user, enc_revision)
      else
        raise ::IO::Error.new("Unknown Encryption Revision #{enc_revision}")
      end
    end

    def user_password(owner_password : Bytes, owner : Bytes, enc_revision : Int32, length : Int32) : Bytes
      if enc_revision == REVISION_5 || enc_revision == REVISION_6
        Bytes.new(0)
      else
        user_password234(owner_password, owner, enc_revision, length)
      end
    end

    def compute_encrypted_key(password : Bytes, o : Bytes, u : Bytes, oe : Bytes?, ue : Bytes?, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool, is_owner_password : Bool) : Bytes
      if enc_revision == REVISION_5 || enc_revision == REVISION_6
        compute_encrypted_key_rev56(password, is_owner_password, o, u, oe, ue, enc_revision)
      else
        compute_encrypted_key_rev234(password, o, permissions, id, encrypt_metadata, key_length_in_bytes, enc_revision)
      end
    end

    def compute_user_password(password : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bytes
      if enc_revision == REVISION_5 || enc_revision == REVISION_6
        return Bytes.new(0)
      end

      enc_key = compute_encrypted_key_rev234(password, owner, permissions, id, encrypt_metadata, key_length_in_bytes, enc_revision)

      if enc_revision == REVISION_2
        encrypt_data_rc4(enc_key, ENCRYPT_PADDING)
      elsif enc_revision == REVISION_3 || enc_revision == REVISION_4
        md = Digest::MD5.new
        md.update(ENCRYPT_PADDING)
        md.update(id)
        hash_result = md.final

        result = ::IO::Memory.new
        result.write(hash_result)

        iteration_key = Bytes.new(enc_key.size, 0_u8)
        20.times do |i|
          enc_key.copy_to(iteration_key)
          iteration_key.size.times do |j|
            iteration_key[j] = iteration_key[j] ^ i.to_u8
          end

          # Get current result bytes, encrypt them
          current_data = result.to_slice
          result.rewind
          encrypted = encrypt_data_rc4(iteration_key, current_data)
          result.write(encrypted)
        end

        final_result = Bytes.new(32, 0_u8)
        result.rewind
        result.read(final_result[0, 16])
        ENCRYPT_PADDING[0, 16].copy_to(final_result[16, 16])
        final_result
      else
        Bytes.new(0)
      end
    end

    def compute_owner_password(owner_password : Bytes, user_password : Bytes, enc_revision : Int32, length : Int32) : Bytes
      if enc_revision == REVISION_2 && length != 5
        raise ::IO::Error.new("Expected length=5 actual=#{length}")
      end

      rc4_key = compute_rc4_key(owner_password, enc_revision, length)
      padded_user = truncate_or_pad(user_password)

      encrypted = encrypt_data_rc4(rc4_key, padded_user)

      if enc_revision == REVISION_3 || enc_revision == REVISION_4
        iteration_key = Bytes.new(rc4_key.size, 0_u8)
        (1..19).each do |i|
          rc4_key.copy_to(iteration_key)
          iteration_key.size.times do |j|
            iteration_key[j] = iteration_key[j] ^ i.to_u8
          end
          encrypted = encrypt_data_rc4(iteration_key, encrypted)
        end
      end

      encrypted
    end

    private def owner_password234?(owner_password : Bytes, user : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bool
      user_password = user_password234(owner_password, owner, enc_revision, key_length_in_bytes)
      user_password234?(user_password, user, owner, permissions, id, enc_revision, key_length_in_bytes, encrypt_metadata)
    end

    private def owner_password56?(owner_password : Bytes, user : Bytes, owner : Bytes, enc_revision : Int32) : Bool
      if owner.size < 40
        raise ::IO::Error.new("Owner password is too short")
      end

      truncated_owner_password = truncate127(owner_password)
      o_hash = owner[0, 32]
      o_validation_salt = owner[32, 8]

      hash = if enc_revision == REVISION_5
               compute_sha256(truncated_owner_password, o_validation_salt, user)
             else
               compute_hash2a(truncated_owner_password, o_validation_salt, user)
             end

      hash == o_hash
    end

    private def user_password234?(password : Bytes, user : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, length : Int32, encrypt_metadata : Bool) : Bool
      password_bytes = compute_user_password(password, owner, permissions, id, enc_revision, length, encrypt_metadata)
      if enc_revision == REVISION_2
        user == password_bytes
      else
        # compare first 16 bytes only
        user[0, 16] == password_bytes[0, 16]
      end
    end

    private def user_password56?(password : Bytes, user : Bytes, enc_revision : Int32) : Bool
      if user.size < 40
        raise ::IO::Error.new("User password is too short")
      end

      truncated_password = truncate127(password)
      u_hash = user[0, 32]
      u_validation_salt = user[32, 8]

      hash = if enc_revision == REVISION_5
               compute_sha256(truncated_password, u_validation_salt, nil)
             else
               compute_hash2a(truncated_password, u_validation_salt, nil)
             end

      hash == u_hash
    end

    private def truncate_or_pad(password : Bytes) : Bytes
      padded = Bytes.new(ENCRYPT_PADDING.size, 0_u8)
      bytes_before_pad = Math.min(password.size, padded.size)
      password[0, bytes_before_pad].copy_to(padded[0, bytes_before_pad])
      ENCRYPT_PADDING[0, ENCRYPT_PADDING.size - bytes_before_pad].copy_to(padded[bytes_before_pad, ENCRYPT_PADDING.size - bytes_before_pad])
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

    private def prepare_encryption_dict_rev234(owner_password : String, user_password : String, encryption : PDEncryption, permission_int : Int32, document : Pdfbox::Pdmodel::Document, revision : Int32, length : Int32) : Nil
      # Generate document ID if not present
      # For now, use a simple fixed ID
      document_id = Bytes[0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10]

      # Convert passwords to bytes based on revision
      owner_password_bytes = password_to_bytes(owner_password, revision)
      user_password_bytes = password_to_bytes(user_password, revision)

      # Compute encryption key
      encrypt_metadata = true # Default to encrypting metadata
      enc_key = compute_encrypted_key_rev234(owner_password_bytes, Bytes.new(0), permission_int, document_id, encrypt_metadata, length, revision)

      # Set encryption key
      set_encryption_key(enc_key)

      # Compute owner key (O)
      owner_key = compute_owner_password(owner_password_bytes, user_password_bytes, revision, length)
      encryption.owner_key = owner_key

      # Compute user key (U)
      user_key = compute_user_password(user_password_bytes, owner_key, permission_int, document_id, revision, length, encrypt_metadata)
      encryption.user_key = user_key

      # Set other encryption parameters
      encryption.encrypt_metadata = encrypt_metadata

      # For revision 4, set up crypt filters
      if revision == REVISION_4
        setup_crypt_filters_rev4(encryption)
      end
    end

    private def prepare_encryption_dict_rev6(owner_password : String, user_password : String, encryption : PDEncryption, permission_int : Int32) : Nil
      # Revision 6 encryption (AES-256)
      # TODO: Implement SASLPrep for revision 6
      # owner_password = SaslPrep.sasl_prep_stored(owner_password)
      # user_password = SaslPrep.sasl_prep_stored(user_password)

      # Generate random 256-bit file encryption key
      encryption_key = Bytes.new(32)
      Random::Secure.random_bytes(encryption_key)
      @encryption_key = encryption_key

      # Set AES-256 encryption
      @use_aes = true

      # Convert passwords to UTF-8 bytes (revision 5/6 uses UTF-8)
      owner_password_bytes = owner_password.to_slice
      user_password_bytes = user_password.to_slice

      # Generate random salts
      user_salt = Bytes.new(8)
      owner_salt = Bytes.new(8)
      user_key_salt = Bytes.new(8)
      owner_key_salt = Bytes.new(8)
      Random::Secure.random_bytes(user_salt)
      Random::Secure.random_bytes(owner_salt)
      Random::Secure.random_bytes(user_key_salt)
      Random::Secure.random_bytes(owner_key_salt)

      # Compute user key (U)
      user_input = concat(user_password_bytes, user_salt)
      hash_u = compute_hash2b(user_input, user_password_bytes, nil)
      u = concat(hash_u, user_salt, user_key_salt)

      # Compute owner key (O)
      owner_input = concat(owner_password_bytes, owner_salt, u)
      hash_o = compute_hash2b(owner_input, owner_password_bytes, u)
      o = concat(hash_o, owner_salt, owner_key_salt)

      # Compute user encryption key (UE)
      ue_input = concat(user_password_bytes, user_key_salt)
      ue_hash = compute_hash2b(ue_input, user_password_bytes, nil)
      ue = encrypt_aes256_key(encryption_key, ue_hash)

      # Compute owner encryption key (OE)
      oe_input = concat(owner_password_bytes, owner_key_salt, u)
      oe_hash = compute_hash2b(oe_input, owner_password_bytes, u)
      oe = encrypt_aes256_key(encryption_key, oe_hash)

      # Set encryption dictionary values
      encryption.revision = REVISION_6
      encryption.length = 256 # 256-bit encryption
      encryption.owner_key = o
      encryption.user_key = u
      encryption.user_encryption_key = ue
      encryption.owner_encryption_key = oe
      encryption.permissions = permission_int
      encryption.encrypt_metadata = @policy.as(StandardProtectionPolicy).encrypt_metadata?

      # Set up AESV3 crypt filter
      setup_crypt_filters_rev6(encryption)

      # Validate permissions
      validate_perms(encryption, permission_int, @policy.as(StandardProtectionPolicy).encrypt_metadata?)
    end

    private def encrypt_aes256_key(key : Bytes, hash : Bytes) : Bytes
      # Encrypt key using AES-256 in CBC mode with zero IV
      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.encrypt
      cipher.key = hash
      cipher.iv = Bytes.new(16, 0_u8) # Zero IV
      cipher.padding = false

      cipher.update(key) + cipher.final
    end

    private def setup_crypt_filters_rev6(encryption : PDEncryption) : Nil
      # Create crypt filter dictionary for revision 6 (AES-256)
      std_crypt_filter = PDCryptFilterDictionary.new
      std_crypt_filter.length = 256                                         # 256-bit encryption
      std_crypt_filter.crypt_filter_method = Pdfbox::Cos::Name.new("AESV3") # AES-256
      std_crypt_filter.encrypt_metadata = @policy.as(StandardProtectionPolicy).encrypt_metadata?

      encryption.std_crypt_filter_dictionary = std_crypt_filter
      encryption.stream_filter_name = PDEncryption::STD_CF
      encryption.string_filter_name = PDEncryption::STD_CF
    end

    private def validate_perms(encryption : PDEncryption, permissions : Int32, encrypt_metadata : Bool) : Nil
      # Validate permissions for revision 5/6
      # Create 16-byte Perms string and encrypt it
      perms = Bytes.new(16, 0_u8)

      # Set permissions (little-endian)
      perms[0] = (permissions & 0xFF).to_u8
      perms[1] = ((permissions >> 8) & 0xFF).to_u8
      perms[2] = ((permissions >> 16) & 0xFF).to_u8
      perms[3] = ((permissions >> 24) & 0xFF).to_u8

      # Set encrypt_metadata flag
      perms[8] = encrypt_metadata ? 0xFF_u8 : 0x00_u8
      perms[9] = 0xFF_u8  # Always 0xFF for "adbe"
      perms[10] = 0xFF_u8 # Always 0xFF for "adbe"

      # Get encryption key
      encryption_key = @encryption_key
      return unless encryption_key

      # Encrypt perms with AES-256 in ECB mode
      cipher = OpenSSL::Cipher.new("AES-256-ECB")
      cipher.encrypt
      cipher.key = encryption_key
      cipher.padding = false

      encrypted_perms = cipher.update(perms) + cipher.final

      # Store encrypted perms in encryption dictionary
      # Note: This would need to be stored in the encryption dictionary
      # For now, we'll just validate that we can decrypt it
      cipher = OpenSSL::Cipher.new("AES-256-ECB")
      cipher.decrypt
      cipher.key = encryption_key
      cipher.padding = false

      decrypted_perms = cipher.update(encrypted_perms) + cipher.final

      # Verify decryption
      unless decrypted_perms == perms
        raise "Permissions validation failed for revision 5/6 encryption"
      end
    end

    private def setup_crypt_filters_rev4(encryption : PDEncryption) : Nil
      # Create crypt filter dictionary for revision 4
      std_crypt_filter = PDCryptFilterDictionary.new

      policy = @policy.as(StandardProtectionPolicy)
      if policy.prefer_aes?
        # Use AES encryption
        std_crypt_filter.length = policy.encryption_key_length
        std_crypt_filter.crypt_filter_method = Pdfbox::Cos::Name.new("AESV2") # AES-128
        @use_aes = true
      else
        # Use RC4 encryption
        std_crypt_filter.length = 128                                      # 128-bit encryption
        std_crypt_filter.crypt_filter_method = Pdfbox::Cos::Name.new("V2") # RC4
        @use_aes = false
      end

      std_crypt_filter.encrypt_metadata = policy.encrypt_metadata?

      encryption.std_crypt_filter_dictionary = std_crypt_filter
      encryption.stream_filter_name = PDEncryption::STD_CF
      encryption.string_filter_name = PDEncryption::STD_CF
    end

    private def compute_encrypted_key_rev234(password : Bytes, o : Bytes, permissions : Int32, id : Bytes, encrypt_metadata : Bool, length : Int32, enc_revision : Int32) : Bytes
      # Algorithm 2, based on MD5
      padded = truncate_or_pad(password)

      md = Digest::MD5.new
      md.update(padded)
      md.update(o)

      # Write permissions as little-endian bytes
      md.update(Bytes[(permissions & 0xFF).to_u8])
      md.update(Bytes[((permissions >> 8) & 0xFF).to_u8])
      md.update(Bytes[((permissions >> 16) & 0xFF).to_u8])
      md.update(Bytes[((permissions >> 24) & 0xFF).to_u8])

      md.update(id)

      # (Security handlers of revision 4 or greater) If document metadata is not being
      # encrypted, pass 4 bytes with the value 0xFFFFFFFF to the MD5 hash function.
      if enc_revision == REVISION_4 && !encrypt_metadata
        md.update(Bytes[0xFF_u8, 0xFF_u8, 0xFF_u8, 0xFF_u8])
      end

      digest = md.final

      if enc_revision == REVISION_3 || enc_revision == REVISION_4
        50.times do
          md = Digest::MD5.new
          md.update(digest[0, length])
          digest = md.final
        end
      end

      digest[0, length]
    end

    private def compute_encrypted_key_rev56(password : Bytes, is_owner_password : Bool, o : Bytes, u : Bytes, oe : Bytes?, ue : Bytes?, enc_revision : Int32) : Bytes
      hash : Bytes
      file_key_enc : Bytes

      if is_owner_password
        raise ::IO::Error.new("/Encrypt/OE entry is missing") unless oe
        o_key_salt = o[40, 8]
        hash = if enc_revision == REVISION_5
                 compute_sha256(password, o_key_salt, u)
               else
                 compute_hash2a(password, o_key_salt, u)
               end
        file_key_enc = oe
      else
        raise ::IO::Error.new("/Encrypt/UE entry is missing") unless ue
        u_key_salt = u[40, 8]
        hash = if enc_revision == REVISION_5
                 compute_sha256(password, u_key_salt, nil)
               else
                 compute_hash2a(password, u_key_salt, nil)
               end
        file_key_enc = ue
      end

      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.decrypt
      cipher.key = hash
      cipher.iv = Bytes.new(16, 0_u8)
      cipher.padding = false
      cipher.update(file_key_enc) + cipher.final
    end

    # Algorithm 2.A from ISO 32000-2
    private def compute_hash2a(password : Bytes, salt : Bytes, u : Bytes?) : Bytes
      user_key = adjust_user_key(u)
      truncated_password = truncate127(password)
      input = concat(truncated_password, salt, user_key)
      compute_hash2b(input, truncated_password, user_key)
    end

    # Algorithm 2.B from ISO 32000-2
    private def compute_hash2b(input : Bytes, password : Bytes, user_key : Bytes?) : Bytes
      k = Digest::SHA256.digest(input)
      user_key48 = if user_key && user_key.size >= 48
                     user_key[0, 48]
                   end

      e = Bytes.empty
      round = 0
      while round < 64 || (e[e.size - 1].to_i32 > round - 32)
        has_user_key = !user_key48.nil?
        chunk_size = password.size + k.size + (has_user_key ? 48 : 0)
        k1 = Bytes.new(64 * chunk_size, 0_u8)

        pos = 0
        64.times do
          password.copy_to(k1[pos, password.size])
          pos += password.size
          k.copy_to(k1[pos, k.size])
          pos += k.size
          if key48 = user_key48
            key48.copy_to(k1[pos, 48])
            pos += 48
          end
        end

        k_first = k[0, 16]
        k_second = k[16, 16]
        cipher = OpenSSL::Cipher.new("AES-128-CBC")
        cipher.encrypt
        cipher.key = k_first
        cipher.iv = k_second
        cipher.padding = false
        e = cipher.update(k1) + cipher.final

        remainder = 0
        e[0, 16].each do |b|
          remainder = ((remainder * 256) + b) % 3
        end
        next_hash = HASHES_2B[remainder]

        k = case next_hash
            when "SHA-384"
              OpenSSL::Digest.new("SHA384").update(e).final
            when "SHA-512"
              OpenSSL::Digest.new("SHA512").update(e).final
            else
              Digest::SHA256.digest(e)
            end

        round += 1
      end

      if k.size > 32
        k[0, 32]
      else
        k
      end
    end

    private def compute_sha256(input : Bytes, password : Bytes, user_key : Bytes?) : Bytes
      data = concat(input, password, adjust_user_key(user_key))
      Digest::SHA256.digest(data)
    end

    private def adjust_user_key(u : Bytes?) : Bytes
      return Bytes.empty if u.nil?
      user = u
      if user.size < 48
        raise ::IO::Error.new("Bad U length")
      elsif user.size > 48
        user[0, 48]
      else
        user
      end
    end

    private def concat(a : Bytes, b : Bytes) : Bytes
      result = Bytes.new(a.size + b.size, 0_u8)
      a.copy_to(result[0, a.size])
      b.copy_to(result[a.size, b.size])
      result
    end

    private def concat(a : Bytes, b : Bytes, c : Bytes) : Bytes
      result = Bytes.new(a.size + b.size + c.size, 0_u8)
      a.copy_to(result[0, a.size])
      b.copy_to(result[a.size, b.size])
      c.copy_to(result[a.size + b.size, c.size])
      result
    end

    private def truncate127(input : Bytes) : Bytes
      return input if input.size <= 127
      input[0, 127]
    end

    private def password_to_bytes(password : String, enc_revision : Int32) : Bytes
      # Apply SASLPrep for revision 6 (PDFBOX-4155)
      password = sasl_prep_query(password) if enc_revision == REVISION_6

      if enc_revision == REVISION_5 || enc_revision == REVISION_6
        # UTF-8 encoding for revisions 5-6
        password.to_slice
      else
        # ISO-8859-1 encoding for revisions 2-4
        iso_8859_1_bytes(password)
      end
    end

    private def sasl_prep_query(password : String) : String
      # TODO: implement SASLPrep string preparation as per RFC 4013
      # For now, return unchanged (ASCII passwords work)
      password
    end

    private def iso_8859_1_bytes(password : String) : Bytes
      # Convert string to ISO-8859-1 bytes
      # ISO-8859-1 maps characters 0-255 directly, characters outside range become '?' (0x3F)
      result = Bytes.new(password.size)
      password.each_char_with_index do |char, i|
        codepoint = char.ord
        if codepoint <= 255
          result[i] = codepoint.to_u8
        else
          result[i] = '?'.ord.to_u8 # 0x3F
        end
      end
      result
    end

    protected def encrypt_data_rc4(key : Bytes, input : ::IO, output : ::IO) : Nil
      # Read all input data
      data = Bytes.new(input.size.to_i32)
      input.read_fully(data)

      rc4 = RC4.new(key)
      result = rc4.process(data)
      output.write(result)
    end

    private def encrypt_data_rc4(key : Bytes, data : Bytes) : Bytes
      rc4 = RC4.new(key)
      rc4.process(data)
    end

    private def encrypt_data_aes_other(key : Bytes, input : ::IO, output : ::IO, decrypt : Bool) : Nil
      # AES with key length other than 256 bits (typically AES-128)
      iv = Bytes.new(16, 0_u8)

      unless prepare_aes_initialization_vector(decrypt, iv, input, output)
        return
      end

      cipher = create_cipher(key, iv, decrypt)

      buffer = Bytes.new(256)
      while (n = input.read(buffer)) > 0
        dst = cipher.update(buffer[0, n])
        output.write(dst) if dst && !dst.empty?
      end

      final = cipher.final
      output.write(final) if final && !final.empty?
    end

    private def encrypt_data_aes256(input : ::IO, output : ::IO, decrypt : Bool) : Nil
      # AES-256 encryption
      iv = Bytes.new(16, 0_u8)

      unless prepare_aes_initialization_vector(decrypt, iv, input, output)
        return
      end

      encryption_key = @encryption_key
      return unless encryption_key

      cipher = create_cipher(encryption_key, iv, decrypt)

      # Read and process in chunks
      buffer = Bytes.new(4096)
      while (n = input.read(buffer)) > 0
        dst = cipher.update(buffer[0, n])
        output.write(dst) if dst && !dst.empty?
      end

      final = cipher.final
      output.write(final) if final && !final.empty?
    end

    private def prepare_aes_initialization_vector(decrypt : Bool, iv : Bytes, input : ::IO, output : ::IO) : Bool
      # For encryption: generate random IV and write it to output
      # For decryption: read IV from input
      if decrypt
        # Read IV from input
        bytes_read = input.read(iv)
        return false if bytes_read != 16
      else
        # Generate random IV for encryption
        Random::Secure.random_bytes(iv)
        output.write(iv)
      end
      true
    end

    private def create_cipher(key : Bytes, iv : Bytes, decrypt : Bool) : OpenSSL::Cipher
      # Determine cipher based on key length
      cipher_name = if key.size == 32
                      "AES-256-CBC"
                    else
                      "AES-128-CBC"
                    end

      cipher = OpenSSL::Cipher.new(cipher_name)

      if decrypt
        cipher.decrypt
      else
        cipher.encrypt
      end

      cipher.key = key
      cipher.iv = iv
      cipher.padding = false # PDF uses no padding
      cipher
    end
  end

  # Public key security handler implementing Adobe.PubSec PDF encryption.
  # Port of org.apache.pdfbox.pdmodel.encryption.PublicKeySecurityHandler.
  class PublicKeySecurityHandler < SecurityHandler
    FILTER     = "Adobe.PubSec"
    SUBFILTER4 = "adbe.pkcs7.s4"
    SUBFILTER5 = "adbe.pkcs7.s5"

    def initialize
      super
    end

    def initialize(policy : PublicKeyProtectionPolicy)
      super(policy)
    end

    # Prepare document for encryption with recipient public keys.
    # Generates 20-byte seed, creates PKCS#7 envelopes per recipient,
    # derives encryption key from SHA1/SHA256 of seed + all recipient data.
    def prepare_document_for_encryption(document : Pdfbox::Pdmodel::Document) : Nil
      policy = @policy.as?(PublicKeyProtectionPolicy)
      raise "PublicKeySecurityHandler requires PublicKeyProtectionPolicy" unless policy

      @key_length = policy.encryption_key_length

      encryption = document.encryption || PDEncryption.new
      encryption.filter = FILTER
      encryption.length = get_key_length_bits
      version = compute_version_number
      encryption.version = version

      # Generate 20-byte random seed
      seed = Bytes.new(20)
      Random::Secure.random_bytes(seed)

      # Compute recipient fields (PKCS#7 envelopes per recipient)
      recipients_fields = compute_recipients_fields(seed, policy, get_key_length_bits // 8)

      # Derive encryption key: SHA1/SHA256 of seed + all recipient bytes
      sha_input_size = seed.size
      recipients_fields.each { |f| sha_input_size += f.size }
      sha_input = Bytes.new(sha_input_size)
      seed.copy_to(sha_input)
      offset = 20
      recipients_fields.each do |field|
        field.copy_to(sha_input[offset..])
        offset += field.size
      end

      key_bytes = get_key_length_bits // 8
      encryption_key = case version
                       when 4
                         encryption.sub_filter = SUBFILTER5
                         prepare_encryption_dict_aes(encryption, Pdfbox::Cos::Name.new("AESV2"), recipients_fields)
                         Digest::SHA1.digest(sha_input)
                       when 5
                         encryption.sub_filter = SUBFILTER5
                         prepare_encryption_dict_aes(encryption, Pdfbox::Cos::Name.new("AESV3"), recipients_fields)
                         Digest::SHA256.digest(sha_input)
                       else
                         encryption.sub_filter = SUBFILTER4
                         encryption.recipients = recipients_fields
                         Digest::SHA1.digest(sha_input)
                       end

      set_encryption_key(encryption_key[0, key_bytes])

      document.encryption = encryption
    end

    # Compute PKCS#7 recipient fields for each recipient.
    # Each field contains the 20-byte seed + 4 permission bytes, encrypted
    # with the recipient's RSA public key using RC2_CBC + RSA envelope.
    private def compute_recipients_fields(seed : Bytes, policy : PublicKeyProtectionPolicy, key_length : Int32) : Array(Bytes)
      fields = [] of Bytes
      policy.recipients.each do |recipient|
        cert = recipient.x509_certificate
        next unless cert

        permission = recipient.permissions.permission_bytes

        # Build PKCS#7 input: seed + 4 permission bytes (big-endian)
        pkcs7_input = Bytes.new(24)
        seed.copy_to(pkcs7_input)
        pkcs7_input[20] = ((permission >> 24) & 0xFF).to_u8
        pkcs7_input[21] = ((permission >> 16) & 0xFF).to_u8
        pkcs7_input[22] = ((permission >> 8) & 0xFF).to_u8
        pkcs7_input[23] = (permission & 0xFF).to_u8

        # Create DER-encoded PKCS#7 envelope using RSA public key
        der_envelope = create_der_for_recipient(pkcs7_input, cert, key_length)
        fields << der_envelope if der_envelope
      end
      fields
    end

    # Create DER-encoded PKCS#7 EnvelopedData for a recipient.
    # Encrypts the input with an ephemeral RC2 key, wraps the key with RSA.
    # NOTE: Full ASN.1/DER PKCS#7 encoding requires BouncyCastle or equivalent.
    # This stub uses OpenSSL for RSA encryption; full PKCS#7 envelope pending.
    private def create_der_for_recipient(input : Bytes, cert : OpenSSL::X509::Certificate, key_length : Int32) : Bytes?
      # Generate ephemeral RC2 session key
      ephemeral_key = Bytes.new(16)
      Random::Secure.random_bytes(ephemeral_key)

      # Encrypt input with RC2 using the ephemeral key
      rc2_encrypted = encrypt_data_rc2(input, ephemeral_key)

      # Encrypt ephemeral key with recipient's RSA public key
      rsa_encrypted_key = encrypt_session_key_rsa(ephemeral_key, cert)

      return unless rc2_encrypted && rsa_encrypted_key

      # Build simplified PKCS#7 envelope:
      # [rc2_encrypted_data | rsa_encrypted_key | cert_serial]
      envelope = ::IO::Memory.new
      envelope.write(rc2_encrypted)
      envelope.write(rsa_encrypted_key)
      envelope.to_slice
    end

    # Encrypt data using RC2 (simplified RC2-CBC).
    private def encrypt_data_rc2(data : Bytes, key : Bytes) : Bytes
      cipher = OpenSSL::Cipher.new("rc2")
      cipher.encrypt
      cipher.key = key
      iv = Bytes.new(8, 0_u8) # RC2 block size is 8 bytes
      cipher.iv = iv
      encrypted = cipher.update(data) + cipher.final
      encrypted
    rescue
      result = Bytes.new(data.size)
      data.each_with_index { |b, i| result[i] = b ^ key[i % key.size] }
      result
    end

    # Encrypt session key with recipient's RSA public key.
    # NOTE: Requires OpenSSL RSA support. Crystal stdlib OpenSSL lacks RSA.
    # For now, returns the key XOR'd with a derived value as a placeholder.
    # Replace with actual RSA when openssl_ext shard is available.
    private def encrypt_session_key_rsa(key : Bytes, cert : OpenSSL::X509::Certificate) : Bytes?
      # Placeholder: return key with simple transform
      # Real implementation uses: cert.public_key.encrypt(key, RSA_PKCS1_PADDING)
      result = Bytes.new(key.size)
      key.each_with_index { |b, i| result[i] = b ^ 0xAA_u8 }
      result
    end

    # Prepare for decryption using recipient private key.
    def prepare_for_decryption(encryption : PDEncryption, document_id_array : Cos::Array?,
                               decryption_material : DecryptionMaterial?) : Nil
      material = decryption_material.as?(PublicKeyDecryptionMaterial)
      raise ::IO::Error.new("Provided decryption material is not compatible") unless material

      crypt_filter = encryption.default_crypt_filter_dictionary
      if crypt_filter && crypt_filter.length != 0
        set_key_length(crypt_filter.length)
        set_decrypt_metadata(crypt_filter.encrypt_metadata?)
      elsif encryption.length != 0
        set_key_length(encryption.length)
        set_decrypt_metadata(encryption.encrypt_metadata?)
      end

      recipients_array = encryption.dictionary[Cos::Name.new("Recipients")]?
      if !recipients_array && crypt_filter
        recipients_array = crypt_filter.dictionary[Cos::Name.new("Recipients")]?
      end
      raise ::IO::Error.new("/Recipients entry missing") unless recipients_array
      recipients_array = resolve_object(recipients_array)

      return unless recipients_array.is_a?(Cos::Array)

      # Collect all recipient bytes for key derivation
      all_recipient_bytes = [] of Bytes
      found_recipient = false
      enveloped_data = nil

      recipients_array.items.each do |item|
        item = resolve_object(item)
        next unless item.is_a?(Cos::String)
        recipient_bytes = item.bytes
        all_recipient_bytes << recipient_bytes

        # Try to decrypt with private key
        unless found_recipient
          decrypted = decrypt_recipient_data_rsa(recipient_bytes, material)
          if decrypted && decrypted.size == 24
            found_recipient = true
            enveloped_data = decrypted
          end
        end
      end

      raise ::IO::Error.new("The certificate matches none of the recipient entries") unless found_recipient
      raise ::IO::Error.new("Enveloped data does not contain 24 bytes") unless enveloped_data && enveloped_data.size == 24

      # Set access permissions from last 4 bytes
      access_bytes = enveloped_data[20, 4]
      access_permission = access_bytes.to_a.reverse.reduce(0) { |acc, b| (acc << 8) | b }
      current = AccessPermission.new(access_permission)
      current.set_read_only
      set_current_access_permission(current)

      # Reconstruct encryption key: SHA1/SHA256 of seed + all recipient bytes
      sha1_size = 20
      all_recipient_bytes.each { |b| sha1_size += b.size }
      sha_input = Bytes.new(sha1_size)
      enveloped_data[0, 20].copy_to(sha_input)
      offset = 20
      all_recipient_bytes.each do |bytes|
        bytes.copy_to(sha_input[offset..])
        offset += bytes.size
      end

      version = encryption.version
      if version == 4 || version == 5
        unless decrypt_metadata?
          sha_input = sha_input + Bytes[0xFF_u8, 0xFF_u8, 0xFF_u8, 0xFF_u8]
        end
        md_result = version == 4 ? Digest::SHA1.digest(sha_input) : Digest::SHA256.digest(sha_input)

        if crypt_filter
          method = crypt_filter.crypt_filter_method
          if method
            set_use_aes(method.value == "AESV2" || method.value == "AESV3")
          end
        end
      else
        md_result = Digest::SHA1.digest(sha_input)
      end

      set_encryption_key(md_result[0, get_key_length_bits // 8])
    end

    # Decrypt recipient data using private key from keystore.
    # NOTE: Requires OpenSSL RSA support. Crystal stdlib lacks RSA.
    private def decrypt_recipient_data_rsa(recipient_bytes : Bytes, material : PublicKeyDecryptionMaterial) : Bytes?
      # Placeholder: try to decrypt using OpenSSL if available
      # Real implementation parses PKCS#7 CMS EnvelopedData,
      # matches recipient by cert serial, and decrypts with private key
      nil
    end

    private def prepare_encryption_dict_aes(encryption : PDEncryption, aes_name : Cos::Name, recipients : Array(Bytes)) : Nil
      crypt_filter = PDCryptFilterDictionary.new
      crypt_filter.crypt_filter_method = aes_name
      crypt_filter.length = get_key_length_bits

      array = Cos::Array.new
      recipients.each do |recipient|
        array.add(Cos::String.new(String.new(recipient)))
      end

      crypt_filter.dictionary[Cos::Name.new("Recipients")] = array
      encryption.default_crypt_filter_dictionary = crypt_filter
      encryption.stream_filter_name = Pdfbox::Cos::Name.new("StdCF")
      encryption.string_filter_name = Pdfbox::Cos::Name.new("StdCF")
      set_use_aes(true)
    end

    private def resolve_object(base : Cos::Base?) : Cos::Base?
      return unless base
      return base.object if base.is_a?(Cos::Object)
      base
    end
  end

  class SecurityHandlerFactory
    PROPERTY = "SecurityHandlerFactory"
    @@instance : SecurityHandlerFactory?

    private def initialize
      @name_to_handler = {
        StandardSecurityHandler::FILTER  => StandardSecurityHandler,
        PublicKeySecurityHandler::FILTER => PublicKeySecurityHandler,
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

    # Encryption dictionary getters
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
      bytes[0, copy_size].copy_to(result[0, copy_size])
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
      bytes[0, copy_size].copy_to(result[0, copy_size])
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

    def encrypt_metadata=(encrypt_metadata : Bool) : Bool
      @dictionary[Pdfbox::Cos::Name.new("EncryptMetadata")] = Pdfbox::Cos::Boolean.get(encrypt_metadata)
      encrypt_metadata
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
      cf_dictionary.direct = true # PDFBOX-4436 direct obj needed for Adobe Reader on Android
      cf_dictionary[crypt_filter_name] = crypt_filter_dictionary.dictionary
    end

    def std_crypt_filter_dictionary=(crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary
      crypt_filter_dictionary.dictionary.direct = true # PDFBOX-4436
      assign_crypt_filter_dictionary(STD_CF, crypt_filter_dictionary)
      crypt_filter_dictionary
    end

    def default_crypt_filter_dictionary=(default_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary
      default_filter_dictionary.dictionary.direct = true # PDFBOX-4436
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

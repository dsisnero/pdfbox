# Encryption types for PDFBox Crystal
require "../cos"

module Pdfbox::Pdmodel::Encryption
  # Basic view of access permission
  class AccessPermission
    @can_assemble_document = true
    @can_extract_content = true
    @can_extract_for_accessibility = true
    @can_fill_in_form = true
    @can_modify = true
    @can_modify_annotations = true
    @can_print = true
    @can_print_faithful = true
    @read_only = false

    def initialize(@owner_permission : Bool = true)
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

    # Getter methods
    def can_assemble_document? : Bool
      @can_assemble_document
    end

    def can_extract_content? : Bool
      @can_extract_content
    end

    def can_extract_for_accessibility? : Bool
      @can_extract_for_accessibility
    end

    def can_fill_in_form? : Bool
      @can_fill_in_form
    end

    def can_modify? : Bool
      @can_modify
    end

    def can_modify_annotations? : Bool
      @can_modify_annotations
    end

    def can_print? : Bool
      @can_print
    end

    def can_print_faithful? : Bool
      @can_print_faithful
    end

    # Setter methods
    def can_assemble_document=(value : Bool) : Nil
      @can_assemble_document = value
    end

    def can_extract_content=(value : Bool) : Nil
      @can_extract_content = value
    end

    def can_extract_for_accessibility=(value : Bool) : Nil
      @can_extract_for_accessibility = value
    end

    def can_fill_in_form=(value : Bool) : Nil
      @can_fill_in_form = value
    end

    def can_modify=(value : Bool) : Nil
      @can_modify = value
    end

    def can_modify_annotations=(value : Bool) : Nil
      @can_modify_annotations = value
    end

    def can_print=(value : Bool) : Nil
      @can_print = value
    end

    def can_print_faithful=(value : Bool) : Nil
      @can_print_faithful = value
    end

    # Java-style setter methods
    def set_can_assemble_document(value : Bool) : Nil
      @can_assemble_document = value
    end

    def set_can_extract_content(value : Bool) : Nil
      @can_extract_content = value
    end

    def set_can_extract_for_accessibility(value : Bool) : Nil
      @can_extract_for_accessibility = value
    end

    def set_can_fill_in_form(value : Bool) : Nil
      @can_fill_in_form = value
    end

    def set_can_modify(value : Bool) : Nil
      @can_modify = value
    end

    def set_can_modify_annotations(value : Bool) : Nil
      @can_modify_annotations = value
    end

    def set_can_print(value : Bool) : Nil
      @can_print = value
    end

    def set_can_print_faithful(value : Bool) : Nil
      @can_print_faithful = value
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
    def version : Int32
      entry = @dictionary[Pdfbox::Cos::Name.new("V")]
      if entry.is_a?(Pdfbox::Cos::Integer)
        entry.value.to_i32
      else
        0
      end
    end

    def revision : Int32
      entry = @dictionary[Pdfbox::Cos::Name.new("R")]
      if entry.is_a?(Pdfbox::Cos::Integer)
        entry.value.to_i32
      else
        DEFAULT_VERSION
      end
    end

    def length : Int32
      entry = @dictionary[Pdfbox::Cos::Name.new("Length")]
      if entry.is_a?(Pdfbox::Cos::Integer)
        entry.value.to_i32
      else
        DEFAULT_LENGTH
      end
    end

    def permissions : Int32
      entry = @dictionary[Pdfbox::Cos::Name.new("P")]
      if entry.is_a?(Pdfbox::Cos::Integer)
        entry.value.to_i32
      else
        0
      end
    end

    def owner_key : Bytes?
      nil
    end

    def user_key : Bytes?
      nil
    end

    def owner_encryption_key : Bytes?
      nil
    end

    def user_encryption_key : Bytes?
      nil
    end

    def encrypt_metadata? : Bool
      true
    end

    def stream_filter_name : Pdfbox::Cos::Name?
      nil
    end

    def string_filter_name : Pdfbox::Cos::Name?
      nil
    end

    def perms : Bytes?
      nil
    end

    # TODO: implement
    def security_handler : SecurityHandler
      raise ::IO::Error.new("No security handler for filter #{filter}") unless @security_handler
      @security_handler.not_nil!
    end

    def has_security_handler? : Bool
      !@security_handler.nil?
    end

    def set_filter(filter : String) : Nil
      # TODO
    end

    def sub_filter : String?
      nil
    end

    def set_sub_filter(subfilter : String) : Nil
      # TODO
    end

    def set_version(version : Int32) : Nil
      # TODO
    end

    def set_length(length : Int32) : Nil
      # TODO
    end

    def set_revision(revision : Int32) : Nil
      # TODO
    end

    def set_owner_key(o : Bytes) : Nil
      # TODO
    end

    def set_user_key(u : Bytes) : Nil
      # TODO
    end

    def set_owner_encryption_key(oe : Bytes) : Nil
      # TODO
    end

    def set_user_encryption_key(ue : Bytes) : Nil
      # TODO
    end

    def set_permissions(permissions : Int32) : Nil
      # TODO
    end

    def set_recipients(recipients : Array(Bytes)) : Nil
      # TODO
    end

    def recipients_length : Int32
      0
    end

    def recipient_string_at(i : Int32) : Pdfbox::Cos::String?
      nil
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

    def set_crypt_filter_dictionary(crypt_filter_name : Pdfbox::Cos::Name, crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Nil
      # TODO
    end

    def set_std_crypt_filter_dictionary(crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Nil
      # TODO
    end

    def set_default_crypt_filter_dictionary(default_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Nil
      # TODO
    end

    def set_stream_filter_name(stream_filter_name : Pdfbox::Cos::Name) : Nil
      # TODO
    end

    def set_string_filter_name(string_filter_name : Pdfbox::Cos::Name) : Nil
      # TODO
    end

    def set_perms(perms : Bytes) : Nil
      # TODO
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

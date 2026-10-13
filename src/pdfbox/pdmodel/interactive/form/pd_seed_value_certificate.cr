module Pdfbox::Pdmodel::Interactive::Form
  # A certificate seed value dictionary (/Cert). Corresponds to
  # PDSeedValueCertificate in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSeedValueCertificate.java
  class PDSeedValueCertificate
    FLAG_SUBJECT    = 1
    FLAG_ISSUER     = 1 << 1
    FLAG_OID        = 1 << 2
    FLAG_SUBJECT_DN = 1 << 3
    FLAG_KEY_USAGE  = 1 << 5
    FLAG_URL        = 1 << 6

    TYPE       = Cos::Name.new("Type")
    FF         = Cos::Name.new("Ff")
    SUBJECT    = Cos::Name.new("Subject")
    ISSUER     = Cos::Name.new("Issuer")
    OID        = Cos::Name.new("OID")
    SUBJECT_DN = Cos::Name.new("SubjectDN")
    KEY_USAGE  = Cos::Name.new("KeyUsage")
    URL        = Cos::Name.new("URL")
    URL_TYPE   = Cos::Name.new("URLType")

    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
      @dictionary[TYPE] = Cos::Name.new("SVCert")
      @dictionary.direct = true
    end

    def initialize(@dictionary : Cos::Dictionary)
      @dictionary.direct = true
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    # --- required flags (/Ff) ---

    def subject_required? : Bool
      flag?(FLAG_SUBJECT)
    end

    def subject_required=(flag : Bool) : Nil
      set_flag(FLAG_SUBJECT, flag)
    end

    def issuer_required? : Bool
      flag?(FLAG_ISSUER)
    end

    def issuer_required=(flag : Bool) : Nil
      set_flag(FLAG_ISSUER, flag)
    end

    def oid_required? : Bool
      flag?(FLAG_OID)
    end

    def oid_required=(flag : Bool) : Nil
      set_flag(FLAG_OID, flag)
    end

    def subject_dn_required? : Bool
      flag?(FLAG_SUBJECT_DN)
    end

    def subject_dn_required=(flag : Bool) : Nil
      set_flag(FLAG_SUBJECT_DN, flag)
    end

    def key_usage_required? : Bool
      flag?(FLAG_KEY_USAGE)
    end

    def key_usage_required=(flag : Bool) : Nil
      set_flag(FLAG_KEY_USAGE, flag)
    end

    def url_required? : Bool
      flag?(FLAG_URL)
    end

    def url_required=(flag : Bool) : Nil
      set_flag(FLAG_URL, flag)
    end

    # --- subject ---

    def subject : Array(Bytes)?
      byte_arrays(SUBJECT)
    end

    def subject=(subjects : Array(Bytes)) : Nil
      @dictionary[SUBJECT] = byte_arrays_to_cos_array(subjects)
    end

    def add_subject(subject : Bytes) : Nil
      array = @dictionary.get_array(SUBJECT) || Cos::Array.new
      array.add(Cos::String.new(subject))
      @dictionary[SUBJECT] = array
    end

    def remove_subject(subject : Bytes) : Nil
      @dictionary.get_array(SUBJECT).try(&.remove_object(Cos::String.new(subject)))
    end

    # --- subject DN ---

    def subject_dn : Array(Hash(::String, ::String?))?
      array = @dictionary.get_array(SUBJECT_DN)
      return nil unless array
      result = [] of Hash(::String, ::String?)
      array.each do |item|
        next unless item.is_a?(Cos::Dictionary)
        map = {} of ::String => ::String?
        item.entries.each do |key, _|
          map[key.value] = item.get_string(key)
        end
        result << map
      end
      result
    end

    def subject_dn=(subject_dn : Array(Hash(::String, ::String))) : Nil
      dictionaries = subject_dn.map do |item|
        dict = Cos::Dictionary.new
        item.each do |key, value|
          dict.set_item(Cos::Name.new(key), Cos::String.new(value))
        end
        dict
      end
      @dictionary[SUBJECT_DN] = Cos::Array.new(dictionaries)
    end

    # --- key usage ---

    def key_usage : Array(::String)?
      array = @dictionary.get_array(KEY_USAGE)
      return nil unless array
      result = [] of ::String
      array.each do |item|
        if item.is_a?(Cos::String)
          result << item.value
        end
      end
      result
    end

    def key_usage=(key_usage_extensions : Array(::String)) : Nil
      @dictionary[KEY_USAGE] = Cos::Array.of_cos_strings(key_usage_extensions)
    end

    def add_key_usage(key_usage_extension : ::String) : Nil
      key_usage_extension.each_char do |char|
        unless char.in?('0', '1', 'X')
          raise ArgumentError.new("characters can only be 0, 1, X")
        end
      end
      array = @dictionary.get_array(KEY_USAGE) || Cos::Array.new
      array.add(Cos::String.new(key_usage_extension))
      @dictionary[KEY_USAGE] = array
    end

    def add_key_usage(digital_signature : Char, non_repudiation : Char, key_encipherment : Char,
                      data_encipherment : Char, key_agreement : Char, key_cert_sign : Char,
                      crl_sign : Char, encipher_only : Char, decipher_only : Char) : Nil
      add_key_usage(::String.build do |builder|
        builder << digital_signature
        builder << non_repudiation
        builder << key_encipherment
        builder << data_encipherment
        builder << key_agreement
        builder << key_cert_sign
        builder << crl_sign
        builder << encipher_only
        builder << decipher_only
      end)
    end

    def remove_key_usage(key_usage_extension : ::String) : Nil
      @dictionary.get_array(KEY_USAGE).try(&.remove_object(Cos::String.new(key_usage_extension)))
    end

    # --- issuer ---

    def issuer : Array(Bytes)?
      byte_arrays(ISSUER)
    end

    def issuer=(issuers : Array(Bytes)) : Nil
      @dictionary[ISSUER] = byte_arrays_to_cos_array(issuers)
    end

    def add_issuer(issuer : Bytes) : Nil
      array = @dictionary.get_array(ISSUER) || Cos::Array.new
      array.add(Cos::String.new(issuer))
      @dictionary[ISSUER] = array
    end

    def remove_issuer(issuer : Bytes) : Nil
      @dictionary.get_array(ISSUER).try(&.remove_object(Cos::String.new(issuer)))
    end

    # --- OID ---

    def oid : Array(Bytes)?
      byte_arrays(OID)
    end

    def oid=(oid_byte_strings : Array(Bytes)) : Nil
      @dictionary[OID] = byte_arrays_to_cos_array(oid_byte_strings)
    end

    def add_oid(oid : Bytes) : Nil
      array = @dictionary.get_array(OID) || Cos::Array.new
      array.add(Cos::String.new(oid))
      @dictionary[OID] = array
    end

    def remove_oid(oid : Bytes) : Nil
      @dictionary.get_array(OID).try(&.remove_object(Cos::String.new(oid)))
    end

    # --- URL ---

    def url : ::String?
      @dictionary.get_string(URL)
    end

    def url=(url : ::String) : Nil
      @dictionary.set_string(URL, url)
    end

    def url_type : ::String?
      @dictionary.get_name_as_string(URL_TYPE)
    end

    def url_type=(url_type : ::String) : Nil
      @dictionary.set_name(URL_TYPE, url_type)
    end

    private def byte_arrays(key : Cos::Name) : Array(Bytes)?
      array = @dictionary.get_array(key)
      return nil unless array
      result = [] of Bytes
      array.each do |item|
        if item.is_a?(Cos::String)
          result << item.bytes
        end
      end
      result
    end

    private def byte_arrays_to_cos_array(byte_arrays : Array(Bytes)) : Cos::Array
      Cos::Array.new(byte_arrays.map { |bytes| Cos::String.new(bytes) })
    end

    private def flag?(bit : Int32) : Bool
      (@dictionary.get_int(FF, 0_i64) & bit) != 0
    end

    private def set_flag(bit : Int32, value : Bool) : Nil
      @dictionary.set_flag(FF, bit, value)
    end
  end
end

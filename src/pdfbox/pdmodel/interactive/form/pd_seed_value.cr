require "./pd_seed_value_mdp"
require "./pd_seed_value_time_stamp"

module Pdfbox::Pdmodel::Interactive::Form
  # A signature seed value dictionary (/SV). Corresponds to PDSeedValue in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSeedValue.java
  #
  # The /Cert (PDSeedValueCertificate) accessors are not ported yet.
  class PDSeedValue
    FLAG_FILTER            = 1
    FLAG_SUBFILTER         = 1 << 1
    FLAG_V                 = 1 << 2
    FLAG_REASON            = 1 << 3
    FLAG_LEGAL_ATTESTATION = 1 << 4
    FLAG_ADD_REV_INFO      = 1 << 5
    FLAG_DIGEST_METHOD     = 1 << 6

    ALLOWED_DIGEST_NAMES = ["SHA1", "SHA256", "SHA384", "SHA512", "RIPEMD160"] of String

    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
      @dictionary[Cos::Name::TYPE] = Cos::Name.new("SV")
    end

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    # --- required flags (/Ff) ---

    def filter_required? : Bool
      flag?(FLAG_FILTER)
    end

    def filter_required=(flag : Bool) : Nil
      set_flag(FLAG_FILTER, flag)
    end

    def sub_filter_required? : Bool
      flag?(FLAG_SUBFILTER)
    end

    def sub_filter_required=(flag : Bool) : Nil
      set_flag(FLAG_SUBFILTER, flag)
    end

    def digest_method_required? : Bool
      flag?(FLAG_DIGEST_METHOD)
    end

    def digest_method_required=(flag : Bool) : Nil
      set_flag(FLAG_DIGEST_METHOD, flag)
    end

    def v_required? : Bool
      flag?(FLAG_V)
    end

    def v_required=(flag : Bool) : Nil
      set_flag(FLAG_V, flag)
    end

    def reason_required? : Bool
      flag?(FLAG_REASON)
    end

    def reason_required=(flag : Bool) : Nil
      set_flag(FLAG_REASON, flag)
    end

    def legal_attestation_required? : Bool
      flag?(FLAG_LEGAL_ATTESTATION)
    end

    def legal_attestation_required=(flag : Bool) : Nil
      set_flag(FLAG_LEGAL_ATTESTATION, flag)
    end

    def add_rev_info_required? : Bool
      flag?(FLAG_ADD_REV_INFO)
    end

    def add_rev_info_required=(flag : Bool) : Nil
      set_flag(FLAG_ADD_REV_INFO, flag)
    end

    # --- entries ---

    # The filter (/Filter) as a name string.
    def filter : String?
      @dictionary.get_name_as_string(Cos::Name.new("Filter"))
    end

    def filter=(filter : Cos::Name) : Nil
      @dictionary[Cos::Name.new("Filter")] = filter
    end

    def sub_filter : Array(String?)
      names("SubFilter")
    end

    def sub_filter=(sub_filter : Array(String)) : Nil
      @dictionary[Cos::Name.new("SubFilter")] = Cos::Array.of_cos_names(sub_filter)
    end

    def digest_method : Array(String?)
      names("DigestMethod")
    end

    def digest_method=(digest_method : Array(String)) : Nil
      digest_method.each do |digest_name|
        unless ALLOWED_DIGEST_NAMES.includes?(digest_name)
          raise ArgumentError.new(
            "Digest method #{digest_name} is not allowed. Allowed values are: #{ALLOWED_DIGEST_NAMES}")
        end
      end
      @dictionary[Cos::Name.new("DigestMethod")] = Cos::Array.of_cos_names(digest_method)
    end

    # The minimum required capability (/V).
    def v : Float32
      @dictionary.get_float(Cos::Name.new("V"), 0.0).to_f32
    end

    def v=(minimum_required_capability : Float32) : Nil
      @dictionary.set_float(Cos::Name.new("V"), minimum_required_capability.to_f64)
    end

    def reasons : Array(String?)
      names("Reasons")
    end

    def reasons=(reasons : Array(String)) : Nil
      @dictionary[Cos::Name.new("Reasons")] = Cos::Array.of_cos_strings(reasons)
    end

    def legal_attestation : Array(String?)
      names("LegalAttestation")
    end

    def legal_attestation=(legal_attestation : Array(String)) : Nil
      @dictionary[Cos::Name.new("LegalAttestation")] = Cos::Array.of_cos_strings(legal_attestation)
    end

    # The MDP dictionary (/MDP), or nil.
    def mdp : PDSeedValueMDP?
      dict = @dictionary.get_dictionary(Cos::Name.new("MDP"))
      dict ? PDSeedValueMDP.new(dict) : nil
    end

    def mdp=(mdp : PDSeedValueMDP?) : Nil
      key = Cos::Name.new("MDP")
      if mdp
        @dictionary[key] = mdp.cos_object
      else
        @dictionary.delete(key)
      end
    end

    # The time stamp dictionary (/TimeStamp), or nil.
    def time_stamp : PDSeedValueTimeStamp?
      dict = @dictionary.get_dictionary(Cos::Name.new("TimeStamp"))
      dict ? PDSeedValueTimeStamp.new(dict) : nil
    end

    def time_stamp=(time_stamp : PDSeedValueTimeStamp?) : Nil
      key = Cos::Name.new("TimeStamp")
      if time_stamp
        @dictionary[key] = time_stamp.cos_object
      else
        @dictionary.delete(key)
      end
    end

    private def names(key : String) : Array(String?)
      array = @dictionary.get_array(Cos::Name.new(key))
      array ? array.to_cos_name_string_list : [] of String?
    end

    private def flag?(bit : Int32) : Bool
      (@dictionary.get_int(Cos::Name.new("Ff"), 0_i64) & bit) != 0
    end

    private def set_flag(bit : Int32, value : Bool) : Nil
      @dictionary.set_flag(Cos::Name.new("Ff"), bit, value)
    end
  end
end

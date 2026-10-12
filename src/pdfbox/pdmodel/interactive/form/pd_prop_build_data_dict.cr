module Pdfbox::Pdmodel::Interactive::Form
  # A property build data dictionary (entry of a /Prop_Build dictionary).
  # Corresponds to PDPropBuildDataDict in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDPropBuildDataDict.java
  class PDPropBuildDataDict
    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
    end

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    def name : String?
      @dictionary.get_name_as_string(Cos::Name.new("Name"))
    end

    def name=(name : String) : Nil
      @dictionary.set_name(Cos::Name.new("Name"), name)
    end

    def date : String?
      @dictionary.get_string(Cos::Name.new("Date"))
    end

    def date=(date : String) : Nil
      @dictionary.set_string(Cos::Name.new("Date"), date)
    end

    # The application version (/REx).
    def version : String?
      @dictionary.get_string(Cos::Name.new("REx"))
    end

    def version=(application_version : String) : Nil
      @dictionary.set_string(Cos::Name.new("REx"), application_version)
    end

    # The application revision (/R).
    def revision : Int64
      @dictionary.get_int(Cos::Name.new("R"), 0_i64)
    end

    def revision=(revision : Int64) : Nil
      @dictionary.set_long(Cos::Name.new("R"), revision)
    end

    # The minimum supported revision (/V).
    def minimum_revision : Int64
      @dictionary.get_int(Cos::Name.new("V"), 0_i64)
    end

    def minimum_revision=(revision : Int64) : Nil
      @dictionary.set_long(Cos::Name.new("V"), revision)
    end

    def pre_release? : Bool
      dict_bool(Cos::Name.new("PreRelease"), false)
    end

    def pre_release=(pre_release : Bool) : Nil
      @dictionary.set_boolean(Cos::Name.new("PreRelease"), pre_release)
    end

    # The operating system (/OS): either the first name of an array or a string.
    def os : String?
      os_array = @dictionary.get_array(Cos::Name.new("OS"))
      os_array ? os_array.get_name(0) : @dictionary.get_string(Cos::Name.new("OS"))
    end

    def os=(os : String?) : Nil
      key = Cos::Name.new("OS")
      if os.nil?
        @dictionary.remove_item(key)
      else
        os_array = @dictionary.get_array(key)
        unless os_array
          os_array = Cos::Array.new
          @dictionary[key] = os_array
        end
        os_array.add(0, Cos::Name.new(os))
      end
    end

    def non_efont_no_warn? : Bool
      dict_bool(Cos::Name.new("NonEFontNoWarn"), true)
    end

    def non_efont_no_warn=(value : Bool) : Nil
      @dictionary.set_boolean(Cos::Name.new("NonEFontNoWarn"), value)
    end

    def trusted_mode? : Bool
      dict_bool(Cos::Name.new("TrustedMode"), false)
    end

    def trusted_mode=(value : Bool) : Nil
      @dictionary.set_boolean(Cos::Name.new("TrustedMode"), value)
    end

    private def dict_bool(key : Cos::Name, default : Bool) : Bool
      value = @dictionary.get_dictionary_object(key)
      value.is_a?(Cos::Boolean) ? value.value : default
    end
  end
end

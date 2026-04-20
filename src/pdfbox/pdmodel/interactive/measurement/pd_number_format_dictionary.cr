module Pdfbox::Pdmodel::Interactive::Measurement
  class PDNumberFormatDictionary
    TYPE                        = "NumberFormat"
    LABEL_SUFFIX_TO_VALUE       = "S"
    LABEL_PREFIX_TO_VALUE       = "P"
    FRACTIONAL_DISPLAY_DECIMAL  = "D"
    FRACTIONAL_DISPLAY_FRACTION = "F"
    FRACTIONAL_DISPLAY_ROUND    = "R"
    FRACTIONAL_DISPLAY_TRUNCATE = "T"

    @number_format_dictionary : Cos::Dictionary

    def initialize
      @number_format_dictionary = Cos::Dictionary.new
      @number_format_dictionary.set_name(Cos::Name::TYPE, TYPE)
    end

    def initialize(@number_format_dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @number_format_dictionary
    end

    def type : String
      TYPE
    end

    def units : String?
      @number_format_dictionary.get_string(Cos::Name.new("U"))
    end

    def units=(value : String) : String
      @number_format_dictionary.set_string("U", value)
      value
    end

    def conversion_factor : Float64
      @number_format_dictionary.get_float(Cos::Name.new("C"))
    end

    def conversion_factor=(value : Number) : Float64
      float_value = value.to_f64
      @number_format_dictionary.set_float("C", float_value)
      float_value
    end

    def fractional_display : String
      @number_format_dictionary.get_string(Cos::Name.new("F"), FRACTIONAL_DISPLAY_DECIMAL).to_s
    end

    def fractional_display=(value : String?) : String?
      validate_fractional_display(value)
      set_optional_string("F", value)
    end

    def denominator : Int32
      @number_format_dictionary.get_int(Cos::Name.new("D")).to_i32
    end

    def denominator=(value : Int) : Int32
      int_value = value.to_i32
      @number_format_dictionary.set_int("D", int_value)
      int_value
    end

    def fd? : Bool
      @number_format_dictionary[Cos::Name.new("FD")]?.as?(Cos::Boolean).try(&.value) || false
    end

    def fd=(value : Bool) : Bool
      @number_format_dictionary.set_boolean("FD", value)
      value
    end

    def thousands_separator : String
      @number_format_dictionary.get_string(Cos::Name.new("RT"), ",").to_s
    end

    def thousands_separator=(value : String) : String
      @number_format_dictionary.set_string("RT", value)
      value
    end

    def decimal_separator : String
      @number_format_dictionary.get_string(Cos::Name.new("RD"), ".").to_s
    end

    def decimal_separator=(value : String) : String
      @number_format_dictionary.set_string("RD", value)
      value
    end

    def label_prefix_string : String
      @number_format_dictionary.get_string(Cos::Name.new("PS"), " ").to_s
    end

    def label_prefix_string=(value : String) : String
      @number_format_dictionary.set_string("PS", value)
      value
    end

    def label_suffix_string : String
      @number_format_dictionary.get_string(Cos::Name.new("SS"), " ").to_s
    end

    def label_suffix_string=(value : String) : String
      @number_format_dictionary.set_string("SS", value)
      value
    end

    def label_position_to_value : String
      @number_format_dictionary.get_string(Cos::Name.new("O"), LABEL_SUFFIX_TO_VALUE).to_s
    end

    def label_position_to_value=(value : String?) : String?
      validate_label_position(value)
      set_optional_string("O", value)
    end

    private def validate_fractional_display(value : String?) : Nil
      return if value.nil?
      return if {
                  FRACTIONAL_DISPLAY_DECIMAL,
                  FRACTIONAL_DISPLAY_FRACTION,
                  FRACTIONAL_DISPLAY_ROUND,
                  FRACTIONAL_DISPLAY_TRUNCATE,
                }.includes?(value)

      raise ArgumentError.new("Value must be \"D\", \"F\", \"R\", or \"T\", (or nil).")
    end

    private def validate_label_position(value : String?) : Nil
      return if value.nil?
      return if {LABEL_PREFIX_TO_VALUE, LABEL_SUFFIX_TO_VALUE}.includes?(value)

      raise ArgumentError.new("Value must be \"S\", or \"P\" (or nil).")
    end

    private def set_optional_string(key : String, value : String?) : String?
      if value
        @number_format_dictionary.set_string(key, value)
      else
        @number_format_dictionary.delete(Cos::Name.new(key))
      end
      value
    end
  end
end

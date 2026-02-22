# A text field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDTextField < PDTerminalField
    FLAG_MULTILINE          = 1 << 12
    FLAG_PASSWORD           = 1 << 13
    FLAG_FILE_SELECT        = 1 << 20
    FLAG_DO_NOT_SPELL_CHECK = 1 << 22
    FLAG_DO_NOT_SCROLL      = 1 << 23
    FLAG_COMB               = 1 << 24
    FLAG_RICH_TEXT          = 1 << 25

    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    def field_type : String
      "Tx"
    end

    def value_as_string : String
      value = @dictionary[Cos::Name.new("V")]
      case value
      when Cos::String
        value.value
      else
        ""
      end
    end

    def value=(value : String)
      @dictionary[Cos::Name.new("V")] = Cos::String.new(value)
    end

    # Check if multiline
    def multiline? : Bool
      (field_flags & FLAG_MULTILINE) != 0
    end

    # Check if password field
    def password? : Bool
      (field_flags & FLAG_PASSWORD) != 0
    end

    # Get default value
    def default_value : String?
      value = @dictionary[Cos::Name.new("DV")]
      value.as?(Cos::String).try(&.value)
    end

    # Set default value
    def default_value=(value : String)
      @dictionary[Cos::Name.new("DV")] = Cos::String.new(value)
    end

    # Get maximum length
    def max_length : Int32?
      value = @dictionary[Cos::Name.new("MaxLen")]
      return unless value.is_a?(Cos::Integer)
      value.value.to_i32
    end

    # Set maximum length
    def max_length=(len : Int32)
      @dictionary[Cos::Name.new("MaxLen")] = Cos::Integer.new(len.to_i64)
    end
  end
end

# A text field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDTextField < PDVariableText
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

    # Convenience constructor for a new text field (Java PDTextField(PDAcroForm)).
    def initialize(acro_form : PDAcroForm)
      super(acro_form, Cos::Dictionary.new, nil)
      @dictionary[Cos::Name.new("FT")] = Cos::Name.new("Tx")
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

    # Java PDTextField#getValue: returns the value string or an empty string.
    def value : String
      value = @dictionary[Cos::Name.new("V")]
      value = value.object if value.is_a?(Cos::Object)
      case value
      when Cos::String
        value.value
      when Cos::Stream
        io = value.create_input_stream
        io.gets_to_end
      else
        ""
      end
    end

    def value=(value : String)
      @dictionary[Cos::Name.new("V")] = Cos::String.new(value)
      apply_change
    end

    # Java PDTextField#setValue(null): removes the /V entry and still applies
    # the change (appearance generation).
    def value=(value : String?)
      if value
        @dictionary[Cos::Name.new("V")] = Cos::String.new(value)
      else
        @dictionary.delete(Cos::Name.new("V"))
      end
      apply_change
    end

    # Constructs appearance streams and appearance dictionaries for all widget
    # annotations. Java PDTextField#constructAppearances.
    def construct_appearances : Nil
      helper = AppearanceGeneratorHelper.new(self)
      helper.set_appearance_value(value_as_string)
    end

    protected def apply_change : Nil
      construct_appearances
      # if we supported JavaScript we would raise a field changed event here
    end

    # Check if multiline
    def multiline? : Bool
      (field_flags & FLAG_MULTILINE) != 0
    end

    # Set the multiline bit.
    def multiline=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_MULTILINE, value)
      value
    end

    # Check if password field
    def password? : Bool
      (field_flags & FLAG_PASSWORD) != 0
    end

    # Set the password bit.
    def password=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_PASSWORD, value)
      value
    end

    # Check if file select field
    def file_select? : Bool
      (field_flags & FLAG_FILE_SELECT) != 0
    end

    # Set the file select bit.
    def file_select=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_FILE_SELECT, value)
      value
    end

    # Check if comb field
    def comb? : Bool
      (field_flags & FLAG_COMB) != 0
    end

    # Set the comb bit.
    def comb=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_COMB, value)
      value
    end

    # Check if do not scroll field
    def do_not_scroll? : Bool
      (field_flags & FLAG_DO_NOT_SCROLL) != 0
    end

    # Set the do not scroll bit.
    def do_not_scroll=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_DO_NOT_SCROLL, value)
      value
    end

    # Check if do not spell check field
    def do_not_spell_check? : Bool
      (field_flags & FLAG_DO_NOT_SPELL_CHECK) != 0
    end

    # Set the do not spell check bit.
    def do_not_spell_check=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_DO_NOT_SPELL_CHECK, value)
      value
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

# Base class for a field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  abstract class PDField
    FLAG_READ_ONLY = 1
    FLAG_REQUIRED  = 1 << 1
    FLAG_NO_EXPORT = 1 << 2

    @acro_form : PDAcroForm
    @parent : PDNonTerminalField?
    @dictionary : Cos::Dictionary

    def initialize(@acro_form : PDAcroForm, @dictionary : Cos::Dictionary, @parent : PDNonTerminalField?)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @dictionary
    end

    # Get the AcroForm
    def acro_form : PDAcroForm
      @acro_form
    end

    # Get the parent field
    def parent : PDNonTerminalField?
      @parent
    end

    # Get the partial field name (T entry)
    def partial_name : String?
      value = @dictionary[Cos::Name.new("T")]
      value.as?(Cos::String).try(&.value)
    end

    # Set the partial field name
    def partial_name=(name : String)
      @dictionary[Cos::Name.new("T")] = Cos::String.new(name)
    end

    # Get the fully qualified field name
    def fully_qualified_name : String
      parts = [] of String
      parts << partial_name if partial_name

      current = parent
      while current
        parts.unshift(current.partial_name) if current.partial_name
        current = current.parent
      end

      parts.join(".")
    end

    # Get the field type (FT entry)
    abstract def field_type : String

    # Get the field flags
    def field_flags : Int32
      value = @dictionary[Cos::Name.new("Ff")]
      return 0 unless value.is_a?(Cos::Integer)
      value.value.to_i32
    end

    # Set the field flags
    def field_flags=(flags : Int32)
      @dictionary[Cos::Name.new("Ff")] = Cos::Integer.new(flags.to_i64)
    end

    # Check if field is read-only
    def read_only? : Bool
      (field_flags & FLAG_READ_ONLY) != 0
    end

    # Set read-only flag
    def read_only=(value : Bool)
      flags = field_flags
      if value
        flags |= FLAG_READ_ONLY
      else
        flags &= ~FLAG_READ_ONLY
      end
      self.field_flags = flags
    end

    # Check if field is required
    def required? : Bool
      (field_flags & FLAG_REQUIRED) != 0
    end

    # Check if field should not be exported
    def no_export? : Bool
      (field_flags & FLAG_NO_EXPORT) != 0
    end

    # Get the value as string
    abstract def value_as_string : String

    # Set the value
    abstract def value=(value : String)

    # Get the widget annotations associated with this field
    abstract def widgets : Array(Annotation::PDAnnotationWidget)
  end
end

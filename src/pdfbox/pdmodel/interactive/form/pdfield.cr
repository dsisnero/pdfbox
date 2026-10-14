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
      read_string_or_name("T")
    end

    # Set the partial field name
    def partial_name=(name : String)
      @dictionary[Cos::Name.new("T")] = Cos::String.new(name)
    end

    # The alternate field name (/TU), or nil (Java getAlternateFieldName).
    def alternate_field_name : String?
      read_string_or_name("TU")
    end

    def alternate_field_name=(alternate_field_name : String) : Nil
      @dictionary.set_string(Cos::Name.new("TU"), alternate_field_name)
    end

    # The mapping name (/TM), or nil (Java getMappingName).
    def mapping_name : String?
      read_string_or_name("TM")
    end

    def mapping_name=(mapping_name : String) : Nil
      @dictionary.set_string(Cos::Name.new("TM"), mapping_name)
    end

    # Java COSDictionary.getString: accepts a COSName as well as a COSString.
    private def read_string_or_name(key : ::String) : String?
      value = @dictionary.get_dictionary_object(Cos::Name.new(key))
      case value
      when Cos::String then value.value
      when Cos::Name   then value.value
      else                  nil
      end
    end

    # Get the fully qualified field name
    def fully_qualified_name : String
      parts = [] of String
      if name = partial_name
        parts << name
      end

      current = parent
      while current
        if name = current.partial_name
          parts.unshift(name)
        end
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

    # Get the additional actions of the field (Java PDField#getActions).
    def actions : Action::PDFormFieldAdditionalActions?
      cos_dict = @dictionary.get_dictionary(Cos::Name.new("AA"))
      return unless cos_dict
      Action::PDFormFieldAdditionalActions.new(cos_dict)
    end

    # Get an inheritable attribute, walking up the parent chain and falling
    # back to the AcroForm dictionary (Java PDField#getInheritableAttribute).
    def get_inheritable_attribute(key : Cos::Name) : Cos::Base?
      if @dictionary.has_key?(key)
        value = @dictionary[key]
        value.is_a?(Cos::Object) ? value.object : value
      elsif parent = @parent
        parent.get_inheritable_attribute(key)
      else
        value = @acro_form.cos_object[key]?
        value.is_a?(Cos::Object) ? value.object : value
      end
    end
  end
end

# An interactive form, also known as an AcroForm
module Pdfbox::Pdmodel::Interactive::Form
  class PDAcroForm
    FLAG_SIGNATURES_EXIST = 1
    FLAG_APPEND_ONLY      = 1 << 1

    @document : Pdmodel::Document
    @dictionary : Cos::Dictionary
    @field_cache : Hash(String, PDField)?

    def initialize(@document : Pdmodel::Document)
      @dictionary = Cos::Dictionary.new
      @dictionary[Cos::Name.new("Fields")] = Cos::Array.new
    end

    def initialize(@document : Pdmodel::Document, @dictionary : Cos::Dictionary)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @dictionary
    end

    # Get the document
    def document : Pdmodel::Document
      @document
    end

    # Get all fields in the form
    def fields : Array(PDField)
      fields_array = @dictionary[Cos::Name.new("Fields")]
      return [] of PDField unless fields_array.is_a?(Cos::Array)

      result = [] of PDField
      fields_array.items.each do |field_dict|
        if field_dict.is_a?(Cos::Dictionary)
          field = PDFieldFactory.create_field(self, field_dict, nil)
          result << field if field
        end
      end
      result
    end

    # Get a field by name
    def get_field(name : String) : PDField?
      fields.each do |field|
        found = find_field_by_name(field, name)
        return found if found
      end
      nil
    end

    private def find_field_by_name(field : PDField, name : String) : PDField?
      return field if field.partial_name == name

      if field.is_a?(PDNonTerminalField)
        field.children.each do |child|
          found = find_field_by_name(child, name)
          return found if found
        end
      end
      nil
    end

    # Check if signatures exist
    def signatures_exist? : Bool
      flags = @dictionary[Cos::Name.new("SigFlags")]
      return false unless flags.is_a?(Cos::Integer)
      (flags.value & FLAG_SIGNATURES_EXIST) != 0
    end

    # Check if form is append-only
    def append_only? : Bool
      flags = @dictionary[Cos::Name.new("SigFlags")]
      return false unless flags.is_a?(Cos::Integer)
      (flags.value & FLAG_APPEND_ONLY) != 0
    end

    # Get the default resources
    def default_resources : Pdmodel::Resources?
      dr = @dictionary[Cos::Name.new("DR")]
      return unless dr.is_a?(Cos::Dictionary)
      Pdmodel::Resources.new(dr)
    end

    # Check if NeedAppearances flag is set
    def need_appearances? : Bool
      value = @dictionary[Cos::Name.new("NeedAppearances")]
      return false unless value.is_a?(Cos::Boolean)
      value.value
    end

    # Set NeedAppearances flag
    def need_appearances=(value : Bool)
      @dictionary[Cos::Name.new("NeedAppearances")] = Cos::Boolean.new(value)
    end

    # Add a field to the form
    def add_field(field : PDField)
      fields_array = @dictionary[Cos::Name.new("Fields")]
      unless fields_array.is_a?(Cos::Array)
        fields_array = Cos::Array.new
        @dictionary[Cos::Name.new("Fields")] = fields_array
      end
      fields_array.add(field.cos_object)
    end
  end
end

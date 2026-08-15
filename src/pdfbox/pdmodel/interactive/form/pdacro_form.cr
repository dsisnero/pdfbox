# An interactive form, also known as an AcroForm
module Pdfbox::Pdmodel::Interactive::Form
  class PDAcroForm
    FLAG_SIGNATURES_EXIST = 1
    FLAG_APPEND_ONLY      = 1 << 1

    @document : Pdmodel::Document
    @dictionary : Cos::Dictionary
    @field_cache : Hash(String, PDField)?
    @scripting_handler : ScriptingHandler?

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

    # Get the scripting handler used to format values.
    def scripting_handler : ScriptingHandler?
      @scripting_handler
    end

    # Set the scripting handler used to format values.
    def scripting_handler=(handler : ScriptingHandler?) : ScriptingHandler?
      @scripting_handler = handler
    end

    # Get all fields in the form
    def fields : Array(PDField)
      fields_value = @dictionary[Cos::Name.new("Fields")]
      if fields_value.is_a?(Cos::Object)
        fields_value = fields_value.object
      end
      return [] of PDField unless fields_value.is_a?(Cos::Array)
      fields_array = fields_value

      result = [] of PDField
      fields_array.items.each do |field_item|
        field_dict = field_item
        field_dict = field_dict.object if field_dict.is_a?(Cos::Object)
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
    def default_resources : Pdmodel::PDResources?
      dr = @dictionary[Cos::Name.new("DR")]
      dr = dr.object if dr.is_a?(Cos::Object)
      return unless dr.is_a?(Cos::Dictionary)
      Pdmodel::PDResources.new(dr)
    end

    # Set the default resources
    def default_resources=(value : Pdmodel::PDResources) : Pdmodel::PDResources
      @dictionary[Cos::Name.new("DR")] = value.cos_object
      value
    end

    # Get the default appearance string (DA entry)
    def default_appearance : String?
      value = @dictionary[Cos::Name.new("DA")]
      value.as?(Cos::String).try(&.value)
    end

    # Set the default appearance string
    def default_appearance=(value : String) : String
      @dictionary.set_string(Cos::Name.new("DA"), value)
      value
    end

    # Check if NeedAppearances flag is set
    def need_appearances? : Bool
      value = @dictionary[Cos::Name.new("NeedAppearances")]
      return false unless value.is_a?(Cos::Boolean)
      value.value
    end

    # Set NeedAppearances flag
    def need_appearances=(value : Bool)
      @dictionary[Cos::Name.new("NeedAppearances")] = Cos::Boolean.get(value)
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

    def import_fdf(fdf : Pdfbox::Pdmodel::Fdf::FDFDocument) : Nil
      fdf.catalog.fdf.fields.try(&.each do |field|
        next unless name = field.partial_field_name
        get_field(name).try(&.import_fdf(field))
      end)
    end

    def export_fdf : Pdfbox::Pdmodel::Fdf::FDFDocument
      fdf = Pdfbox::Pdmodel::Fdf::FDFDocument.new
      exported_fields = fields.map(&.export_fdf)
      fdf.catalog.fdf.fields = exported_fields unless exported_fields.empty?

      if document_id = @document.document_id
        hex = document_id.hexstring
        fdf.catalog.fdf.id = [hex, hex]
      end
      fdf
    end
  end
end

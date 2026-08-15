# A signature field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDSignatureField < PDTerminalField
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    # Convenience constructor for a new signature field
    # (Java PDSignatureField(PDAcroForm)).
    def initialize(acro_form : PDAcroForm)
      super(acro_form, Cos::Dictionary.new, nil)
      @dictionary[Cos::Name.new("FT")] = Cos::Name.new("Sig")
      first_widget = widgets[0]
      first_widget.locked = true
      first_widget.printed = true
      self.partial_name = generate_partial_name
    end

    def field_type : String
      "Sig"
    end

    def value_as_string : String
      "" # Signatures have complex values, not simple strings
    end

    # Java PDSignatureField#setValue(String): throws UnsupportedOperationException.
    def value=(value : String)
      raise Pdfbox::Cos::UnsupportedOperationError.new("Signature fields don't support setting the value as String - use setValue(PDSignature value) instead")
    end

    # Sets the value of this field to be the given signature.
    # ameba:disable Naming/AccessorMethodName
    def set_value(value : PDSignature) : Nil
      @dictionary[Cos::Name.new("V")] = value.cos_object
      apply_change
    end

    # Check if signed
    def signed? : Bool
      @dictionary.has_key?(Cos::Name.new("V"))
    end

    # Get the signature. Java PDSignatureField#getSignature.
    def signature : PDSignature?
      value = @dictionary[Cos::Name.new("V")]?
      value = value.object if value.is_a?(Cos::Object)
      value.as?(Cos::Dictionary).try { |dictionary| PDSignature.new(dictionary) }
    end

    private def generate_partial_name : String
      field_name = "Signature"
      name_set = Set(String).new
      acro_form.fields.each do |field|
        if name = field.partial_name
          name_set.add(name)
        end
      end
      i = 1
      while name_set.includes?("#{field_name}#{i}")
        i += 1
      end
      "#{field_name}#{i}"
    end
  end
end

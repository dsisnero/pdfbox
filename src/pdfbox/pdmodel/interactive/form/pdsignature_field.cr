# A signature field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDSignatureField < PDTerminalField
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    def field_type : String
      "Sig"
    end

    def value_as_string : String
      "" # Signatures have complex values, not simple strings
    end

    def value=(value : String)
      # Signature values are set via signature objects, not strings
    end

    # Check if signed
    def signed? : Bool
      @dictionary.has_key?(Cos::Name.new("V"))
    end

    # Get the signature dictionary
    def signature : Cos::Dictionary?
      value = @dictionary[Cos::Name.new("V")]
      value.as?(Cos::Dictionary)
    end
  end
end

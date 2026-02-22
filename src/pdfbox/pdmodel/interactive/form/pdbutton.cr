# A button field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  abstract class PDButton < PDTerminalField
    FLAG_NO_TOGGLE_TO_OFF = 1 << 14
    FLAG_RADIO            = 1 << 15
    FLAG_PUSHBUTTON       = 1 << 16
    FLAG_RADIOS_IN_UNISON = 1 << 25

    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    def field_type : String
      "Btn"
    end
  end
end

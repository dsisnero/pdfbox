# A push button field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDPushButton < PDButton
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    # Convenience constructor for a new push button (Java PDPushButton(PDAcroForm)).
    def initialize(acro_form : PDAcroForm)
      super(acro_form)
      @dictionary.set_flag(Cos::Name.new("Ff"), PDButton::FLAG_PUSHBUTTON, true)
    end

    def value_as_string : String
      "" # Push buttons don't have values
    end

    def value=(value : String)
      # Push buttons don't store values
    end
  end
end

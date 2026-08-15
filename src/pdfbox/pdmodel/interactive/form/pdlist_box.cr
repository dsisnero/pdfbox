# A list box field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDListBox < PDChoice
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    # Convenience constructor for a new list box (Java PDListBox(PDAcroForm)).
    def initialize(acro_form : PDAcroForm)
      super(acro_form)
    end
  end
end

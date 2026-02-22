# A list box field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDListBox < PDChoice
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end
  end
end

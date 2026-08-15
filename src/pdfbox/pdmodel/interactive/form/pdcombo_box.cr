# A combo box field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDComboBox < PDChoice
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    # Convenience constructor for a new combo box (Java PDComboBox(PDAcroForm)).
    def initialize(acro_form : PDAcroForm)
      super(acro_form)
      @dictionary.set_flag(Cos::Name.new("Ff"), PDChoice::FLAG_COMBO, true)
    end

    # Java PDComboBox#constructAppearances.
    def construct_appearances : Nil
      helper = AppearanceGeneratorHelper.new(self)
      helper.set_appearance_value("")
    end
  end
end

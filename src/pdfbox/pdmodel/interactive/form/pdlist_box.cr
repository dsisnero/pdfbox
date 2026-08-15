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

    # Get the top index "TI" value. Java PDListBox#getTopIndex.
    def top_index : Int32
      @dictionary.get_int(Cos::Name.new("TI"), 0_i64).to_i32
    end

    # Set top index "TI" value. Java PDListBox#setTopIndex; nil removes it.
    def top_index=(value : Int32?) : Int32?
      if value
        @dictionary.set_int(Cos::Name.new("TI"), value)
      else
        @dictionary.delete(Cos::Name.new("TI"))
      end
      value
    end

    # Java PDListBox#constructAppearances.
    def construct_appearances : Nil
      helper = AppearanceGeneratorHelper.new(self)
      helper.set_appearance_value("")
    end
  end
end

# A check box toggles between two states, on and off.
module Pdfbox::Pdmodel::Interactive::Form
  class PDCheckBox < PDButton
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    # Convenience constructor for a new check box (Java PDCheckBox(PDAcroForm)).
    def initialize(acro_form : PDAcroForm)
      super(acro_form)
    end

    # This will tell if this check box is currently checked or not.
    def checked? : Bool
      value == get_on_value
    end

    # Checks the check box.
    def check : Nil
      self.value = get_on_value
    end

    # Unchecks the check box.
    def uncheck : Nil
      self.value = Cos::Name.new("Off").value
    end

    # Get the value which sets the check box to the On state.
    # ameba:disable Naming/AccessorMethodName
    def get_on_value : String
      widget = widgets[0]
      ap_dictionary = widget.appearance
      if ap_dictionary
        normal_appearance = ap_dictionary.normal_appearance
        if normal_appearance
          normal_appearance.sub_dictionary.keys.each do |entry|
            return entry.value unless entry == Cos::Name.new("Off")
          end
        end
      end
      ""
    end
  end
end

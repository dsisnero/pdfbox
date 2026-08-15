# Radio button fields contain a set of related buttons that can each be on or off.
module Pdfbox::Pdmodel::Interactive::Form
  class PDRadioButton < PDButton
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    # Convenience constructor for a new radio button (Java PDRadioButton(PDAcroForm)).
    def initialize(acro_form : PDAcroForm)
      super(acro_form)
      @dictionary.set_flag(Cos::Name.new("Ff"), PDButton::FLAG_RADIO, true)
    end

    # If set, a group of radio buttons within a radio button field that use the
    # same value for the on state will turn on and off in unison.
    def radios_in_unison? : Bool
      (field_flags & PDButton::FLAG_RADIOS_IN_UNISON) != 0
    end

    def radios_in_unison=(radios_in_unison : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), PDButton::FLAG_RADIOS_IN_UNISON, radios_in_unison)
      radios_in_unison
    end

    # Get the first selected index, or -1 if no option is selected.
    # ameba:disable Naming/AccessorMethodName
    def get_selected_index : Int32
      idx = 0
      widgets.each do |widget|
        return idx unless widget.appearance_state == Cos::Name.new("Off")
        idx += 1
      end
      -1
    end

    # Get the selected export values.
    # ameba:disable Naming/AccessorMethodName
    def get_selected_export_values : Array(String)
      export_values = get_export_values
      if export_values.empty?
        return [value]
      end

      selected_export_values = [] of String
      field_value = value
      idx = 0
      get_on_values.each do |on_value|
        if on_value == field_value
          selected_export_values << export_values[idx]
        end
        idx += 1
      end
      selected_export_values
    end
  end
end

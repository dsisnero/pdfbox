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

    # Push buttons have no value (Java PDPushButton#getValue).
    def value : String
      ""
    end

    # Push buttons have no default value (Java PDPushButton#getDefaultValue).
    def default_value : String
      ""
    end

    # Push buttons have no export values (Java PDPushButton#getExportValues).
    # ameba:disable Naming/AccessorMethodName
    def get_export_values : Array(String)
      [] of String
    end

    # A push button shall not use the /Opt entry (Java PDPushButton#setExportValues).
    # ameba:disable Naming/AccessorMethodName
    def set_export_values(values : Array(String)?) : Nil
      if values && !values.empty?
        raise ArgumentError.new("A PDPushButton shall not use the Opt entry in the field dictionary")
      end
    end

    # Push buttons have no on values (Java PDPushButton#getOnValues).
    # ameba:disable Naming/AccessorMethodName
    def get_on_values : Set(String)
      Set(String).new
    end
  end
end

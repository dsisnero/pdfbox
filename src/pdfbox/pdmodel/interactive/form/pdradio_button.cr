# A radio button field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDRadioButton < PDButton
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    def value_as_string : String
      value = @dictionary[Cos::Name.new("V")]
      case value
      when Cos::Name
        value.value
      else
        "Off"
      end
    end

    def value=(value : String)
      @dictionary[Cos::Name.new("V")] = Cos::Name.new(value)
    end

    # Get the selected value
    def selected : String
      value_as_string
    end

    # Set the selected value
    def select(value : String)
      self.value = value
    end
  end
end

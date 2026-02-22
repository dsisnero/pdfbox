# A checkbox field in an interactive form
module Pdfbox::Pdmodel::Interactive::Form
  class PDCheckBox < PDButton
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
      # Also update the appearance state (AS)
      @dictionary[Cos::Name.new("AS")] = Cos::Name.new(value)
    end

    # Check if checked
    def checked? : Bool
      value = value_as_string
      value != "Off" && !value.empty?
    end

    # Check the box
    def check
      # Get the export value (the "on" state name)
      on_value = export_value
      self.value = on_value
    end

    # Uncheck the box
    def uncheck
      self.value = "Off"
    end

    # Get the export value (on state name)
    def export_value : String
      # Look for the on state in the appearance dictionary
      appearance = @dictionary[Cos::Name.new("AP")]
      if appearance.is_a?(Cos::Dictionary)
        normal = appearance[Cos::Name.new("N")]
        if normal.is_a?(Cos::Dictionary)
          # Find a key that isn't "Off"
          normal.entries.each do |key, _|
            return key.value unless key.value == "Off"
          end
        end
      end
      "Yes" # Default on value
    end
  end
end

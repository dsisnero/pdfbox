# A PDField factory
module Pdfbox::Pdmodel::Interactive::Form
  class PDFieldFactory
    FIELD_TYPE_TEXT      = "Tx"
    FIELD_TYPE_BUTTON    = "Btn"
    FIELD_TYPE_CHOICE    = "Ch"
    FIELD_TYPE_SIGNATURE = "Sig"

    def self.create_field(form : PDAcroForm, field : Cos::Dictionary, parent : PDNonTerminalField?) : PDField?
      # Check if it's a non-terminal field (has Kids with field names)
      if field.has_key?(Cos::Name.new("Kids"))
        kids = field[Cos::Name.new("Kids")]
        if kids.is_a?(Cos::Array) && !kids.items.empty?
          kids.items.each do |kid|
            kid_dict = kid.is_a?(Cos::Dictionary) ? kid : nil
            if kid_dict && kid_dict.has_key?(Cos::Name.new("T"))
              return PDNonTerminalField.new(form, field, parent)
            end
          end
        end
      end

      field_type = find_field_type(field, Set(Cos::Dictionary).new)
      return unless field_type

      case field_type
      when FIELD_TYPE_CHOICE
        create_choice_subtype(form, field, parent)
      when FIELD_TYPE_TEXT
        PDTextField.new(form, field, parent)
      when FIELD_TYPE_SIGNATURE
        PDSignatureField.new(form, field, parent)
      when FIELD_TYPE_BUTTON
        create_button_subtype(form, field, parent)
      end
    end

    private def self.create_choice_subtype(form : PDAcroForm, field : Cos::Dictionary, parent : PDNonTerminalField?) : PDField
      flags = get_field_flags(field)
      if (flags & PDChoice::FLAG_COMBO) != 0
        PDComboBox.new(form, field, parent)
      else
        PDListBox.new(form, field, parent)
      end
    end

    private def self.create_button_subtype(form : PDAcroForm, field : Cos::Dictionary, parent : PDNonTerminalField?) : PDField
      flags = get_field_flags(field)
      if (flags & PDButton::FLAG_RADIO) != 0
        PDRadioButton.new(form, field, parent)
      elsif (flags & PDButton::FLAG_PUSHBUTTON) != 0
        PDPushButton.new(form, field, parent)
      else
        PDCheckBox.new(form, field, parent)
      end
    end

    private def self.get_field_flags(field : Cos::Dictionary) : Int32
      ff = field[Cos::Name.new("Ff")]
      return 0 unless ff.is_a?(Cos::Integer)
      ff.value.to_i32
    end

    private def self.find_field_type(dic : Cos::Dictionary, seen : Set(Cos::Dictionary)) : String?
      return unless seen.add?(dic)

      ft = dic[Cos::Name.new("FT")]
      if ft.is_a?(Cos::Name)
        return ft.value
      end

      # Check parent
      parent = dic[Cos::Name.new("Parent")]
      if parent.is_a?(Cos::Dictionary)
        return find_field_type(parent, seen)
      end

      nil
    end
  end
end

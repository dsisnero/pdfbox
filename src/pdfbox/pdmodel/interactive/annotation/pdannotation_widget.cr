# A widget annotation that is used for form fields
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationWidget < PDAnnotation
    SUB_TYPE = "Widget"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def highlighting_mode : String
      cos_object.get_name_as_string(Cos::Name.new("H")) || "I"
    end

    def highlighting_mode=(value : String?) : String?
      if value.nil? || {"N", "I", "O", "P", "T"}.includes?(value)
        if value.nil?
          cos_object.delete(Cos::Name.new("H"))
        else
          cos_object.set_name(Cos::Name.new("H"), value)
        end
        value
      else
        raise ArgumentError.new("Valid values for highlighting mode are 'N', 'I', 'O', 'P' or 'T'")
      end
    end

    def appearance_characteristics : PDAppearanceCharacteristicsDictionary?
      cos_object.get_dictionary(Cos::Name.new("MK")).try { |entry| PDAppearanceCharacteristicsDictionary.new(entry) }
    end

    def appearance_characteristics=(value : PDAppearanceCharacteristicsDictionary) : PDAppearanceCharacteristicsDictionary
      cos_object[Cos::Name.new("MK")] = value.cos_object
      value
    end

    def action : Action::PDAction?
      Action::PDActionFactory.create_action(cos_object.get_dictionary(Cos::Name.new("A")))
    end

    def action=(value : Action::PDAction) : Action::PDAction
      cos_object[Cos::Name.new("A")] = value.cos_object
      value
    end

    def actions : Action::PDAnnotationAdditionalActions?
      cos_object.get_dictionary(Cos::Name.new("AA")).try { |entry| Action::PDAnnotationAdditionalActions.new(entry) }
    end

    def actions=(value : Action::PDAnnotationAdditionalActions) : Action::PDAnnotationAdditionalActions
      cos_object[Cos::Name.new("AA")] = value.cos_object
      value
    end

    def border_style : PDBorderStyleDictionary?
      cos_object.get_dictionary(Cos::Name.new("BS")).try { |entry| PDBorderStyleDictionary.new(entry) }
    end

    def border_style=(value : PDBorderStyleDictionary) : PDBorderStyleDictionary
      cos_object[Cos::Name.new("BS")] = value.cos_object
      value
    end

    # Get the field name (T entry)
    def field_name : String?
      @dictionary[Cos::Name.new("T")].as?(Cos::String).try(&.value)
    end

    # Set the field name
    def field_name=(name : String)
      @dictionary[Cos::Name.new("T")] = Cos::String.new(name)
    end

    # Get the page reference
    def page_ref : Cos::Base?
      @dictionary[Cos::Name.new("P")]?
    end

    def page_ref=(page : Cos::Base) : Cos::Base
      @dictionary[Cos::Name.new("P")] = page
      page
    end

    def parent=(field)
      field_dictionary = field.responds_to?(:cos_object) ? field.cos_object : nil
      raise ArgumentError.new("parent field must expose a COS dictionary") unless field_dictionary.is_a?(Cos::Dictionary)
      raise ArgumentError.new("setParent() is not to be called for a field that shares a dictionary with its only widget") if cos_object == field_dictionary

      cos_object[Cos::Name.new("Parent")] = field_dictionary
      field
    end
  end
end

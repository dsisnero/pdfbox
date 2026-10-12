# A user property, i.e. a name/value pair in an attribute object owned by
# "UserProperties". Corresponds to PDUserProperty in Apache PDFBox.
#
# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDUserProperty.java
module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  class PDUserProperty < Pdfbox::Pdmodel::Common::PDDictionaryWrapper
    @user_attribute_object : PDUserAttributeObject?

    # Creates a new user property.
    def initialize(@user_attribute_object : PDUserAttributeObject?)
      super()
    end

    # Creates a user property with a given dictionary.
    def initialize(dictionary : Cos::Dictionary, @user_attribute_object : PDUserAttributeObject?)
      super(dictionary)
    end

    # Returns the property name (/N).
    def name : String?
      cos_object.get_name_as_string(Cos::Name.new("N"))
    end

    # Sets the property name (/N).
    def name=(name : String) : Nil
      potentially_notify_changed(self.name, name)
      cos_object.set_name(Cos::Name.new("N"), name)
    end

    # Returns the property value (/V).
    def value : Cos::Base?
      cos_object.get_dictionary_object(Cos::Name.new("V"))
    end

    # Sets the property value (/V). A nil value removes the entry.
    def value=(value : Cos::Base?) : Nil
      potentially_notify_changed(self.value, value)
      key = Cos::Name.new("V")
      if value
        cos_object[key] = value
      else
        cos_object.delete(key)
      end
    end

    # Returns the string for the property value (/F).
    def formatted_value : String?
      cos_object.get_string(Cos::Name.new("F"))
    end

    # Sets the string for the property value (/F).
    def formatted_value=(formatted_value : String) : Nil
      potentially_notify_changed(self.formatted_value, formatted_value)
      cos_object.set_string(Cos::Name.new("F"), formatted_value)
    end

    # Shall the property be hidden? (/H, default false).
    def hidden? : Bool
      value = cos_object.get_dictionary_object(Cos::Name.new("H"))
      value.is_a?(Cos::Boolean) ? value.value : false
    end

    # Specifies whether the property shall be hidden (/H).
    def hidden=(hidden : Bool) : Nil
      potentially_notify_changed(self.hidden?, hidden)
      cos_object.set_boolean(Cos::Name.new("H"), hidden)
    end

    private def potentially_notify_changed(old_entry, new_entry) : Nil
      return unless entry_changed?(old_entry, new_entry)
      @user_attribute_object.try(&.user_property_changed(self))
    end

    private def entry_changed?(old_entry, new_entry) : Bool
      return !new_entry.nil? if old_entry.nil?
      !(old_entry == new_entry)
    end
  end
end

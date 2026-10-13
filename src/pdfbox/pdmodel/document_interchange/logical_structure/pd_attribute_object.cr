module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  # Base class for attribute objects in the logical structure tree
  # (Java PDAttributeObject). A "Standard attribute object" wraps a COS
  # dictionary with an /O (owner) entry.
  abstract class PDAttributeObject
    @dictionary : Cos::Dictionary
    @structure_element : PDStructureElement?

    protected def initialize
      @dictionary = Cos::Dictionary.new
    end

    protected def initialize(@dictionary : Cos::Dictionary)
    end

    # Creates an attribute object from a dictionary, dispatching on the /O
    # owner entry (Java PDAttributeObject.create).
    def self.create(dictionary : Cos::Dictionary) : PDAttributeObject
      owner = dictionary.get_name_as_string(Cos::Name.new("O"))
      case owner
      when PDUserAttributeObject::OWNER_USER_PROPERTIES
        PDUserAttributeObject.new(dictionary)
      when Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDListAttributeObject::OWNER_LIST
        Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDListAttributeObject.new(dictionary)
      when Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDPrintFieldAttributeObject::OWNER_PRINT_FIELD
        Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDPrintFieldAttributeObject.new(dictionary)
      when Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDTableAttributeObject::OWNER_TABLE
        Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDTableAttributeObject.new(dictionary)
      when Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDLayoutAttributeObject::OWNER_LAYOUT
        Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDLayoutAttributeObject.new(dictionary)
      when Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDExportFormatAttributeObject::OWNER_XML_1_00,
           Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDExportFormatAttributeObject::OWNER_HTML_3_20,
           Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDExportFormatAttributeObject::OWNER_HTML_4_01,
           Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDExportFormatAttributeObject::OWNER_OEB_1_00,
           Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDExportFormatAttributeObject::OWNER_RTF_1_05,
           Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDExportFormatAttributeObject::OWNER_CSS_1_00,
           Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDExportFormatAttributeObject::OWNER_CSS_2_00
        Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf::PDExportFormatAttributeObject.new(dictionary)
      else
        PDDefaultAttributeObject.new(dictionary)
      end
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    protected def structure_element : PDStructureElement?
      @structure_element
    end

    protected def structure_element=(element : PDStructureElement?) : Nil
      @structure_element = element
    end

    # Notifies the attached structure element that this attribute changed, if any
    # (Java PDAttributeObject#notifyChanged).
    protected def notify_changed : Nil
      @structure_element.try(&.attribute_changed(self))
    end

    # Notifies the structure element only when the value actually changed
    # (Java PDAttributeObject#potentiallyNotifyChanged).
    protected def potentially_notify_changed(old_base : Cos::Base?, new_base : Cos::Base?) : Nil
      notify_changed if value_changed?(old_base, new_base)
    end

    private def value_changed?(old_value : Cos::Base?, new_value : Cos::Base?) : Bool
      return !new_value.nil? if old_value.nil?
      old_value != new_value
    end

    # Returns the owner of the attributes (/O).
    def owner : String?
      @dictionary.get_name_as_string(Cos::Name.new("O"))
    end

    protected def owner=(owner : String) : Nil
      @dictionary.set_name(Cos::Name.new("O"), owner)
    end

    # Detects whether there are no properties besides the owner.
    def empty? : Bool
      (@dictionary.size == 1) && !owner.nil?
    end

    def to_s(io : ::IO) : Nil
      io << "O=" << owner
    end
  end

  # An attribute object with an unknown owner (Java PDDefaultAttributeObject).
  class PDDefaultAttributeObject < PDAttributeObject
    def initialize
      super
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    # Returns the attribute names, excluding the owner (/O).
    # Java PDDefaultAttributeObject#getAttributeNames.
    def attribute_names : Array(::String)
      names = [] of ::String
      cos_object.entries.each_key do |key|
        next if key.value == "O"
        names << key.value
      end
      names
    end

    # Returns the value of the named attribute, or nil.
    # Java PDDefaultAttributeObject#getAttributeValue.
    def attribute_value(attr_name : ::String) : Cos::Base?
      cos_object.get_dictionary_object(Cos::Name.new(attr_name))
    end

    # Sets the named attribute and notifies the structure element on change.
    # Java PDDefaultAttributeObject#setAttribute.
    def set_attribute(attr_name : ::String, attr_value : Cos::Base) : Nil
      old = attribute_value(attr_name)
      cos_object.set_item(Cos::Name.new(attr_name), attr_value)
      potentially_notify_changed(old, attr_value)
    end
  end

  # An attribute object with user properties (Java PDUserAttributeObject).
  class PDUserAttributeObject < PDAttributeObject
    OWNER_USER_PROPERTIES = "UserProperties"

    def initialize
      super
      self.owner = OWNER_USER_PROPERTIES
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    # Java getOwnerUserProperties: the /P array as PDUserProperty objects.
    def user_properties : Array(PDUserProperty)
      array = cos_object.get_array(Cos::Name.new("P"))
      return [] of PDUserProperty unless array
      array.items.compact_map do |item|
        item = item.object if item.is_a?(Cos::Object)
        dict = item.as?(Cos::Dictionary)
        dict ? PDUserProperty.new(dict, self) : nil
      end
    end

    # Java setUserProperties: stores the list as the /P array.
    def user_properties=(user_properties : Array(PDUserProperty)) : Nil
      array = Cos::Array.new
      user_properties.each { |property| array.add(property.cos_object) }
      cos_object[Cos::Name.new("P")] = array
    end

    # Adds a user property to the /P array (Java addUserProperty).
    def add_user_property(user_property : PDUserProperty) : Nil
      key = Cos::Name.new("P")
      array = cos_object.get_array(key)
      unless array
        array = Cos::Array.new
        cos_object[key] = array
      end
      array.add(user_property.cos_object)
    end

    # Removes a user property from the /P array (Java removeUserProperty).
    def remove_user_property(user_property : PDUserProperty?) : Nil
      return unless user_property
      array = cos_object.get_array(Cos::Name.new("P"))
      return unless array
      array.remove_object(user_property.cos_object)
    end

    # Notify a possible change of user properties (Java userPropertyChanged).
    def user_property_changed(_user_property : PDUserProperty) : Nil
    end
  end
end

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
  end
end

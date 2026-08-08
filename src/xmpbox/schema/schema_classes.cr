require "./xmp_schema"

module Xmpbox
  module Schema
    # Dublin Core: http://purl.org/dc/elements/1.1/
    class DublinCoreSchema < XMPSchema
      CONTRIBUTOR = "contributor"
      COVERAGE    = "coverage"
      CREATOR     = "creator"
      DATE        = "date"
      DESCRIPTION = "description"
      FORMAT      = "format"
      IDENTIFIER  = "identifier"
      LANGUAGE    = "language"
      PUBLISHER   = "publisher"
      RELATION    = "relation"
      RIGHTS      = "rights"
      SOURCE      = "source"
      SUBJECT     = "subject"
      TITLE       = "title"
      TYPE        = "type"

      def self.structured_type_info
        {namespace: "http://purl.org/dc/elements/1.1/", prefered_prefix: "dc"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          CONTRIBUTOR => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Bag),
          COVERAGE    => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          CREATOR     => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Seq),
          DATE        => Type::PropertyTypeDesc.new(type: Type::Types::Date, card: Type::Cardinality::Seq),
          DESCRIPTION => Type::PropertyTypeDesc.new(type: Type::Types::LangAlt),
          FORMAT      => Type::PropertyTypeDesc.new(type: Type::Types::MIMEType),
          IDENTIFIER  => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          LANGUAGE    => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Bag),
          PUBLISHER   => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Bag),
          RELATION    => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Bag),
          RIGHTS      => Type::PropertyTypeDesc.new(type: Type::Types::LangAlt),
          SOURCE      => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          SUBJECT     => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Bag),
          TITLE       => Type::PropertyTypeDesc.new(type: Type::Types::LangAlt),
          TYPE        => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Bag),
        }
      end

      def coverage=(text : String) : Nil
        set_text_property_value(COVERAGE, text)
      end

      def coverage_property : Type::TextType?
        unqualified_text_property(COVERAGE)
      end

      def coverage : String?
        unqualified_text_property_value(COVERAGE)
      end

      def format=(mime_type : String) : Nil
        set_text_property_value(FORMAT, mime_type)
      end

      def format_property : Type::TextType?
        unqualified_text_property(FORMAT)
      end

      def format : String?
        unqualified_text_property_value(FORMAT)
      end

      def identifier=(text : String) : Nil
        set_text_property_value(IDENTIFIER, text)
      end

      def identifier_property : Type::TextType?
        unqualified_text_property(IDENTIFIER)
      end

      def identifier : String?
        unqualified_text_property_value(IDENTIFIER)
      end

      def source=(text : String) : Nil
        set_text_property_value(SOURCE, text)
      end

      def source_property : Type::TextType?
        unqualified_text_property(SOURCE)
      end

      def source : String?
        unqualified_text_property_value(SOURCE)
      end

      def title=(value : String) : Nil
        set_unqualified_language_property_value(TITLE, nil, value)
      end

      def set_title(lang : String, value : String) : Nil
        set_unqualified_language_property_value(TITLE, lang, value)
      end

      def title : String?
        unqualified_language_property_value(TITLE, nil)
      end

      def title(lang : String) : String?
        unqualified_language_property_value(TITLE, lang)
      end

      def description=(value : String) : Nil
        set_unqualified_language_property_value(DESCRIPTION, nil, value)
      end

      def description : String?
        unqualified_language_property_value(DESCRIPTION, nil)
      end

      def description(lang : String) : String?
        unqualified_language_property_value(DESCRIPTION, lang)
      end

      def description_languages : Array(String)?
        unqualified_language_property_languages_value(DESCRIPTION)
      end

      def add_contributor(contributor : String) : Nil
        add_unqualified_bag_value(CONTRIBUTOR, contributor)
      end

      def contributors : Array(String)?
        unqualified_bag_value_list(CONTRIBUTOR)
      end

      def add_creator(creator : String) : Nil
        add_unqualified_sequence_value(CREATOR, creator)
      end

      def creators : Array(String)?
        unqualified_sequence_value_list(CREATOR)
      end
    end

    # XMP Basic: http://ns.adobe.com/xap/1.0/
    class XMPBasicSchema < XMPSchema
      ADVISORY      = "Advisory"
      BASE_URL      = "BaseURL"
      CREATE_DATE   = "CreateDate"
      CREATOR_TOOL  = "CreatorTool"
      IDENTIFIER    = "Identifier"
      LABEL         = "Label"
      METADATA_DATE = "MetadataDate"
      MODIFY_DATE   = "ModifyDate"
      NICKNAME      = "Nickname"
      RATING        = "Rating"
      MODIFIER_DATE = "ModifierDate"
      THUMBNAILS    = "Thumbnails"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/", prefered_prefix: "xmp"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          ADVISORY      => Type::PropertyTypeDesc.new(type: Type::Types::XPath, card: Type::Cardinality::Bag),
          BASE_URL      => Type::PropertyTypeDesc.new(type: Type::Types::URL),
          CREATE_DATE   => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          CREATOR_TOOL  => Type::PropertyTypeDesc.new(type: Type::Types::AgentName),
          IDENTIFIER    => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Bag),
          LABEL         => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          METADATA_DATE => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          MODIFY_DATE   => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          NICKNAME      => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          RATING        => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          MODIFIER_DATE => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          THUMBNAILS    => Type::PropertyTypeDesc.new(type: Type::Types::Thumbnail, card: Type::Cardinality::Alt),
        }
      end

      def base_url=(url : String) : Nil
        set_text_property_value(BASE_URL, url)
      end

      def base_url : String?
        unqualified_text_property_value(BASE_URL)
      end

      def create_date=(date : Time) : Nil
        set_date_property_value(CREATE_DATE, date)
      end

      def create_date : Time?
        date_property_value(CREATE_DATE)
      end

      def metadata_date=(date : Time) : Nil
        set_date_property_value(METADATA_DATE, date)
      end

      def metadata_date : Time?
        date_property_value(METADATA_DATE)
      end

      def modify_date=(date : Time) : Nil
        set_date_property_value(MODIFY_DATE, date)
      end

      def modify_date : Time?
        date_property_value(MODIFY_DATE)
      end

      def creator_tool=(tool : String) : Nil
        set_text_property_value(CREATOR_TOOL, tool)
      end

      def creator_tool : String?
        unqualified_text_property_value(CREATOR_TOOL)
      end

      def label=(label : String) : Nil
        set_text_property_value(LABEL, label)
      end

      def label : String?
        unqualified_text_property_value(LABEL)
      end

      def nickname=(nickname : String) : Nil
        set_text_property_value(NICKNAME, nickname)
      end

      def nickname : String?
        unqualified_text_property_value(NICKNAME)
      end

      def rating=(rating : Int32) : Nil
        set_integer_property_value(RATING, rating)
      end

      def rating : Int32?
        integer_property_value(RATING)
      end

      def add_identifier(identifier : String) : Nil
        add_unqualified_bag_value(IDENTIFIER, identifier)
      end

      def identifiers : Array(String)?
        unqualified_bag_value_list(IDENTIFIER)
      end

      def add_advisory(advisory : String) : Nil
        add_unqualified_bag_value(ADVISORY, advisory)
      end

      def advisories : Array(String)?
        unqualified_bag_value_list(ADVISORY)
      end
    end

    # XMP Media Management: http://ns.adobe.com/xap/1.0/mm/
    class XMPMediaManagementSchema < XMPSchema
      DOCUMENT_ID          = "DocumentID"
      INSTANCE_ID          = "InstanceID"
      MANAGER              = "Manager"
      MANAGE_TO            = "ManageTo"
      MANAGE_UI            = "ManageUI"
      ORIGINAL_DOCUMENT_ID = "OriginalDocumentID"
      RENDITION_PARAMS     = "RenditionParams"
      RENDITION_CLASS      = "RenditionClass"
      VERSION_ID           = "VersionID"
      HISTORY              = "History"
      DERIVED_FROM         = "DerivedFrom"
      MANAGED_FROM         = "ManagedFrom"
      MANAGER_VARIANT      = "ManagerVariant"
      VERSIONS             = "Versions"
      LAST_URL             = "LastURL"
      RENDITION_OF         = "RenditionOf"
      SAVE_ID              = "SaveID"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/mm/", prefered_prefix: "xmpMM"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          DOCUMENT_ID          => Type::PropertyTypeDesc.new(type: Type::Types::URI),
          INSTANCE_ID          => Type::PropertyTypeDesc.new(type: Type::Types::URI),
          MANAGER              => Type::PropertyTypeDesc.new(type: Type::Types::AgentName),
          MANAGE_TO            => Type::PropertyTypeDesc.new(type: Type::Types::URI),
          MANAGE_UI            => Type::PropertyTypeDesc.new(type: Type::Types::URI),
          ORIGINAL_DOCUMENT_ID => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          RENDITION_PARAMS     => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          RENDITION_CLASS      => Type::PropertyTypeDesc.new(type: Type::Types::RenditionClass),
          VERSION_ID           => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          HISTORY              => Type::PropertyTypeDesc.new(type: Type::Types::ResourceEvent, card: Type::Cardinality::Seq),
          DERIVED_FROM         => Type::PropertyTypeDesc.new(type: Type::Types::ResourceRef),
          MANAGED_FROM         => Type::PropertyTypeDesc.new(type: Type::Types::ResourceRef),
          MANAGER_VARIANT      => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          VERSIONS             => Type::PropertyTypeDesc.new(type: Type::Types::Version, card: Type::Cardinality::Seq),
          LAST_URL             => Type::PropertyTypeDesc.new(type: Type::Types::URL),
          RENDITION_OF         => Type::PropertyTypeDesc.new(type: Type::Types::ResourceRef),
          SAVE_ID              => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
        }
      end

      def document_id=(value : String) : Nil
        set_text_property_value(DOCUMENT_ID, value)
      end

      def document_id : String?
        unqualified_text_property_value(DOCUMENT_ID)
      end

      def instance_id=(value : String) : Nil
        set_text_property_value(INSTANCE_ID, value)
      end

      def instance_id : String?
        unqualified_text_property_value(INSTANCE_ID)
      end

      def manager=(value : String) : Nil
        set_text_property_value(MANAGER, value)
      end

      def manager : String?
        unqualified_text_property_value(MANAGER)
      end

      def manage_to=(value : String) : Nil
        set_text_property_value(MANAGE_TO, value)
      end

      def manage_to : String?
        unqualified_text_property_value(MANAGE_TO)
      end

      def manage_ui=(value : String) : Nil
        set_text_property_value(MANAGE_UI, value)
      end

      def manage_ui : String?
        unqualified_text_property_value(MANAGE_UI)
      end

      def original_document_id=(value : String) : Nil
        set_text_property_value(ORIGINAL_DOCUMENT_ID, value)
      end

      def original_document_id : String?
        unqualified_text_property_value(ORIGINAL_DOCUMENT_ID)
      end

      def rendition_params=(value : String) : Nil
        set_text_property_value(RENDITION_PARAMS, value)
      end

      def rendition_params : String?
        unqualified_text_property_value(RENDITION_PARAMS)
      end

      def rendition_class=(value : String) : Nil
        set_text_property_value(RENDITION_CLASS, value)
      end

      def rendition_class : String?
        unqualified_text_property_value(RENDITION_CLASS)
      end

      def version_id=(value : String) : Nil
        set_text_property_value(VERSION_ID, value)
      end

      def version_id : String?
        unqualified_text_property_value(VERSION_ID)
      end

      def add_history(history : String) : Nil
        add_unqualified_sequence_value(HISTORY, history)
      end

      def history : Array(String)?
        unqualified_sequence_value_list(HISTORY)
      end
    end

    # XMP Rights Management: http://ns.adobe.com/xap/1.0/rights/
    class XMPRightsManagementSchema < XMPSchema
      CERTIFICATE   = "Certificate"
      MARKED        = "Marked"
      OWNER         = "Owner"
      USAGE_TERMS   = "UsageTerms"
      WEB_STATEMENT = "WebStatement"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/rights/", prefered_prefix: "xmpRights"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          CERTIFICATE   => Type::PropertyTypeDesc.new(type: Type::Types::URL),
          MARKED        => Type::PropertyTypeDesc.new(type: Type::Types::Boolean),
          OWNER         => Type::PropertyTypeDesc.new(type: Type::Types::ProperName, card: Type::Cardinality::Bag),
          USAGE_TERMS   => Type::PropertyTypeDesc.new(type: Type::Types::LangAlt),
          WEB_STATEMENT => Type::PropertyTypeDesc.new(type: Type::Types::URL),
        }
      end

      def certificate=(value : String) : Nil
        set_text_property_value(CERTIFICATE, value)
      end

      def certificate : String?
        unqualified_text_property_value(CERTIFICATE)
      end

      def web_statement=(value : String) : Nil
        set_text_property_value(WEB_STATEMENT, value)
      end

      def web_statement : String?
        unqualified_text_property_value(WEB_STATEMENT)
      end

      def marked=(value : Bool) : Nil
        set_boolean_property_value(MARKED, value)
      end

      def marked : Bool?
        boolean_property_value(MARKED)
      end

      def add_owner(owner : String) : Nil
        add_unqualified_bag_value(OWNER, owner)
      end

      def owners : Array(String)?
        unqualified_bag_value_list(OWNER)
      end

      def usage_terms=(value : String) : Nil
        set_unqualified_language_property_value(USAGE_TERMS, nil, value)
      end

      def usage_terms : String?
        unqualified_language_property_value(USAGE_TERMS, nil)
      end
    end

    # Adobe PDF: http://ns.adobe.com/pdf/1.3/
    class AdobePDFSchema < XMPSchema
      KEYWORDS    = "Keywords"
      PDF_VERSION = "PDFVersion"
      PRODUCER    = "Producer"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/pdf/1.3/", prefered_prefix: "pdf"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          KEYWORDS    => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          PDF_VERSION => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          PRODUCER    => Type::PropertyTypeDesc.new(type: Type::Types::Text),
        }
      end

      def keywords=(value : String) : Nil
        set_text_property_value(KEYWORDS, value)
      end

      def keywords_property : Type::TextType?
        unqualified_text_property(KEYWORDS)
      end

      def keywords : String?
        unqualified_text_property_value(KEYWORDS)
      end

      def pdf_version=(value : String) : Nil
        set_text_property_value(PDF_VERSION, value)
      end

      def pdf_version_property : Type::TextType?
        unqualified_text_property(PDF_VERSION)
      end

      def pdf_version : String?
        unqualified_text_property_value(PDF_VERSION)
      end

      def producer=(value : String) : Nil
        set_text_property_value(PRODUCER, value)
      end

      def producer_property : Type::TextType?
        unqualified_text_property(PRODUCER)
      end

      def producer : String?
        unqualified_text_property_value(PRODUCER)
      end
    end

    # PDF/A Identification: http://www.aiim.org/pdfa/ns/id/
    class PDFAIdentificationSchema < XMPSchema
      PART        = "part"
      AMD         = "amd"
      CONFORMANCE = "conformance"
      REV         = "rev"

      VALID_CONFORMANCE = {"A", "B", "U", "e", "f"}

      def self.structured_type_info
        {namespace: "http://www.aiim.org/pdfa/ns/id/", prefered_prefix: "pdfaid"}
      end

      # Port of Java @PropertyType annotations — used by TypeMapping to resolve
      # property types during strict parsing (mirrors TypeMapping.initializePropMapping).
      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          PART        => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          AMD         => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          CONFORMANCE => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          REV         => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
        }
      end

      def set_part_value_with_string(value : String) : Nil
        set_integer_property_value(PART, value.to_i32)
      end

      def set_part_value_with_int(value : Int32) : Nil
        set_integer_property_value(PART, value)
      end

      def set_part(value : Int32) : Nil
        set_part_value_with_int(value)
      end

      def part_property : Type::IntegerType?
        integer_property(PART)
      end

      def part : Int32?
        integer_property_value(PART)
      end

      def set_amd(value : String) : Nil
        set_text_property_value(AMD, value)
      end

      def amd_property : Type::TextType?
        unqualified_text_property(AMD)
      end

      def amendment : String?
        prop = abstract_property(AMD)
        if prop.is_a?(Type::TextType)
          return prop.string_value
        end
        nil
      end

      def amd : String?
        prop = amd_property
        if prop
          return prop.string_value
        end
        all_attributes.each do |attribute|
          return attribute.value if attribute.name == AMD
        end
        nil
      end

      def set_conformance(value : String) : Nil
        unless VALID_CONFORMANCE.includes?(value)
          raise Type::BadFieldValueException.new(
            "The value '#{value}' isn't a valid PDF/A conformance level (must be A, B, U, e or f)")
        end
        set_text_property_value(CONFORMANCE, value)
      end

      def conformance_property : Type::TextType?
        unqualified_text_property(CONFORMANCE)
      end

      def conformance : String?
        prop = conformance_property
        if prop
          return prop.string_value
        end
        all_attributes.each do |attribute|
          return attribute.value if attribute.name == CONFORMANCE
        end
        nil
      end

      def set_rev_value_with_string(value : String) : Nil
        set_integer_property_value(REV, value.to_i32)
      end

      def set_rev_value_with_int(value : Int32) : Nil
        set_integer_property_value(REV, value)
      end

      def set_rev(value : Int32) : Nil
        set_rev_value_with_int(value)
      end

      def rev_property : Type::IntegerType?
        integer_property(REV)
      end

      def rev : Int32?
        integer_property_value(REV)
      end
    end

    # PDF/A Extension: http://www.aiim.org/pdfa/ns/extension/
    class PDFAExtensionSchema < XMPSchema
      SCHEMAS = "schemas"

      def self.structured_type_info
        {namespace: "http://www.aiim.org/pdfa/ns/extension/", prefered_prefix: "pdfaExtension"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          SCHEMAS => Type::PropertyTypeDesc.new(type: Type::Types::PDFASchema, card: Type::Cardinality::Bag),
        }
      end

      def schemas_property : Type::ArrayProperty?
        array_property(SCHEMAS)
      end
    end

    # Photoshop: http://ns.adobe.com/photoshop/1.0/
    class PhotoshopSchema < XMPSchema
      AUTHORS_POSITION        = "AuthorsPosition"
      CAPTION_WRITER          = "CaptionWriter"
      CATEGORY                = "Category"
      CITY                    = "City"
      COLOR_MODE              = "ColorMode"
      COUNTRY                 = "Country"
      CREDIT                  = "Credit"
      DATE_CREATED            = "DateCreated"
      HEADLINE                = "Headline"
      HISTORY                 = "History"
      ICC_PROFILE             = "ICCProfile"
      INSTRUCTIONS            = "Instructions"
      SOURCE                  = "Source"
      STATE                   = "State"
      TRANSMISSION_REFERENCE  = "TransmissionReference"
      URGENCY                 = "Urgency"
      ANCESTOR_ID             = "AncestorID"
      DOCUMENT_ANCESTORS      = "DocumentAncestors"
      SUPPLEMENTAL_CATEGORIES = "SupplementalCategories"
      TEXT_LAYERS             = "TextLayers"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/photoshop/1.0/", prefered_prefix: "photoshop"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          ANCESTOR_ID             => Type::PropertyTypeDesc.new(type: Type::Types::URI),
          AUTHORS_POSITION        => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          CAPTION_WRITER          => Type::PropertyTypeDesc.new(type: Type::Types::ProperName),
          CATEGORY                => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          CITY                    => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          COLOR_MODE              => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          COUNTRY                 => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          CREDIT                  => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          DATE_CREATED            => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          DOCUMENT_ANCESTORS      => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Bag),
          HEADLINE                => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          HISTORY                 => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          ICC_PROFILE             => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          INSTRUCTIONS            => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          SOURCE                  => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          STATE                   => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          SUPPLEMENTAL_CATEGORIES => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          TEXT_LAYERS             => Type::PropertyTypeDesc.new(type: Type::Types::Layer, card: Type::Cardinality::Seq),
          TRANSMISSION_REFERENCE  => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          URGENCY                 => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
        }
      end

      def authors_position=(value : String) : Nil
        set_text_property_value(AUTHORS_POSITION, value)
      end

      def authors_position : String?
        unqualified_text_property_value(AUTHORS_POSITION)
      end

      def caption_writer=(value : String) : Nil
        set_text_property_value(CAPTION_WRITER, value)
      end

      def caption_writer : String?
        unqualified_text_property_value(CAPTION_WRITER)
      end

      def city=(value : String) : Nil
        set_text_property_value(CITY, value)
      end

      def city : String?
        unqualified_text_property_value(CITY)
      end

      def country=(value : String) : Nil
        set_text_property_value(COUNTRY, value)
      end

      def country : String?
        unqualified_text_property_value(COUNTRY)
      end

      def credit=(value : String) : Nil
        set_text_property_value(CREDIT, value)
      end

      def credit : String?
        unqualified_text_property_value(CREDIT)
      end

      def headline=(value : String) : Nil
        set_text_property_value(HEADLINE, value)
      end

      def headline : String?
        unqualified_text_property_value(HEADLINE)
      end

      def history=(value : String) : Nil
        set_text_property_value(HISTORY, value)
      end

      def history : String?
        unqualified_text_property_value(HISTORY)
      end

      def icc_profile=(value : String) : Nil
        set_text_property_value(ICC_PROFILE, value)
      end

      def icc_profile : String?
        unqualified_text_property_value(ICC_PROFILE)
      end

      def instructions=(value : String) : Nil
        set_text_property_value(INSTRUCTIONS, value)
      end

      def instructions : String?
        unqualified_text_property_value(INSTRUCTIONS)
      end

      def state=(value : String) : Nil
        set_text_property_value(STATE, value)
      end

      def state : String?
        unqualified_text_property_value(STATE)
      end

      def color_mode=(value : Int32) : Nil
        set_integer_property_value(COLOR_MODE, value)
      end

      def color_mode : Int32?
        integer_property_value(COLOR_MODE)
      end

      def urgency=(value : Int32) : Nil
        set_integer_property_value(URGENCY, value)
      end

      def urgency : Int32?
        integer_property_value(URGENCY)
      end

      def date_created=(date : Time) : Nil
        set_date_property_value(DATE_CREATED, date)
      end

      def date_created : Time?
        date_property_value(DATE_CREATED)
      end
    end

    # EXIF: http://ns.adobe.com/exif/1.0/
    class ExifSchema < XMPSchema
      USER_COMMENT                = "UserComment"
      EXIF_VERSION                = "ExifVersion"
      FLASH_PIX_VERSION           = "FlashpixVersion"
      COLOR_SPACE                 = "ColorSpace"
      COMPONENTS_CONFIGURATION    = "ComponentsConfiguration"
      COMPRESSED_BPP              = "CompressedBitsPerPixel"
      PIXEL_X_DIMENSION           = "PixelXDimension"
      PIXEL_Y_DIMENSION           = "PixelYDimension"
      RELATED_SOUND_FILE          = "RelatedSoundFile"
      DATE_TIME_ORIGINAL          = "DateTimeOriginal"
      DATE_TIME_DIGITIZED         = "DateTimeDigitized"
      EXPOSURE_TIME               = "ExposureTime"
      F_NUMBER                    = "FNumber"
      EXPOSURE_PROGRAM            = "ExposureProgram"
      SPECTRAL_SENSITIVITY        = "SpectralSensitivity"
      ISO_SPEED_RATINGS           = "ISOSpeedRatings"
      SHUTTER_SPEED_VALUE         = "ShutterSpeedValue"
      APERTURE_VALUE              = "ApertureValue"
      BRIGHTNESS_VALUE            = "BrightnessValue"
      EXPOSURE_BIAS_VALUE         = "ExposureBiasValue"
      MAX_APERTURE_VALUE          = "MaxApertureValue"
      SUBJECT_DISTANCE            = "SubjectDistance"
      METERING_MODE               = "MeteringMode"
      LIGHT_SOURCE                = "LightSource"
      FLASH_ENERGY                = "FlashEnergy"
      FOCAL_LENGTH                = "FocalLength"
      FOCAL_PLANE_XRESOLUTION     = "FocalPlaneXResolution"
      FOCAL_PLANE_YRESOLUTION     = "FocalPlaneYResolution"
      SUBJECT_AREA                = "SubjectArea"
      FOCAL_PLANE_RESOLUTION_UNIT = "FocalPlaneResolutionUnit"
      SUBJECT_LOCATION            = "SubjectLocation"
      EXPOSURE_INDEX              = "ExposureIndex"
      SENSING_METHOD              = "SensingMethod"
      FILE_SOURCE                 = "FileSource"
      SCENE_TYPE                  = "SceneType"
      CUSTOM_RENDERED             = "CustomRendered"
      WHITE_BALANCE               = "WhiteBalance"
      EXPOSURE_MODE               = "ExposureMode"
      DIGITAL_ZOOM_RATIO          = "DigitalZoomRatio"
      FOCAL_LENGTH_IN_3_5MM_FILM  = "FocalLengthIn35mmFilm"
      SCENE_CAPTURE_TYPE          = "SceneCaptureType"
      GAIN_CONTROL                = "GainControl"
      CONTRAST                    = "Contrast"
      SATURATION                  = "Saturation"
      SHARPNESS                   = "Sharpness"
      SUBJECT_DISTANCE_RANGE      = "SubjectDistanceRange"
      IMAGE_UNIQUE_ID             = "ImageUniqueID"
      GPSVERSION_ID               = "GPSVersionID"
      GPS_SATELLITES              = "GPSSatellites"
      GPS_STATUS                  = "GPSStatus"
      GPS_MEASURE_MODE            = "GPSMeasureMode"
      GPS_MAP_DATUM               = "GPSMapDatum"
      GPS_SPEED_REF               = "GPSSpeedRef"
      GPS_TRACK_REF               = "GPSTrackRef"
      GPS_IMG_DIRECTION_REF       = "GPSImgDirectionRef"
      GPS_DEST_BEARING_REF        = "GPSDestBearingRef"
      GPS_DEST_DISTANCE_REF       = "GPSDestDistanceRef"
      GPS_PROCESSING_METHOD       = "GPSProcessingMethod"
      GPS_AREA_INFORMATION        = "GPSAreaInformation"
      GPS_ALTITUDE                = "GPSAltitude"
      GPS_DOP                     = "GPSDOP"
      GPS_SPEED                   = "GPSSpeed"
      GPS_TRACK                   = "GPSTrack"
      GPS_IMG_DIRECTION           = "GPSImgDirection"
      GPS_DEST_BEARING            = "GPSDestBearing"
      GPS_DEST_DISTANCE           = "GPSDestDistance"
      GPS_ALTITUDE_REF            = "GPSAltitudeRef"
      GPS_DIFFERENTIAL            = "GPSDifferential"
      GPS_TIME_STAMP              = "GPSTimeStamp"
      OECF                        = "OECF"
      SPATIAL_FREQUENCY_RESPONSE  = "SpatialFrequencyResponse"
      GPS_LATITUDE                = "GPSLatitude"
      GPS_LONGITUDE               = "GPSLongitude"
      GPS_DEST_LATITUDE           = "GPSDestLatitude"
      GPS_DEST_LONGITUDE          = "GPSDestLongitude"
      CFA_PATTERN                 = "CFAPattern"
      FLASH                       = "Flash"
      CFA_PATTERN_TYPE            = "CFAPatternType"
      DEVICE_SETTING_DESCRIPTION  = "DeviceSettingDescription"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/exif/1.0/", prefered_prefix: "exif"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          USER_COMMENT                => Type::PropertyTypeDesc.new(type: Type::Types::LangAlt),
          EXIF_VERSION                => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          FLASH_PIX_VERSION           => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          COLOR_SPACE                 => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          COMPONENTS_CONFIGURATION    => Type::PropertyTypeDesc.new(type: Type::Types::Integer, card: Type::Cardinality::Seq),
          COMPRESSED_BPP              => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          PIXEL_X_DIMENSION           => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          PIXEL_Y_DIMENSION           => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          RELATED_SOUND_FILE          => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          DATE_TIME_ORIGINAL          => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          DATE_TIME_DIGITIZED         => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          EXPOSURE_TIME               => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          F_NUMBER                    => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          EXPOSURE_PROGRAM            => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          SPECTRAL_SENSITIVITY        => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          ISO_SPEED_RATINGS           => Type::PropertyTypeDesc.new(type: Type::Types::Integer, card: Type::Cardinality::Seq),
          SHUTTER_SPEED_VALUE         => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          APERTURE_VALUE              => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          BRIGHTNESS_VALUE            => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          EXPOSURE_BIAS_VALUE         => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          MAX_APERTURE_VALUE          => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          SUBJECT_DISTANCE            => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          METERING_MODE               => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          LIGHT_SOURCE                => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          FLASH_ENERGY                => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          FOCAL_LENGTH                => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          FOCAL_PLANE_XRESOLUTION     => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          FOCAL_PLANE_YRESOLUTION     => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          SUBJECT_AREA                => Type::PropertyTypeDesc.new(type: Type::Types::Integer, card: Type::Cardinality::Seq),
          FOCAL_PLANE_RESOLUTION_UNIT => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          SUBJECT_LOCATION            => Type::PropertyTypeDesc.new(type: Type::Types::Integer, card: Type::Cardinality::Seq),
          EXPOSURE_INDEX              => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          SENSING_METHOD              => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          FILE_SOURCE                 => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          SCENE_TYPE                  => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          CUSTOM_RENDERED             => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          WHITE_BALANCE               => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          EXPOSURE_MODE               => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          DIGITAL_ZOOM_RATIO          => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          FOCAL_LENGTH_IN_3_5MM_FILM  => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          SCENE_CAPTURE_TYPE          => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          GAIN_CONTROL                => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          CONTRAST                    => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          SATURATION                  => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          SHARPNESS                   => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          SUBJECT_DISTANCE_RANGE      => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          IMAGE_UNIQUE_ID             => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPSVERSION_ID               => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_SATELLITES              => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_STATUS                  => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_MEASURE_MODE            => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_MAP_DATUM               => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_SPEED_REF               => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_TRACK_REF               => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_IMG_DIRECTION_REF       => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_DEST_BEARING_REF        => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_DEST_DISTANCE_REF       => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_PROCESSING_METHOD       => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_AREA_INFORMATION        => Type::PropertyTypeDesc.new(type: Type::Types::Text),
          GPS_ALTITUDE                => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          GPS_DOP                     => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          GPS_SPEED                   => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          GPS_TRACK                   => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          GPS_IMG_DIRECTION           => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          GPS_DEST_BEARING            => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          GPS_DEST_DISTANCE           => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          GPS_ALTITUDE_REF            => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          GPS_DIFFERENTIAL            => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          GPS_TIME_STAMP              => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          OECF                        => Type::PropertyTypeDesc.new(type: Type::Types::OECF),
          SPATIAL_FREQUENCY_RESPONSE  => Type::PropertyTypeDesc.new(type: Type::Types::OECF),
          GPS_LATITUDE                => Type::PropertyTypeDesc.new(type: Type::Types::GPSCoordinate),
          GPS_LONGITUDE               => Type::PropertyTypeDesc.new(type: Type::Types::GPSCoordinate),
          GPS_DEST_LATITUDE           => Type::PropertyTypeDesc.new(type: Type::Types::GPSCoordinate),
          GPS_DEST_LONGITUDE          => Type::PropertyTypeDesc.new(type: Type::Types::GPSCoordinate),
          CFA_PATTERN                 => Type::PropertyTypeDesc.new(type: Type::Types::CFAPattern),
          FLASH                       => Type::PropertyTypeDesc.new(type: Type::Types::Flash),
          CFA_PATTERN_TYPE            => Type::PropertyTypeDesc.new(type: Type::Types::CFAPattern),
          DEVICE_SETTING_DESCRIPTION  => Type::PropertyTypeDesc.new(type: Type::Types::DeviceSettings),
        }
      end
    end

    # TIFF: http://ns.adobe.com/tiff/1.0/
    class TiffSchema < XMPSchema
      IMAGE_DESCRIPTION          = "ImageDescription"
      COPYRIGHT                  = "Copyright"
      ARTIST                     = "Artist"
      IMAGE_WIDTH                = "ImageWidth"
      IMAGE_LENGTH               = "ImageLength"
      BITS_PER_SAMPLE            = "BitsPerSample"
      COMPRESSION                = "Compression"
      PHOTOMETRIC_INTERPRETATION = "PhotometricInterpretation"
      ORIENTATION                = "Orientation"
      SAMPLES_PER_PIXEL          = "SamplesPerPixel"
      PLANAR_CONFIGURATION       = "PlanarConfiguration"
      YCBCR_SUB_SAMPLING         = "YCbCrSubSampling"
      YCBCR_POSITIONING          = "YCbCrPositioning"
      X_RESOLUTION               = "XResolution"
      Y_RESOLUTION               = "YResolution"
      RESOLUTION_UNIT            = "ResolutionUnit"
      TRANSFER_FUNCTION          = "TransferFunction"
      WHITE_POINT                = "WhitePoint"
      PRIMARY_CHROMATICITIES     = "PrimaryChromaticities"
      YCBCR_COEFFICIENTS         = "YCbCrCoefficients"
      REFERENCE_BLACK_WHITE      = "ReferenceBlackWhite"
      DATE_TIME                  = "DateTime"
      SOFTWARE                   = "Software"
      MAKE                       = "Make"
      MODEL                      = "Model"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/tiff/1.0/", prefered_prefix: "tiff"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          IMAGE_DESCRIPTION          => Type::PropertyTypeDesc.new(type: Type::Types::LangAlt),
          COPYRIGHT                  => Type::PropertyTypeDesc.new(type: Type::Types::LangAlt),
          ARTIST                     => Type::PropertyTypeDesc.new(type: Type::Types::ProperName),
          IMAGE_WIDTH                => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          IMAGE_LENGTH               => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          BITS_PER_SAMPLE            => Type::PropertyTypeDesc.new(type: Type::Types::Integer, card: Type::Cardinality::Seq),
          COMPRESSION                => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          PHOTOMETRIC_INTERPRETATION => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          ORIENTATION                => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          SAMPLES_PER_PIXEL          => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          PLANAR_CONFIGURATION       => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          YCBCR_SUB_SAMPLING         => Type::PropertyTypeDesc.new(type: Type::Types::Integer, card: Type::Cardinality::Seq),
          YCBCR_POSITIONING          => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          X_RESOLUTION               => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          Y_RESOLUTION               => Type::PropertyTypeDesc.new(type: Type::Types::Rational),
          RESOLUTION_UNIT            => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          TRANSFER_FUNCTION          => Type::PropertyTypeDesc.new(type: Type::Types::Integer, card: Type::Cardinality::Seq),
          WHITE_POINT                => Type::PropertyTypeDesc.new(type: Type::Types::Rational, card: Type::Cardinality::Seq),
          PRIMARY_CHROMATICITIES     => Type::PropertyTypeDesc.new(type: Type::Types::Rational, card: Type::Cardinality::Seq),
          YCBCR_COEFFICIENTS         => Type::PropertyTypeDesc.new(type: Type::Types::Rational, card: Type::Cardinality::Seq),
          REFERENCE_BLACK_WHITE      => Type::PropertyTypeDesc.new(type: Type::Types::Rational, card: Type::Cardinality::Seq),
          DATE_TIME                  => Type::PropertyTypeDesc.new(type: Type::Types::Date),
          SOFTWARE                   => Type::PropertyTypeDesc.new(type: Type::Types::AgentName),
          MAKE                       => Type::PropertyTypeDesc.new(type: Type::Types::ProperName),
          MODEL                      => Type::PropertyTypeDesc.new(type: Type::Types::ProperName),
        }
      end
    end

    # XMP Basic Job Ticket: http://ns.adobe.com/xap/1.0/bj/
    class XMPBasicJobTicketSchema < XMPSchema
      JOB_REF = "JobRef"

      @bag_jobs : Type::ArrayProperty?

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/bj/", prefered_prefix: "xmpBJ"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          JOB_REF => Type::PropertyTypeDesc.new(type: Type::Types::Job, card: Type::Cardinality::Bag),
        }
      end

      def add_job(id : String, name : String, url : String) : Nil
        add_job(id, name, url, nil)
      end

      def add_job(id : String, name : String, url : String, field_prefix : String?) : Nil
        if bag = @bag_jobs
          if field_prefix.nil?
            first = bag.container.all_properties.first?
            if first.is_a?(Type::JobType)
              field_prefix = first.prefix
            end
          end
        end
        job = Type::JobType.new(metadata, nil, field_prefix)
        job.id = id
        job.name = name
        job.url = url
        add_job(job)
      end

      def add_job(job : Type::JobType) : Nil
        prefix = namespace_prefix(job.namespace.to_s)
        if prefix
          job.prefix = prefix
          if bag = @bag_jobs
            bag.container.all_properties.each do |field|
              if field.is_a?(Type::JobType)
                field.prefix = prefix
              end
            end
          end
        else
          add_namespace(job.namespace.to_s, job.prefix.to_s)
        end
        if @bag_jobs.nil?
          @bag_jobs = create_array_property(JOB_REF, Type::Cardinality::Bag)
          add_property(@bag_jobs.as(Type::ArrayProperty))
        end
        @bag_jobs.as(Type::ArrayProperty).container.add_property(job)
      end

      def jobs : Array(Type::JobType)?
        prop = abstract_property(JOB_REF)
        unless prop.is_a?(Type::ArrayProperty)
          return nil
        end
        prop.container.all_properties.map do |abstract_field|
          unless abstract_field.is_a?(Type::JobType)
            raise Type::BadFieldValueException.new(
              "Job expected and #{abstract_field.class.name} found.")
          end
          abstract_field
        end
      end
    end

    # XMP Page Text: http://ns.adobe.com/xap/1.0/t/pg/
    class XMPPageTextSchema < XMPSchema
      MAX_PAGE_SIZE = "MaxPageSize"
      N_PAGES       = "NPages"
      PLATE_NAMES   = "PlateNames"
      COLORANTS     = "Colorants"
      FONTS         = "Fonts"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/t/pg/", prefered_prefix: "xmpTPg"}
      end

      def self.property_types : Hash(String, Type::PropertyTypeDesc)
        {
          MAX_PAGE_SIZE => Type::PropertyTypeDesc.new(type: Type::Types::Dimensions),
          N_PAGES       => Type::PropertyTypeDesc.new(type: Type::Types::Integer),
          PLATE_NAMES   => Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Seq),
          COLORANTS     => Type::PropertyTypeDesc.new(type: Type::Types::Colorant, card: Type::Cardinality::Seq),
          FONTS         => Type::PropertyTypeDesc.new(type: Type::Types::Font, card: Type::Cardinality::Bag),
        }
      end
    end
  end
end

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

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/", prefered_prefix: "xmp"}
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
      VERSION_ID           = "VersionID"
      HISTORY              = "History"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/mm/", prefered_prefix: "xmpMM"}
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
      def self.structured_type_info
        {namespace: "http://www.aiim.org/pdfa/ns/extension/", prefered_prefix: "pdfaExtension"}
      end
    end

    # Photoshop: http://ns.adobe.com/photoshop/1.0/
    class PhotoshopSchema < XMPSchema
      AUTHORS_POSITION       = "AuthorsPosition"
      CAPTION_WRITER         = "CaptionWriter"
      CATEGORY               = "Category"
      CITY                   = "City"
      COLOR_MODE             = "ColorMode"
      COUNTRY                = "Country"
      CREDIT                 = "Credit"
      DATE_CREATED           = "DateCreated"
      HEADLINE               = "Headline"
      HISTORY                = "History"
      ICC_PROFILE            = "ICCProfile"
      INSTRUCTIONS           = "Instructions"
      SOURCE                 = "Source"
      STATE                  = "State"
      TRANSMISSION_REFERENCE = "TransmissionReference"
      URGENCY                = "Urgency"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/photoshop/1.0/", prefered_prefix: "photoshop"}
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
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/exif/1.0/", prefered_prefix: "exif"}
      end
    end

    # TIFF: http://ns.adobe.com/tiff/1.0/
    class TiffSchema < XMPSchema
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/tiff/1.0/", prefered_prefix: "tiff"}
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
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/t/pg/", prefered_prefix: "xmpTPg"}
      end
    end
  end
end

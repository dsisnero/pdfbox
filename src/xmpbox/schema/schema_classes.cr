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
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/", prefered_prefix: "xmp"}
      end
    end

    # XMP Media Management: http://ns.adobe.com/xap/1.0/mm/
    class XMPMediaManagementSchema < XMPSchema
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/mm/", prefered_prefix: "xmpMM"}
      end
    end

    # XMP Rights Management: http://ns.adobe.com/xap/1.0/rights/
    class XMPRightsManagementSchema < XMPSchema
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/rights/", prefered_prefix: "xmpRights"}
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
      def self.structured_type_info
        {namespace: "http://www.aiim.org/pdfa/ns/id/", prefered_prefix: "pdfaid"}
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
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/photoshop/1.0/", prefered_prefix: "photoshop"}
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
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/bj/", prefered_prefix: "xmpBJ"}
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

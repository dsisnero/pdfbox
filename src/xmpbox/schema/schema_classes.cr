require "./xmp_schema"

module Xmpbox
  module Schema
    # Dublin Core: http://purl.org/dc/elements/1.1/
    class DublinCoreSchema < XMPSchema
      def self.structured_type_info
        {namespace: "http://purl.org/dc/elements/1.1/", prefered_prefix: "dc"}
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
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/pdf/1.3/", prefered_prefix: "pdf"}
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

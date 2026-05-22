require "./type/type_mapping"

module Xmpbox
  class XMPMetadata
    property xpacket_begin : String = XmpConstants::DEFAULT_XPACKET_BEGIN
    property xpacket_id : String = XmpConstants::DEFAULT_XPACKET_ID
    property xpacket_encoding : String = XmpConstants::DEFAULT_XPACKET_ENCODING
    property xpacket_end : String = XmpConstants::DEFAULT_XPACKET_END
    property xpacket_bytes : String?

    def initialize
      @schemas = {} of String => Schema::XMPSchema
      @type_mapping = Type::TypeMapping.new(self)
    end

    def type_mapping : Type::TypeMapping
      @type_mapping.as(Type::TypeMapping)
    end

    def self.create_xmp_metadata : XMPMetadata
      create_xmp_metadata(XmpConstants::DEFAULT_XPACKET_BEGIN, XmpConstants::DEFAULT_XPACKET_ID, nil, XmpConstants::DEFAULT_XPACKET_ENCODING)
    end

    def self.create_xmp_metadata(xpacket_begin : String, xpacket_id : String, xpacket_bytes : String?, xpacket_encoding : String) : XMPMetadata
      xmp = new
      xmp.xpacket_begin = xpacket_begin
      xmp.xpacket_id = xpacket_id
      xmp.xpacket_bytes = xpacket_bytes
      xmp.xpacket_encoding = xpacket_encoding
      {
        {"http://purl.org/dc/elements/1.1/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::DublinCoreSchema.new(m) }},
        {"http://ns.adobe.com/xap/1.0/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::XMPBasicSchema.new(m) }},
        {"http://ns.adobe.com/xap/1.0/mm/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::XMPMediaManagementSchema.new(m) }},
        {"http://ns.adobe.com/xap/1.0/rights/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::XMPRightsManagementSchema.new(m) }},
        {"http://ns.adobe.com/pdf/1.3/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::AdobePDFSchema.new(m) }},
        {"http://www.aiim.org/pdfa/ns/id/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::PDFAIdentificationSchema.new(m) }},
        {"http://www.aiim.org/pdfa/ns/extension/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::PDFAExtensionSchema.new(m) }},
        {"http://ns.adobe.com/photoshop/1.0/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::PhotoshopSchema.new(m) }},
        {"http://ns.adobe.com/exif/1.0/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::ExifSchema.new(m) }},
        {"http://ns.adobe.com/tiff/1.0/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::TiffSchema.new(m) }},
        {"http://ns.adobe.com/xap/1.0/bj/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::XMPBasicJobTicketSchema.new(m) }},
        {"http://ns.adobe.com/xap/1.0/t/pg/", ->(m : XMPMetadata, _p : String) : Type::AbstractStructuredType { Schema::XMPPageTextSchema.new(m) }},
      }.each do |_schema_ns, create_proc|
        xmp.type_mapping.register_schema(_schema_ns, create_proc)
      end
      xmp
    end

    # Schema accessors
    macro schema_helper(method_name, schema_class)
      def create_and_add_{{method_name}} : {{schema_class}}
        schema = {{schema_class}}.new(self)
        add_schema(schema)
        schema
      end

      def {{method_name}} : {{schema_class}}?
        @schemas.each_value do |s|
          return s.as({{schema_class}}) if s.is_a?({{schema_class}})
        end
        nil
      end
    end

    schema_helper dublin_core_schema, Schema::DublinCoreSchema
    schema_helper xmp_basic_schema, Schema::XMPBasicSchema
    schema_helper xmp_media_management_schema, Schema::XMPMediaManagementSchema
    schema_helper xmp_rights_management_schema, Schema::XMPRightsManagementSchema
    schema_helper adobe_pdf_schema, Schema::AdobePDFSchema
    schema_helper pdfa_identification_schema, Schema::PDFAIdentificationSchema
    schema_helper pdfa_extension_schema, Schema::PDFAExtensionSchema
    schema_helper photoshop_schema, Schema::PhotoshopSchema
    schema_helper exif_schema, Schema::ExifSchema
    schema_helper tiff_schema, Schema::TiffSchema
    schema_helper xmp_basic_job_ticket_schema, Schema::XMPBasicJobTicketSchema
    schema_helper xmp_page_text_schema, Schema::XMPPageTextSchema

    def schema(ns_uri : String) : Schema::XMPSchema?
      @schemas[ns_uri]?
    end

    def schema(prefix : String, ns_uri : String) : Schema::XMPSchema?
      @schemas[ns_uri]?
    end

    def all_schemas : Array(Schema::XMPSchema)
      @schemas.values
    end

    def add_schema(schema : Schema::XMPSchema) : Nil
      ns = schema.namespace
      return unless ns
      @schemas[ns] = schema
    end

    def remove_schema(ns_uri : String) : Nil
      @schemas.delete(ns_uri)
    end

    def clear_schemas : Nil
      @schemas.clear
    end
  end
end

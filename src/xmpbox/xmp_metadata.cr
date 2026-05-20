require "./type/type_mapping"

module Xmpbox
  class XMPMetadata
    def initialize
      @schemas = {} of String => Schema::XMPSchema
      @type_mapping = Type::TypeMapping.new(self)
      register_schemas
    end

    private def register_schemas : Nil
      {
        "http://purl.org/dc/elements/1.1/"       => Schema::DublinCoreSchema,
        "http://ns.adobe.com/xap/1.0/"           => Schema::XMPBasicSchema,
        "http://ns.adobe.com/xap/1.0/mm/"        => Schema::XMPMediaManagementSchema,
        "http://ns.adobe.com/xap/1.0/rights/"    => Schema::XMPRightsManagementSchema,
        "http://ns.adobe.com/pdf/1.3/"           => Schema::AdobePDFSchema,
        "http://www.aiim.org/pdfa/ns/id/"        => Schema::PDFAIdentificationSchema,
        "http://www.aiim.org/pdfa/ns/extension/" => Schema::PDFAExtensionSchema,
        "http://ns.adobe.com/photoshop/1.0/"     => Schema::PhotoshopSchema,
        "http://ns.adobe.com/exif/1.0/"          => Schema::ExifSchema,
        "http://ns.adobe.com/tiff/1.0/"          => Schema::TiffSchema,
        "http://ns.adobe.com/xap/1.0/bj/"        => Schema::XMPBasicJobTicketSchema,
        "http://ns.adobe.com/xap/1.0/t/pg/"      => Schema::XMPPageTextSchema,
      }.each do |ns, klass|
        @type_mapping.register_schema(ns, klass)
      end
    end

    def type_mapping : Type::TypeMapping
      @type_mapping
    end

    # Schema helpers
    macro create_schema_helper(method_name, schema_class)
      def create_and_add_{{method_name}} : {{schema_class}}
        schema = {{schema_class}}.new(self)
        add_schema(schema)
        schema
      end

      def {{method_name}} : {{schema_class}}?
        get_schema({{method_name.stringify}}).as?({{schema_class}})
      end
    end

    create_schema_helper dublin_core_schema, Schema::DublinCoreSchema
    create_schema_helper xmp_basic_schema, Schema::XMPBasicSchema
    create_schema_helper xmp_media_management_schema, Schema::XMPMediaManagementSchema
    create_schema_helper xmp_rights_management_schema, Schema::XMPRightsManagementSchema
    create_schema_helper adobe_pdf_schema, Schema::AdobePDFSchema
    create_schema_helper pdfa_identification_schema, Schema::PDFAIdentificationSchema
    create_schema_helper pdfa_extension_schema, Schema::PDFAExtensionSchema
    create_schema_helper photoshop_schema, Schema::PhotoshopSchema
    create_schema_helper exif_schema, Schema::ExifSchema
    create_schema_helper tiff_schema, Schema::TiffSchema
    create_schema_helper xmp_basic_job_ticket_schema, Schema::XMPBasicJobTicketSchema
    create_schema_helper xmp_page_text_schema, Schema::XMPPageTextSchema

    def schema(ns_uri : String) : Schema::XMPSchema?
      @schemas[ns_uri]?
    end

    def schema(klass : T.class) : T? forall T
      @schemas.each_value do |s|
        return s.as(T) if s.is_a?(T)
      end
      nil
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

    def self.create_xmp_metadata : XMPMetadata
      new
    end
  end
end

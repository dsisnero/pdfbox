require "../type"
require "../schema/schema_classes"
require "../xmp_constants"
require "../xmp_metadata"
require "./exceptions"

module Xmpbox
  module Xml
    module PdfaExtensionHelper
      CLOSED_CHOICE   = "closed Choice of "
      CLOSED_CHOICE_U = "Closed Choice of "
      OPEN_CHOICE     = "open Choice of "
      OPEN_CHOICE_U   = "Open Choice of "

      def self.validate_naming(meta : XMPMetadata, description : XML::Node) : Nil
        description.attributes.each do |attr|
          next unless attr.namespace
          check_namespace_declaration(attr, Type::PDFASchemaType)
          check_namespace_declaration(attr, Type::PDFAFieldType)
          check_namespace_declaration(attr, Type::PDFAPropertyType)
          check_namespace_declaration(attr, Type::PDFATypeType)
        end
      end

      private def self.check_namespace_declaration(attr : XML::Node, klass : Type::AbstractStructuredType.class) : Nil
        st_info = klass.structured_type_info
        return unless st_info
        cprefix = st_info[:prefered_prefix]
        cnamespace = st_info[:namespace]
        prefix = attr.namespace.try(&.prefix)
        return unless prefix
        namespace = attr.namespace.try(&.href) || ""

        if cprefix == prefix && cnamespace != namespace
          raise XmpParsingException.new(XmpParsingException::ErrorType::InvalidPdfaSchema,
            "Invalid PDF/A namespace definition, prefix: #{prefix}, namespace: #{namespace}")
        end
        if cnamespace == namespace && cprefix != prefix
          raise XmpParsingException.new(XmpParsingException::ErrorType::InvalidPdfaSchema,
            "Invalid PDF/A namespace definition, prefix: #{prefix}, namespace: #{namespace}")
        end
      end

      def self.populate_schema_mapping(meta : XMPMetadata, strict_parsing : Bool) : Nil
        schemas = meta.all_schemas
        tm = meta.type_mapping
        st_pdfa_ext = Type::PDFAExtensionSchema

        schemas.each do |xmp_schema|
          next unless xmp_schema.is_a?(Schema::PDFAExtensionSchema)
          st_info = st_pdfa_ext.structured_type_info
          next unless st_info

          if xmp_schema.namespace == st_info[:namespace]
            unless xmp_schema.prefix == st_info[:prefered_prefix]
              raise XmpParsingException.new(XmpParsingException::ErrorType::InvalidPrefix,
                "Found invalid prefix for PDF/A extension, found '#{xmp_schema.prefix}', should be '#{st_info[:prefered_prefix]}'")
            end

            pes = xmp_schema.as(Schema::PDFAExtensionSchema)
            sp = pes.array_property("schema")
            next unless sp

            sp.all_properties.each do |field|
              if field.is_a?(Type::PDFASchemaType)
                populate_pdfa_schema_type(meta, field.as(Type::PDFASchemaType), tm, strict_parsing)
              end
            end
          end
        end
      end

      private def self.populate_pdfa_schema_type(meta : XMPMetadata, st : Type::PDFASchemaType, tm : Type::TypeMapping, strict_parsing : Bool) : Nil
        namespace_uri = st.namespace_uri_value
        require_non_null(namespace_uri, "Missing pdfaSchema:namespaceURI in type definition")
        namespace_uri = namespace_uri.as(String).strip
        prefix = st.prefix_value
        properties = st.schema_property
        value_types = st.value_type_property

        xsf = tm.schema_factory(namespace_uri)
        if xsf.nil?
          tm.add_new_namespace(namespace_uri, prefix || "")
          xsf = tm.schema_factory(namespace_uri)
        end

        if value_types
          value_types.all_properties.each do |type_field|
            if type_field.is_a?(Type::PDFATypeType)
              populate_pdfa_type(meta, type_field.as(Type::PDFATypeType), tm)
            end
          end
        end

        if properties.nil?
          return unless strict_parsing
        end
        require_non_null(properties, "Missing pdfaSchema:property in type definition")
        properties = properties.as(Type::ArrayProperty)
        properties.all_properties.each do |prop_field|
          if prop_field.is_a?(Type::PDFAPropertyType)
            populate_pdfa_property_type(prop_field.as(Type::PDFAPropertyType), tm, xsf.as(Type::XMPSchemaFactory))
          end
        end
      end

      private def self.populate_pdfa_property_type(property : Type::PDFAPropertyType, tm : Type::TypeMapping, xsf : Type::XMPSchemaFactory) : Nil
        pname = property.name_value
        ptype = property.value_type
        require_non_null(pname, "Missing field 'name' in property definition")
        require_non_null(ptype, "Missing field 'valueType' in property definition")
        require_non_null(property.description, "Missing field 'description' in property definition")
        require_non_null(property.category, "Missing field 'category' in property definition")

        pt = transform_value_type(tm, ptype.as(String))
        unless pt
          raise XmpParsingException.new(XmpParsingException::ErrorType::NoValueType, "Unknown property value type : #{ptype}")
        end
        if pt.type.nil?
          raise XmpParsingException.new(XmpParsingException::ErrorType::NoValueType, "Type not defined : #{ptype}")
        elsif pt.type.simple? || pt.type.structured? || pt.type == Type::Types::DefinedType
          xsf.property_definition.add_new_property(pname.as(String), pt)
        else
          raise XmpParsingException.new(XmpParsingException::ErrorType::NoValueType, "Type not defined : #{ptype}")
        end
      end

      private def self.populate_pdfa_type(meta : XMPMetadata, type : Type::PDFATypeType, tm : Type::TypeMapping) : Nil
        ttype = type.type_value
        tns = type.namespace_uri_value
        tprefix = type.prefix_value

        require_non_null(ttype, "Missing field 'type' in type definition")
        require_non_null(tns, "Missing field 'namespaceURI' in type definition")
        require_non_null(tprefix, "Missing field 'prefix' in type definition")
        require_non_null(type.description, "Missing field 'description' in type definition")

        structured_type = Type::DefinedStructuredType.new(meta, tns, tprefix, nil)
        fields = type.field_property
        if fields
          fields.all_properties.each do |field3|
            if field3.is_a?(Type::PDFAFieldType)
              populate_pdfa_field_type(field3.as(Type::PDFAFieldType), structured_type)
            end
          end
        end

        pm = Type::PropertiesDescription.new
        structured_type.defined_properties.each do |dp_name, dp_type|
          pm.add_new_property(dp_name, dp_type)
        end
        tm.add_to_defined_structured_types(ttype.as(String), tns.as(String), pm)
      end

      private def self.populate_pdfa_field_type(field : Type::PDFAFieldType, structured_type : Type::DefinedStructuredType) : Nil
        f_name = field.name_value
        f_value_type = field.value_type

        require_non_null(f_name, "Missing field 'name' in field definition")
        require_non_null(field.description, "Missing field 'description' in field definition")
        require_non_null(f_value_type, "Missing field 'valueType' in field definition")

        begin
          f_value = Type::Types.parse(f_value_type.as(String))
          structured_type.add_property(f_name.as(String),
            Type::PropertyTypeDesc.new(type: f_value, card: Type::Cardinality::Simple))
        rescue ex : ArgumentError
          raise XmpParsingException.new(XmpParsingException::ErrorType::NoValueType,
            "Type not defined : #{f_value_type}")
        end
      end

      private def self.transform_value_type(tm : Type::TypeMapping, value_type : String) : Type::PropertyTypeDesc?
        if value_type == "Lang Alt"
          return Type::PropertyTypeDesc.new(type: Type::Types::LangAlt, card: Type::Cardinality::Simple)
        end

        vt = value_type

        if vt.starts_with?(CLOSED_CHOICE) || vt.starts_with?(CLOSED_CHOICE_U)
          vt = vt[CLOSED_CHOICE.size..]
        elsif vt.starts_with?(OPEN_CHOICE) || vt.starts_with?(OPEN_CHOICE_U)
          vt = vt[OPEN_CHOICE.size..]
        end

        pos = vt.index(' ')
        card = Type::Cardinality::Simple
        if pos
          scard = vt[0...pos].downcase
          card = case scard
                 when "seq" then Type::Cardinality::Seq
                 when "bag" then Type::Cardinality::Bag
                 when "alt" then Type::Cardinality::Alt
                 else
                   return nil
                 end
        end

        type_name = pos ? vt[(pos + 1)..] : vt
        begin
          t = Type::Types.parse(type_name)
          Type::PropertyTypeDesc.new(type: t, card: card)
        rescue ex : ArgumentError
          if tm.defined_type?(type_name)
            Type::PropertyTypeDesc.new(type: Type::Types::DefinedType, card: card)
          end
        end
      end

      private def self.require_non_null(value, message : String) : Nil
        if value.nil?
          raise XmpParsingException.new(XmpParsingException::ErrorType::RequiredProperty, message)
        end
      end
    end
  end
end

require "../type"
require "../xmp_constants"
require "../xmp_metadata"

module Xmpbox
  module Xml
    class XmpSerializer
      def initialize
      end

      def serialize(metadata : XMPMetadata, io : IO, with_xpacket : Bool = true) : Nil
        xml = build_xml(metadata, with_xpacket)
        io << xml
      end

      def serialize(metadata : XMPMetadata, with_xpacket : Bool = true) : String
        build_xml(metadata, with_xpacket)
      end

      private def build_xml(metadata : XMPMetadata, with_xpacket : Bool) : String
        String.build do |io|
          if with_xpacket
            io << "<?xpacket begin=\"" << metadata.xpacket_begin << "\" id=\"" << metadata.xpacket_id << "\"?>\n"
          end
          io << "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\">\n"
          io << "  <rdf:RDF xmlns:rdf=\"" << XmpConstants::RDF_NAMESPACE << "\">\n"

          metadata.all_schemas.each do |schema|
            serialize_schema(io, schema)
          end

          io << "  </rdf:RDF>\n"
          io << "</x:xmpmeta>\n"
          if with_xpacket
            io << "\n<?xpacket end=\"" << metadata.xpacket_end << "\"?>"
          else
            io << "\n"
          end
        end
      end

      private def serialize_schema(io : IO, schema : Schema::XMPSchema) : Nil
        prefix = schema.prefix || ""
        about = schema.about_value
        ns = schema.namespace || ""

        io << "    <rdf:Description"
        io << " rdf:about=\"" << escape_attr(about) << "\""
        io << " xmlns:" << prefix << "=\"" << escape_attr(ns) << "\""

        # Additional namespace declarations
        schema.all_namespaces_with_prefix.each do |ns_uri, ns_prefix|
          next if ns_prefix.empty?
          next if ns_prefix == prefix || ns_prefix == XmpConstants::DEFAULT_RDF_PREFIX
          io << " xmlns:" << ns_prefix << "=\"" << escape_attr(ns_uri) << "\""
        end

        io << ">\n"

        serialize_fields(io, schema.all_properties, 3, prefix, nil, true)

        io << "    </rdf:Description>\n"
      end

      private def serialize_fields(io : IO, fields : Array(Type::AbstractField), indent_level : Int32, resource_ns : String, local_prefix : String?, wrap_with_property : Bool) : Nil
        ind = "  " * indent_level
        use_prefix = local_prefix && !local_prefix.empty?

        fields.each do |field|
          if field.is_a?(Type::AbstractSimpleProperty)
            prefix = use_prefix ? local_prefix : (field.prefix || "")
            prop_name = field.property_name || ""

            attrs = build_xml_attribute_string(field.all_attributes)
            value = escape_text(field.string_value || "")
            io << ind << "<" << prefix << ":" << prop_name << attrs << ">"
            io << value
            io << "</" << prefix << ":" << prop_name << ">\n"
          elsif field.is_a?(Type::ArrayProperty)
            array = field.as(Type::ArrayProperty)
            arr_prefix = use_prefix ? local_prefix : (field.prefix || "")
            arr_name = field.property_name || ""

            io << ind << "<" << arr_prefix << ":" << arr_name << ">\n"
            io << "  " << ind << "<rdf:" << array.array_type.to_s.downcase << ">\n"

            inner_fields = array.all_properties
            serialize_fields(io, inner_fields, indent_level + 2, resource_ns, XmpConstants::DEFAULT_RDF_PREFIX, false)

            io << "  " << ind << "</rdf:" << array.array_type.to_s.downcase << ">\n"
            io << ind << "</" << arr_prefix << ":" << arr_name << ">\n"
          elsif field.is_a?(Type::AbstractStructuredType)
            structured = field.as(Type::AbstractStructuredType)
            st_name = field.property_name || ""

            list_parent_indent = indent_level
            if wrap_with_property
              io << ind << "<" << resource_ns << ":" << st_name << ">\n"
              list_parent_indent = indent_level + 1
            end

            inner_ind = "  " * list_parent_indent
            io << inner_ind << "<rdf:li rdf:parseType=\"Resource\">\n"

            inner_fields = structured.all_properties
            serialize_fields(io, inner_fields, list_parent_indent + 1, resource_ns, nil, true)

            io << inner_ind << "</rdf:li>\n"

            if wrap_with_property
              io << ind << "</" << resource_ns << ":" << st_name << ">\n"
            end
          end
        end
      end

      private def build_xml_attribute_string(attributes : Array(Type::Attribute)) : String
        String.build do |str|
          attributes.each do |attr|
            ns = attr.ns_uri
            name = attr.name
            value = attr.value
            if ns == "http://www.w3.org/XML/1998/namespace"
              str << " xml:" << name << "=\"" << escape_attr(value) << "\""
            end
          end
        end
      end

      private def escape_attr(str : String?) : String
        return "" unless str
        str
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub("\"", "&quot;")
      end

      private def escape_text(str : String?) : String
        return "" unless str
        str
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
      end
    end
  end
end

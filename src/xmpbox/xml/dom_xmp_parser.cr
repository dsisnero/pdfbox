require "xml"
require "../type"
require "../xmp_constants"
require "../xmp_metadata"
require "../schema/schema_classes"
require "./dom_helper"
require "./exceptions"
require "./namespace_finder"

module Xmpbox
  module Xml
    class DomXmpParser
      @strict_parsing : Bool
      @ns_finder : NamespaceFinder

      def initialize(@strict_parsing : Bool = true)
        @ns_finder = NamespaceFinder.new
      end

      def strict_parsing? : Bool
        @strict_parsing
      end

      def strict_parsing=(value : Bool) : Nil
        @strict_parsing = value
      end

      # Parse XMP from a byte array
      def parse(bytes : Bytes) : XMPMetadata
        parse(String.new(bytes))
      end

      # Parse XMP from an XML string
      def parse(xml_str : String) : XMPMetadata
        document = XML.parse(xml_str)
        parse_from_document(document)
      end

      # Parse XMP from an IO stream
      def parse(io : IO) : XMPMetadata
        document = XML.parse(io)
        parse_from_document(document)
      end

      private def parse_from_document(document : XML::Document) : XMPMetadata
        remove_comments_and_blanks(document)
        node = document.children.first?

        xmp : XMPMetadata?
        if node.nil? || !processing_instruction?(node)
          if @strict_parsing
            raise XmpParsingException.new(XmpParsingException::ErrorType::XpacketBadStart,
              "xmp should start with a processing instruction")
          end
          xmp = XMPMetadata.create_xmp_metadata
        else
          xmp = parse_initial_xpacket(node)
          node = next_sibling(node)
        end

        # Skip other processing instructions
        while node && processing_instruction?(node)
          node = next_sibling(node)
        end

        if node.nil? || !node.element?
          raise XmpParsingException.new(XmpParsingException::ErrorType::NoRootElement,
            "xmp should contain a root element")
        end

        root = node
        node = next_sibling(node)

        # Expect xpacket end
        if node.nil? || !processing_instruction?(node)
          if @strict_parsing
            raise XmpParsingException.new(XmpParsingException::ErrorType::XpacketBadEnd,
              "xmp should end with a processing instruction")
          end
        else
          parse_end_packet(xmp, node)
          node = next_sibling(node)
        end

        if node
          raise XmpParsingException.new(XmpParsingException::ErrorType::XpacketBadEnd,
            "xmp should end after xpacket end processing instruction")
        end

        # Parse content
        @ns_finder.push(root)
        rdf_rdf = find_descriptions_parent(root)
        @ns_finder.push(rdf_rdf)

        # Lenient mode: look for non-standard namespaces
        unless @strict_parsing
          rdf_rdf.namespace_definitions.each do |ns_def|
            next unless ns_def.prefix
            next if ns_def.prefix == "xmlns"
            next unless ns_def.href
            # Check if this is a non-standard namespace
            attr_node = rdf_rdf.children.find { |child_node| child_node.attribute? && child_node.name == ns_def.prefix }
            if attr_node
              maybe_add_non_standard_namespace(xmp, ns_def.href.as(String), ns_def.prefix.as(String))
            end
          end
        end

        descriptions = DomHelper.element_children(rdf_rdf)

        # Parse schema extensions first (pdfaExtension)
        descriptions.each do |desc|
          parse_schema_extensions(xmp, desc)
        end

        # Populate schema mappings
        # (PdfaExtensionHelper.populateSchemaMapping equivalent - skipped for now)

        # Parse data descriptions
        descriptions.each do |desc|
          parse_description_root(xmp, desc)
        end

        @ns_finder.pop
        @ns_finder.pop

        xmp
      end

      private def remove_comments_and_blanks(node : XML::Node) : Nil
        to_remove = [] of XML::Node
        walk_nodes(node) do |child|
          if child.comment? || (child.text? && child.content.strip.empty?)
            to_remove << child
          end
        end
        to_remove.each(&.unlink)
      end

      private def walk_nodes(node : XML::Node, &block : XML::Node ->) : Nil
        yield node
        node.children.each { |child| walk_nodes(child, &block) }
      end

      private def processing_instruction?(node : XML::Node) : Bool
        node.type == XML::Node::Type::PI_NODE
      end

      private def next_sibling(node : XML::Node) : XML::Node?
        node.next_sibling
      end

      private def maybe_add_non_standard_namespace(xmp : XMPMetadata, namespace : String, prefix : String) : Nil
        tm = xmp.type_mapping
        return if namespace == XmpConstants::RDF_NAMESPACE
        return if tm.structured_type_namespace?(namespace)
        return if xmp.schema(namespace)
        return if tm.schema_factory(namespace)
        tm.add_new_namespace(namespace, prefix)
      end

      private def find_descriptions_parent(root : XML::Node) : XML::Node
        # root should be rdf:RDF
        if root.name == XmpConstants::DEFAULT_RDF_LOCAL_NAME ||
           root.name == "#{XmpConstants::DEFAULT_RDF_PREFIX}:#{XmpConstants::DEFAULT_RDF_LOCAL_NAME}"
          return root
        end
        # Search children for rdf:RDF
        DomHelper.element_children(root).each do |child|
          if child.name == XmpConstants::DEFAULT_RDF_LOCAL_NAME ||
             child.name == "#{XmpConstants::DEFAULT_RDF_PREFIX}:#{XmpConstants::DEFAULT_RDF_LOCAL_NAME}"
            return child
          end
        end
        raise XmpParsingException.new(XmpParsingException::ErrorType::NoRootElement,
          "Can't find rdf:RDF element")
      end

      private def parse_initial_xpacket(pi : XML::Node) : XMPMetadata
        XMPMetadata.create_xmp_metadata
      end

      private def parse_end_packet(xmp : XMPMetadata, pi : XML::Node) : Nil
        # Extract end attribute
        # xmp.end_xpacket = pi["end"]? || XmpConstants::DEFAULT_XPACKET_END
      end

      private def parse_schema_extensions(xmp : XMPMetadata, description : XML::Node) : Nil
        tm = xmp.type_mapping
        @ns_finder.push(description)
        begin
          schema_extensions = DomHelper.element_children(description).select do |ext_elem|
            ext_elem.namespace.try(&.prefix) == "pdfaExtension"
          end
          schema_extensions.each do |ext|
            namespace = ext.namespace.try(&.href) || ""
            unless tm.defined_schema?(namespace)
              raise XmpParsingException.new(XmpParsingException::ErrorType::NoSchema,
                "This namespace is not from a schema: #{namespace}")
            end
            type = check_property_definition(tm, DomHelper.qname(ext), nil)
            factory = tm.schema_factory(namespace)
            next unless factory
            schema = factory.create_xmp_schema(xmp, ext.namespace.try(&.prefix) || "")
            xmp.add_schema(schema) if schema.is_a?(Xmpbox::Schema::XMPSchema)
            load_attributes(schema, description)
            container = schema.container
            create_property(xmp, ext, type, container)
          end
        ensure
          @ns_finder.pop
        end
      end

      private def parse_description_root(xmp : XMPMetadata, description : XML::Node) : Nil
        @ns_finder.push(description)
        tm = xmp.type_mapping
        begin
          properties = DomHelper.element_children(description)

          # Parse attributes as properties
          description.attributes.each do |attr|
            local_name = attr.name
            prefix = attr.namespace.try(&.prefix)
            next if local_name == XmpConstants::ABOUT_NAME &&
                    (prefix.nil? || prefix == XmpConstants::DEFAULT_RDF_PREFIX)
            next if prefix == "xmlns"
            parse_description_root_attr(xmp, description, attr, tm)
          end

          parse_children_as_properties(xmp, properties, tm, description)
        ensure
          @ns_finder.pop
        end
      end

      private def parse_description_root_attr(xmp : XMPMetadata, description : XML::Node, attr : XML::Node, tm : Type::TypeMapping) : Nil
        namespace = attr.namespace.try(&.href) || ""
        schema = xmp.schema(namespace)
        if schema.nil? && (factory = tm.schema_factory(namespace))
          schema = factory.create_xmp_schema(xmp, attr.namespace.try(&.prefix) || "")
          xmp.add_schema(schema) if schema.is_a?(Xmpbox::Schema::XMPSchema)
          load_attributes(schema, description)
        end

        return unless schema
        container = schema.container

        qn = Type::QName.new(
          attr.namespace.try(&.href) || "",
          attr.name,
          attr.namespace.try(&.prefix) || ""
        )
        type = check_property_definition(tm, qn, nil)

        if type.nil?
          if @strict_parsing
            raise XmpParsingException.new(XmpParsingException::ErrorType::InvalidType,
              "No type defined for {#{attr.namespace.try(&.href)}}#{attr.name}")
          end
          type = Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Simple)
        elsif !type.type.simple? || type.card.array? || type.type == Type::Types::LangAlt
          if @strict_parsing
            raise XmpParsingException.new(XmpParsingException::ErrorType::InvalidType,
              "The type '#{type.type}' in '#{attr.namespace.try(&.prefix)}:#{attr.name}=#{attr.content}' is a structured or array type")
          end
          if attr.content.empty?
            schema.remove_attribute(attr.name)
            return
          end
          type = Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Simple)
        end

        begin
          sp = tm.instanciate_simple_property(namespace, schema.prefix, attr.name, attr.content, type.type)
          container.add_property(sp)
        rescue ex : ArgumentError
          raise XmpParsingException.new(XmpParsingException::ErrorType::Format,
            "#{ex.message} in #{schema.prefix}:#{attr.name}")
        end
      end

      private def parse_children_as_properties(xmp : XMPMetadata, properties : Array(XML::Node), tm : Type::TypeMapping, description : XML::Node) : Nil
        properties.each do |property|
          @ns_finder.push(property)
          namespace = property.namespace.try(&.href) || ""
          type = check_property_definition(tm, DomHelper.qname(property), nil)

          unless tm.defined_schema?(namespace)
            if @strict_parsing
              raise XmpParsingException.new(XmpParsingException::ErrorType::NoSchema,
                "This namespace is not from a schema: #{namespace}")
            else
              # Lenient mode: register unknown namespace
              prefix = property.namespace.try(&.prefix) || ""
              tm.add_new_namespace(namespace, prefix) unless namespace.empty?
            end
          end

          next if property.namespace.try(&.prefix) == "pdfaExtension"

          schema = xmp.schema(namespace)
          if schema.nil?
            factory = tm.schema_factory(namespace)
            raise XmpParsingException.new(XmpParsingException::ErrorType::NoSchema, "No schema factory for: #{namespace}") unless factory
            schema = factory.create_xmp_schema(xmp, property.namespace.try(&.prefix) || "")
            xmp.add_schema(schema) if schema.is_a?(Xmpbox::Schema::XMPSchema)
            load_attributes(schema, description)
          end

          container = schema.container
          create_property(xmp, property, type, container)
          @ns_finder.pop
        end
      end

      private def create_property(xmp : XMPMetadata, property : XML::Node, type : Type::PropertyTypeDesc?, container : Type::ComplexPropertyContainer) : Nil
        prefix = property.namespace.try(&.prefix) || ""
        name = property.name
        namespace = property.namespace.try(&.href) || ""

        @ns_finder.push(property)
        begin
          if type.nil?
            if @strict_parsing
              raise XmpParsingException.new(XmpParsingException::ErrorType::InvalidType,
                "No type defined for {#{namespace}}#{name}")
            end
            # Lenient mode: check for array container child element
            if bag_or_seq = DomHelper.unique_element_child(property)
              card = detect_cardinality_from_name(bag_or_seq.name)
              if card && card.array?
                manage_array(xmp, property, Type::PropertyTypeDesc.new(type: Type::Types::Text, card: card), container)
              else
                manage_simple_type(xmp, property, Type::Types::Text, container)
              end
            else
              manage_simple_type(xmp, property, Type::Types::Text, container)
            end
          elsif type.type == Type::Types::LangAlt
            manage_lang_alt(xmp, property, container)
          elsif type.card.array?
            manage_array(xmp, property, type, container)
          elsif type.type.simple?
            manage_simple_type(xmp, property, type.type, container)
          elsif type.type.structured?
            manage_structured_type(xmp, property, prefix, container)
          elsif type.type == Type::Types::DefinedType
            manage_defined_type(xmp, property, prefix, container)
          end
        rescue ex : ArgumentError
          raise XmpParsingException.new(XmpParsingException::ErrorType::Format,
            "#{ex.message} in #{prefix}:#{name}")
        ensure
          @ns_finder.pop
        end
      end

      private def manage_simple_type(xmp : XMPMetadata, property : XML::Node, type : Type::Types, container : Type::ComplexPropertyContainer) : Nil
        tm = xmp.type_mapping
        prefix = property.namespace.try(&.prefix) || ""
        name = property.name
        namespace = property.namespace.try(&.href) || ""
        sp = tm.instanciate_simple_property(namespace, prefix, name, property.content, type)
        load_attributes(sp, property)
        container.add_property(sp)
      end

      private def manage_array(xmp : XMPMetadata, property : XML::Node, type : Type::PropertyTypeDesc, container : Type::ComplexPropertyContainer) : Nil
        tm = xmp.type_mapping
        prefix = property.namespace.try(&.prefix) || ""
        name = property.name
        namespace = property.namespace.try(&.href) || ""

        bag_or_seq = DomHelper.unique_element_child(property)
        if bag_or_seq.nil?
          first_child = property.children.first?
          unless @strict_parsing
            if first_child.nil?
              return # ignore
            end
            if first_child.text?
              manage_simple_type(xmp, property, Type::Types::Text, container)
              return
            end
          end
          what = first_child ? (first_child.text? ? "Text" : first_child.class.name) : "nothing"
          raise XmpParsingException.new(XmpParsingException::ErrorType::Format,
            "Invalid array definition, expecting #{type.card} and found #{what} [prefix=#{prefix}; name=#{name}]")
        end

        if @strict_parsing && bag_or_seq.name != type.card.to_s
          raise XmpParsingException.new(XmpParsingException::ErrorType::Format,
            "Invalid array type, expecting #{type.card} and found #{bag_or_seq.name} [prefix=#{prefix}; name=#{name}]")
        end

        array = tm.create_array_property(namespace, prefix, name, type.card)
        container.add_property(array)

        lis = DomHelper.element_children(bag_or_seq)
        lis.each do |element|
          property_qname = Type::QName.new("", element.name, "")
          ast = parse_li_element(xmp, property_qname, element, type.type)
          array.add_property(ast) if ast
        end
      end

      private def manage_lang_alt(xmp : XMPMetadata, property : XML::Node, container : Type::ComplexPropertyContainer) : Nil
        manage_array(xmp, property, Type::PropertyTypeDesc.new(type: Type::Types::LangAlt, card: Type::Cardinality::Alt), container)
      end

      private def manage_defined_type(xmp : XMPMetadata, property : XML::Node, prefix : String, container : Type::ComplexPropertyContainer) : Nil
        if DomHelper.parse_type_resource?(property)
          ast = parse_li_description(xmp, DomHelper.qname(property), property)
          raise XmpParsingException.new(XmpParsingException::ErrorType::Format,
            "property should contain child elements: #{property}") unless ast
          ast.prefix = prefix
          container.add_property(ast)
        else
          inner = DomHelper.first_child_element(property)
          raise XmpParsingException.new(XmpParsingException::ErrorType::Format,
            "property should contain child element: #{property}") unless inner
          ast = parse_li_description(xmp, DomHelper.qname(property), inner)
          raise XmpParsingException.new(XmpParsingException::ErrorType::Format,
            "inner element should contain child elements: #{inner}") unless ast
          ast.prefix = prefix
          container.add_property(ast)
        end
      end

      private def manage_structured_type(xmp : XMPMetadata, property : XML::Node, prefix : String, container : Type::ComplexPropertyContainer) : Nil
        if DomHelper.parse_type_resource?(property)
          ast = parse_li_description(xmp, DomHelper.qname(property), property)
          if ast
            ast.prefix = prefix
            container.add_property(ast)
          end
        else
          inner = DomHelper.first_child_element(property)
          if inner
            @ns_finder.push(inner)
            begin
              ast = parse_li_description(xmp, DomHelper.qname(property), inner)
              raise XmpParsingException.new(XmpParsingException::ErrorType::Format,
                "inner element should contain child elements: #{inner}") unless ast
              ast.prefix = prefix
              container.add_property(ast)
            ensure
              @ns_finder.pop
            end
          end
        end
      end

      private def parse_li_element(xmp : XMPMetadata, descriptor : Type::QName, li_element : XML::Node, type : Type::Types) : Type::AbstractField?
        if DomHelper.parse_type_resource?(li_element)
          @ns_finder.push(li_element)
          begin
            return parse_li_description(xmp, descriptor, li_element)
          ensure
            @ns_finder.pop
          end
        end

        li_child = DomHelper.unique_element_child(li_element)
        if li_child
          @ns_finder.push(li_element)
          @ns_finder.push(li_child)
          begin
            return parse_li_description(xmp, descriptor, li_child)
          ensure
            @ns_finder.pop
            @ns_finder.pop
          end
        end

        text = li_element.content
        tm = xmp.type_mapping

        if type.simple?
          af = tm.instanciate_simple_property(descriptor.namespace_uri, descriptor.prefix, descriptor.local_part, text, type)
          load_attributes(af, li_element)
          return af
        end

        # Assume structured
        af = tm.instanciate_structured_type(type, descriptor.local_part)
        load_attributes(af, li_element)
        pm = if type.structured?
               tm.structured_prop_mapping(type)
             else
               tm.defined_description_by_namespace(
                 li_element.namespace.try(&.href) || "",
                 li_element.name
               )
             end
        try_parse_attributes_as_properties(tm, li_element, af, pm, nil)
      end

      private def load_attributes(sp : Type::AbstractField, element : XML::Node) : Nil
        element.attributes.each do |attr|
          next if attr.namespace.try(&.prefix) == "xmlns"

          # Check for rdf:about
          about_prefix = XmpConstants::DEFAULT_RDF_PREFIX
          if attr.namespace.try(&.prefix) == about_prefix && attr.name == XmpConstants::ABOUT_NAME
            if sp.is_a?(Schema::XMPSchema)
              sp.set_about_as_simple(attr.content)
            end
            next
          end

          # xml: namespace attributes (xml:lang, etc.)
          if attr.namespace.try(&.href) == DomHelper::XML_NS_URI
            attribute = Type::Attribute.new(DomHelper::XML_NS_URI, attr.name, attr.content)
            sp.attribute = attribute
          end
        end
      end

      private def parse_li_description(xmp : XMPMetadata, parent_qname : Type::QName, li_desc_element : XML::Node) : Type::AbstractStructuredType?
        tm = xmp.type_mapping
        children = DomHelper.element_children(li_desc_element)

        if children.empty?
          return try_parse_attributes_as_properties(tm, li_desc_element, nil, nil, parent_qname)
        end

        first_child = children.first
        if first_child.name == "rdf:Description" || (first_child.namespace.try(&.prefix) == "rdf" && first_child.name == "Description")
          return parse_li_description(xmp, parent_qname, first_child)
        end

        @ns_finder.push(first_child)
        first_child_qname = DomHelper.qname(first_child)
        ctype = check_property_definition(tm, first_child_qname, parent_qname.local_part)

        unless ctype
          raise XmpParsingException.new(XmpParsingException::ErrorType::NoType,
            "Property '#{first_child_qname.prefix}:#{first_child_qname.local_part}' not defined in #{first_child_qname.namespace_uri}")
        end

        tt = ctype.type
        ast = instanciate_structured(tm, tt, parent_qname.local_part,
          first_child.namespace.try(&.href) || "")

        ast.namespace = first_child.namespace.try(&.href)
        ast.prefix = first_child.namespace.try(&.prefix)

        pm = if tt.structured?
               tm.structured_prop_mapping(tt)
             else
               tm.defined_description_by_namespace(
                 first_child.namespace.try(&.href) || "",
                 first_child.name
               )
             end

        children.each do |child|
          prefix = child.namespace.try(&.prefix) || ""
          name = child.name
          namespace = child.namespace.try(&.href) || ""
          type = pm.try(&.property_type(name))

          if type.nil?
            if @strict_parsing
              raise XmpParsingException.new(XmpParsingException::ErrorType::NoType,
                "Type '#{prefix}:#{name}' not defined in #{namespace}")
            end
            type = Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Simple)
          end

          if type.card.array?
            array = tm.create_array_property(namespace, prefix, name, type.card)
            ast.container.add_property(array)
            bag_or_seq = DomHelper.unique_element_child(child)
            if bag_or_seq
              lis = DomHelper.element_children(bag_or_seq)
              lis.each do |elem|
                ast2 = parse_li_element(xmp, parent_qname, elem, type.type)
                array.add_property(ast2) if ast2
              end
            end
          elsif type.type.simple?
            sp = tm.instanciate_simple_property(namespace, prefix, name, child.content, type.type)
            load_attributes(sp, child)
            ast.container.add_property(sp)
          elsif type.type.structured?
            inner = DomHelper.first_child_element(child)
            if inner
              @ns_finder.push(inner)
              begin
                ast2 = parse_li_description(xmp, parent_qname, inner)
                if ast2
                  ast2.prefix = prefix
                  ast.container.add_property(ast2)
                end
              ensure
                @ns_finder.pop
              end
            end
          elsif type.type == Type::Types::LangAlt
            inner_items = DomHelper.element_children(child)
            if inner_items.size == 1
              alt_array = tm.create_array_property(namespace, prefix, name, Type::Cardinality::Alt)
              alt_container = inner_items.first
              DomHelper.element_children(alt_container).each do |list_item|
                lang_value = tm.instanciate_simple_property(namespace, prefix, "li", list_item.content, Type::Types::Text)
                alt_array.add_property(lang_value)
              end
              ast.container.add_property(alt_array)
            end
          end
        end

        ast
      end

      private def try_parse_attributes_as_properties(tm : Type::TypeMapping, element : XML::Node, ast : Type::AbstractStructuredType?, pm : Type::PropertiesDescription?, parent_qname : Type::QName?) : Type::AbstractStructuredType?
        # If ast is nil, only try to build from parent type info
        if ast.nil? && parent_qname
          ctype = check_property_definition(tm, parent_qname, nil)
          if ctype
            ast = instanciate_structured(tm, ctype.type, parent_qname.local_part,
              parent_qname.namespace_uri)
          end
        end
        return nil unless ast

        # Parse XML attributes as properties
        element.attributes.each do |attr|
          prefix = attr.namespace.try(&.prefix)
          next if prefix.nil? || prefix == "xmlns" || prefix == "rdf"
          local_name = attr.name
          namespace = attr.namespace.try(&.href) || ""

          prop_type = pm.try(&.property_type(local_name))
          unless prop_type
            next unless @strict_parsing
            prop_type = Type::PropertyTypeDesc.new(type: Type::Types::Text, card: Type::Cardinality::Simple)
          end

          next unless prop_type
          sp = tm.instanciate_simple_property(namespace, prefix, local_name, attr.content, prop_type.type)
          ast.container.add_property(sp)
        end

        ast
      end

      private def check_property_definition(tm : Type::TypeMapping, qname : Type::QName, parent_type_name : String?) : Type::PropertyTypeDesc?
        tm.specified_property_type(qname, parent_type_name)
      end

      private def detect_cardinality_from_name(name : String) : Type::Cardinality?
        case name
        when "rdf:Bag", "Bag" then Type::Cardinality::Bag
        when "rdf:Seq", "Seq" then Type::Cardinality::Seq
        when "rdf:Alt", "Alt" then Type::Cardinality::Alt
        end
      end

      private def instanciate_structured(tm : Type::TypeMapping, type : Type::Types, name : String, namespace : String) : Type::AbstractStructuredType
        tm.instanciate_structured_type(type, name).tap do |ast|
          ast.namespace = namespace
        end
      rescue ex : Type::BadFieldValueException
        raise XmpParsingException.new(XmpParsingException::ErrorType::InvalidType,
          "Failed to instantiate structured type #{type}: #{ex.message}")
      end
    end
  end
end

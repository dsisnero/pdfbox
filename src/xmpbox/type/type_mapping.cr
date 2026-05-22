module Xmpbox
  module Type
    class TypeMapping
      getter metadata : XMPMetadata

      @structured_mappings : Hash(Types, PropertiesDescription)
      @structured_namespaces : Hash(String, Array(Types))
      @defined_structured_mappings : Hash(String, PropertiesDescription)
      @defined_structured_namespaces : Hash(String, Array(PropertiesDescription))
      @schema_map : Hash(String, XMPSchemaFactory)

      # Map from Types enum to implementing Crystal class
      STRUCTURED_TYPE_CLASSES = {
        Types::ResourceEvent  => ResourceEventType,
        Types::ResourceRef    => ResourceRefType,
        Types::Thumbnail      => ThumbnailType,
        Types::Font           => FontType,
        Types::Version        => VersionType,
        Types::Colorant       => ColorantType,
        Types::Layer          => LayerType,
        Types::Job            => JobType,
        Types::OECF           => OECFType,
        Types::CFAPattern     => CFAPatternType,
        Types::DeviceSettings => DeviceSettingsType,
        Types::Flash          => FlashType,
        Types::Dimensions     => DimensionsType,
        Types::PDFASchema     => PDFASchemaType,
        Types::PDFAField      => PDFAFieldType,
        Types::PDFAProperty   => PDFAPropertyType,
        Types::PDFAType       => PDFATypeType,
      } of Types => AbstractStructuredType.class

      SIMPLE_TYPE_CLASSES = {
        Types::Text           => TextType,
        Types::Date           => DateType,
        Types::Boolean        => BooleanType,
        Types::Integer        => IntegerType,
        Types::Real           => RealType,
        Types::ProperName     => ProperNameType,
        Types::Locale         => LocaleType,
        Types::AgentName      => AgentNameType,
        Types::GUID           => GUIDType,
        Types::XPath          => XPathType,
        Types::Part           => PartType,
        Types::URL            => URLType,
        Types::URI            => URIType,
        Types::Choice         => ChoiceType,
        Types::MIMEType       => MIMEType,
        Types::LangAlt        => TextType,
        Types::RenditionClass => RenditionClassType,
        Types::Rational       => RationalType,
        Types::GPSCoordinate  => TextType,
      } of Types => AbstractSimpleProperty.class

      def initialize(@metadata : XMPMetadata)
        @structured_mappings = {} of Types => PropertiesDescription
        @structured_namespaces = {} of String => Array(Types)
        @defined_structured_mappings = {} of String => PropertiesDescription
        @defined_structured_namespaces = {} of String => Array(PropertiesDescription)
        @schema_map = {} of String => XMPSchemaFactory
        init_structured_types
      end

      private def init_structured_types : Nil
        Types.each do |type|
          next unless type.structured?
          klass = STRUCTURED_TYPE_CLASSES[type]?
          next unless klass
          st_info = klass.structured_type_info
          next unless st_info
          ns = st_info[:namespace]
          pm = initialize_prop_mapping(klass)
          list = @structured_namespaces[ns]?
          if list
            list << type
          else
            @structured_namespaces[ns] = [type]
          end
          @structured_mappings[type] = pm
        end
      end

      # Called after schema classes are loaded to register them
      def register_schema(ns : String, create_proc : (XMPMetadata, String) -> AbstractStructuredType) : Nil
        pm = initialize_prop_mapping(AbstractStructuredType)
        @schema_map[ns] = XMPSchemaFactory.new(ns, create_proc, pm)
      end

      def add_to_defined_structured_types(type_name : String, ns : String, pm : PropertiesDescription) : Nil
        list = @defined_structured_namespaces[ns]?
        if list
          list << pm
        else
          @defined_structured_namespaces[ns] = [pm]
        end
        @defined_structured_mappings[type_name] = pm
      end

      def defined_description_by_namespace(namespace : String, field_name : String) : PropertiesDescription?
        prop_desc_list = @defined_structured_namespaces[namespace]?
        return nil unless prop_desc_list
        prop_desc_list.find(&.properties_names.includes?(field_name))
      end

      def instanciate_structured_type(type : Types, property_name : String) : AbstractStructuredType
        klass = STRUCTURED_TYPE_CLASSES[type]?
        raise BadFieldValueException.new("Unknown structured type: #{type}") unless klass
        tmp = klass.new(metadata, nil, nil, property_name)
        tmp
      end

      def instanciate_defined_type(property_name : String, namespace : String) : DefinedStructuredType
        DefinedStructuredType.new(metadata, namespace, nil, property_name)
      end

      def instanciate_simple_property(ns_uri : String?, prefix : String?, name : String?, value : ValueType, type : Types) : AbstractSimpleProperty
        klass = SIMPLE_TYPE_CLASSES[type]?
        raise ArgumentError.new("No implementing class for type: #{type}") unless klass
        klass.new(metadata, ns_uri, prefix, name, value)
      end

      def instanciate_simple_field(klass : T.class, ns_uri : String?, prefix : String?, property_name : String, value : ValueType) : AbstractSimpleProperty forall T
        pm = initialize_prop_mapping(klass)
        simple_type = pm.property_type(property_name)
        raise "No PropertyType for #{property_name}" unless simple_type
        instanciate_simple_property(ns_uri, prefix, property_name, value, simple_type.type)
      end

      def structured_type_namespace?(namespace : String) : Bool
        @structured_namespaces.has_key?(namespace)
      end

      def defined_type_namespace?(namespace : String) : Bool
        @defined_structured_namespaces.has_key?(namespace)
      end

      def defined_type?(name : String) : Bool
        @defined_structured_mappings.has_key?(name)
      end

      def add_new_namespace(ns : String, preferred : String) : Nil
        mapping = PropertiesDescription.new
        # Create a fallback factory that creates a generic XMPSchema
        @schema_map[ns] = XMPSchemaFactory.new(ns,
          ->(metadata : XMPMetadata, prefix : String) : AbstractStructuredType {
            Schema::XMPSchema.new(metadata, ns, prefix, nil)
          },
          mapping)
      end

      def structured_prop_mapping(type : Types) : PropertiesDescription?
        @structured_mappings[type]?
      end

      def schema_factory(namespace : String) : XMPSchemaFactory?
        @schema_map[namespace]?
      end

      def defined_schema?(namespace : String) : Bool
        @schema_map.has_key?(namespace)
      end

      def defined_namespace?(namespace : String) : Bool
        defined_schema?(namespace) || structured_type_namespace?(namespace) || defined_type_namespace?(namespace)
      end

      def specified_property_type(qname : QName, parent_type_name : String?) : PropertyTypeDesc?
        factory = schema_factory(qname.namespace_uri)
        if factory
          prop_type = factory.property_type(qname.local_part)
          return prop_type if prop_type
        end

        list = @structured_namespaces[qname.namespace_uri]?
        if list
          if list.size == 1
            st = list.first
            prop_desc = @structured_mappings[st]?
            if factory.nil? || (prop_desc && prop_desc.properties_names.includes?(qname.local_part))
              return PropertyTypeDesc.new(type: st, card: Cardinality::Simple)
            end
            return nil
          elsif list.size > 1
            list.each do |type|
              if type.to_s == parent_type_name
                return PropertyTypeDesc.new(type: type, card: Cardinality::Simple)
              end
            end
            list.each do |type|
              prop_desc = @structured_mappings[type]?
              if prop_desc && prop_desc.properties_names.includes?(qname.local_part)
                return PropertyTypeDesc.new(type: type, card: Cardinality::Simple)
              end
            end
          end
          return nil
        end

        if @defined_structured_namespaces.has_key?(qname.namespace_uri)
          return PropertyTypeDesc.new(type: Types::DefinedType, card: Cardinality::Simple)
        end

        # Check if namespace is known at all
        if defined_namespace?(qname.namespace_uri)
          return nil
        end

        if factory
          nil
        else
          # If the namespace is completely unknown, return nil to let lenient mode handle it
          nil
        end
      end

      def initialize_prop_mapping(klass : T.class) : PropertiesDescription forall T
        PropertiesDescription.new
      end

      # Convenience creators
      def create_boolean(ns_uri : String?, prefix : String?, property_name : String?, value : Bool) : BooleanType
        BooleanType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_date(ns_uri : String?, prefix : String?, property_name : String?, value : Time) : DateType
        DateType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_integer(ns_uri : String?, prefix : String?, property_name : String?, value : Int32) : IntegerType
        IntegerType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_real(ns_uri : String?, prefix : String?, property_name : String?, value : Float64) : RealType
        RealType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_text(ns_uri : String?, prefix : String?, property_name : String?, value : String) : TextType
        TextType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_proper_name(ns_uri : String?, prefix : String?, property_name : String?, value : String) : ProperNameType
        ProperNameType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_uri(ns_uri : String?, prefix : String?, property_name : String?, value : String) : URIType
        URIType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_url(ns_uri : String?, prefix : String?, property_name : String?, value : String) : URLType
        URLType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_rendition_class(ns_uri : String?, prefix : String?, property_name : String?, value : String) : RenditionClassType
        RenditionClassType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_part(ns_uri : String?, prefix : String?, property_name : String?, value : String) : PartType
        PartType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_mime_type(ns_uri : String?, prefix : String?, property_name : String?, value : String) : MIMEType
        MIMEType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_locale(ns_uri : String?, prefix : String?, property_name : String?, value : String) : LocaleType
        LocaleType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_guid(ns_uri : String?, prefix : String?, property_name : String?, value : String) : GUIDType
        GUIDType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_choice(ns_uri : String?, prefix : String?, property_name : String?, value : String) : ChoiceType
        ChoiceType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_agent_name(ns_uri : String?, prefix : String?, property_name : String?, value : String) : AgentNameType
        AgentNameType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_x_path(ns_uri : String?, prefix : String?, property_name : String?, value : String) : XPathType
        XPathType.new(metadata, ns_uri, prefix, property_name, value)
      end

      def create_array_property(namespace : String?, prefix : String?, property_name : String?, type : Cardinality) : ArrayProperty
        ArrayProperty.new(metadata, namespace, prefix, property_name, type)
      end
    end

    # QName equivalent
    struct QName
      getter namespace_uri : String
      getter local_part : String
      getter prefix : String

      def initialize(@namespace_uri : String, @local_part : String, @prefix : String = "")
      end
    end
  end
end

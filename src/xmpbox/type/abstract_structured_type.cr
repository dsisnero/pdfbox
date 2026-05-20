module Xmpbox
  module Type
    abstract class AbstractStructuredType < AbstractComplexProperty
      STRUCTURE_ARRAY_NAME = "li"

      @namespace_uri : String?
      @prefered_prefix : String?
      @prefix_str : String?

      def initialize(metadata : XMPMetadata)
        initialize(metadata, nil, nil, nil)
      end

      def initialize(metadata : XMPMetadata, namespace_uri : String?, field_prefix : String?, property_name : String?)
        super(metadata, property_name)
        st = self.class.structured_type_info
        if st
          @namespace_uri = st[:namespace]
          @prefered_prefix = st[:prefered_prefix]
        else
          raise ArgumentError.new("Both StructuredType annotation and namespace parameter cannot be null") unless namespace_uri
          @namespace_uri = namespace_uri
          @prefered_prefix = field_prefix
        end
        @prefix_str = field_prefix || @prefered_prefix
      end

      # Override in subclasses to provide namespace/prefix info
      # Returns {namespace: String, prefered_prefix: String} or nil
      def self.structured_type_info : NamedTuple(namespace: String, prefered_prefix: String)?
        nil
      end

      def namespace : String?
        @namespace_uri
      end

      def namespace=(ns : String?) : Nil
        @namespace_uri = ns
      end

      def prefix : String?
        @prefix_str
      end

      def prefix=(pf : String?) : Nil
        @prefix_str = pf
      end

      def prefered_prefix : String?
        @prefered_prefix
      end

      protected def add_simple_property(property_name : String, value : ValueType) : Nil
        tm = metadata.type_mapping
        asp = tm.instanciate_simple_field(self.class, nil, prefix, property_name, value)
        add_property(asp)
      end

      protected def property_value_as_string(field_name : String) : String?
        abs_prop = property(field_name)
        return nil unless abs_prop
        if asp = abs_prop.as?(AbstractSimpleProperty)
          asp.string_value
        end
      end

      protected def date_property_as_calendar(field_name : String) : Time?
        abs_prop = first_equivalent_property(field_name, DateType)
        return nil unless abs_prop
        if date_type = abs_prop.as?(DateType)
          date_type.value
        end
      end

      def create_text_type(property_name : String, value : String) : TextType
        metadata.type_mapping.create_text(namespace, prefix, property_name, value)
      end

      def create_array_property(property_name : String, type : Cardinality) : ArrayProperty
        metadata.type_mapping.create_array_property(namespace, prefix, property_name, type)
      end
    end
  end
end

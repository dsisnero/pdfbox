module Xmpbox
  module Type
    class XMPSchemaFactory
      getter namespace : String
      @create_proc : (XMPMetadata, String) -> AbstractStructuredType
      @prop_mapping : PropertiesDescription

      def initialize(@namespace : String, create_proc : (XMPMetadata, String) -> AbstractStructuredType,
                     prop_mapping : PropertiesDescription)
        @create_proc = create_proc
        @prop_mapping = prop_mapping
      end

      def property_definition : PropertiesDescription
        @prop_mapping
      end

      def property_type(name : String) : PropertyTypeDesc?
        @prop_mapping.property_type(name)
      end

      def properties_names : Array(String)
        @prop_mapping.properties_names
      end

      def create_xmp_schema(metadata : XMPMetadata, prefix : String) : AbstractStructuredType
        @create_proc.call(metadata, prefix)
      end
    end
  end
end

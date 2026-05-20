module Xmpbox
  module Type
    class XMPSchemaFactory
      getter namespace : String
      getter schema_class : Xmpbox::Type::AbstractStructuredType.class
      @prop_mapping : PropertiesDescription

      def initialize(@namespace : String, @schema_class : AbstractStructuredType.class, prop_mapping : PropertiesDescription)
        @prop_mapping = prop_mapping
      end

      def property_type(name : String) : PropertyTypeDesc?
        @prop_mapping.property_type(name)
      end

      def properties_names : Array(String)
        @prop_mapping.properties_names
      end
    end
  end
end

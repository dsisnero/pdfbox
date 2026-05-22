module Xmpbox
  module Type
    class DefinedStructuredType < AbstractStructuredType
      getter defined_properties : Hash(String, PropertyTypeDesc)

      def initialize(metadata : XMPMetadata, @namespace_uri : String?, prefered_prefix : String?, property_name : String?)
        super(metadata, @namespace_uri, prefered_prefix, property_name)
        @defined_properties = {} of String => PropertyTypeDesc
      end

      def add_property(name : String, type : PropertyTypeDesc) : Nil
        @defined_properties[name] = type
      end
    end
  end
end

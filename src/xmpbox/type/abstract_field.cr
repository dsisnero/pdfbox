require "./attribute"

module Xmpbox
  module Type
    abstract class AbstractField
      getter metadata : XMPMetadata
      property property_name : String?
      getter attributes : Hash(String, Attribute)

      def initialize(@metadata : XMPMetadata, @property_name : String?)
        @attributes = {} of String => Attribute
      end

      def attribute=(value : Attribute) : Nil
        @attributes[value.name] = value
      end

      def contains_attribute?(qualified_name : String) : Bool
        @attributes.has_key?(qualified_name)
      end

      def attribute(qualified_name : String) : Attribute?
        @attributes[qualified_name]?
      end

      def all_attributes : Array(Attribute)
        @attributes.values
      end

      def remove_attribute(qualified_name : String) : Nil
        @attributes.delete(qualified_name)
      end

      abstract def namespace : String?
      abstract def prefix : String?
    end
  end
end

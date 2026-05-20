require "./cardinality"

module Xmpbox
  module Type
    class ArrayProperty < AbstractComplexProperty
      getter array_type : Cardinality
      @namespace_uri : String?
      @prefix_str : String?

      def initialize(metadata : XMPMetadata, @namespace_uri : String?, @prefix_str : String?,
                     property_name : String?, @array_type : Cardinality)
        super(metadata, property_name)
      end

      def elements_as_string : Array(String)
        all_properties.map do |tmp|
          if asp = tmp.as?(AbstractSimpleProperty)
            asp.string_value.to_s
          else
            raise "Array element is not a simple property"
          end
        end
      end

      def namespace : String?
        @namespace_uri
      end

      def prefix : String?
        @prefix_str
      end
    end
  end
end

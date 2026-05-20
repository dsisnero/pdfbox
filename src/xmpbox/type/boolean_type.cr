module Xmpbox
  module Type
    class BooleanType < AbstractSimpleProperty
      @bool_value : Bool?

      def initialize(metadata : XMPMetadata, namespace_uri : String?, prefix_str : String?,
                     property_name : String?, value : ValueType)
        super(metadata, namespace_uri, prefix_str, property_name, value)
      end

      def value=(value : ValueType) : Nil
        case value
        when Bool
          @bool_value = value
        else
          raise ArgumentError.new("Value given is not allowed for the Boolean type: '#{value}'")
        end
      end

      def string_value : String?
        @bool_value.try(&.to_s)
      end

      def value : Bool?
        @bool_value
      end
    end
  end
end

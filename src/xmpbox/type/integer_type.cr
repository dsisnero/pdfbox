module Xmpbox
  module Type
    class IntegerType < AbstractSimpleProperty
      @int_value : Int32?

      def initialize(metadata : XMPMetadata, namespace_uri : String?, prefix_str : String?,
                     property_name : String?, value : ValueType)
        super(metadata, namespace_uri, prefix_str, property_name, value)
      end

      def value=(value : ValueType) : Nil
        case value
        when Int32, Int64
          @int_value = value.to_i32
        when String
          @int_value = value.to_i32
        else
          raise ArgumentError.new("Value given is not allowed for the Integer type: '#{value}'")
        end
      end

      def string_value : String?
        @int_value.try(&.to_s)
      end

      def value : Int32?
        @int_value
      end
    end
  end
end

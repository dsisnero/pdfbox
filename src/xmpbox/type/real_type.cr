module Xmpbox
  module Type
    class RealType < AbstractSimpleProperty
      @float_value : Float64?

      def initialize(metadata : XMPMetadata, namespace_uri : String?, prefix_str : String?,
                     property_name : String?, value : ValueType)
        super(metadata, namespace_uri, prefix_str, property_name, value)
      end

      def value=(value : ValueType) : Nil
        case value
        when Float32, Float64
          @float_value = value.to_f64
        when Int32, Int64
          @float_value = value.to_f64
        when String
          @float_value = value.to_f64
        else
          raise ArgumentError.new("Value given is not allowed for the Real type: '#{value}'")
        end
      end

      def string_value : String?
        @float_value.try(&.to_s)
      end

      def value : Float64?
        @float_value
      end
    end
  end
end

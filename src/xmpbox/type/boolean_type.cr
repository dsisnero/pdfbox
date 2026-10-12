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
        when String
          s = value.strip.upcase
          if s == "TRUE"
            @bool_value = true
          elsif s == "FALSE"
            @bool_value = false
          else
            # unknown value
            raise ArgumentError.new("Not a valid boolean value : '#{value}'")
          end
        else
          raise ArgumentError.new("Value given is not allowed for the Boolean type.")
        end
      end

      def string_value : String?
        # Java BooleanType.TRUE = "True", FALSE = "False".
        (@bool_value || false) ? "True" : "False"
      end

      def value : Bool?
        @bool_value
      end
    end
  end
end

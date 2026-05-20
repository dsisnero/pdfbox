module Xmpbox
  module Type
    class TextType < AbstractSimpleProperty
      @text_value : String?

      def initialize(metadata : XMPMetadata, namespace_uri : String?, prefix_str : String?,
                     property_name : String?, value : ValueType)
        super(metadata, namespace_uri, prefix_str, property_name, value)
      end

      def value=(value : ValueType) : Nil
        case value
        when String
          @text_value = value
        else
          raise ArgumentError.new("Value given is not allowed for the Text type: '#{value}'")
        end
      end

      def string_value : String?
        @text_value
      end

      def value : String?
        @text_value
      end
    end
  end
end

module Xmpbox
  module Type
    abstract class AbstractSimpleProperty < AbstractField
      getter namespace_uri : String?
      getter prefix_str : String?
      getter raw_value : ValueType

      def initialize(metadata : XMPMetadata, @namespace_uri : String?, @prefix_str : String?,
                     property_name : String?, value : ValueType)
        super(metadata, property_name)
        @raw_value = value
        self.value = value
      end

      abstract def value=(value : ValueType)
      abstract def string_value : String?
      abstract def value : ValueType

      def namespace : String?
        @namespace_uri
      end

      def prefix : String?
        @prefix_str
      end

      def to_s(io : IO) : Nil
        io << '[' << @property_name << "=TextType:" << string_value << ']'
      end
    end
  end
end

# Alias for the various value types used in XMP simple properties
alias AbstractSimplePropertyValue = String | Int32 | Int64 | Float32 | Float64 | Bool | Time | Nil
alias ValueType = AbstractSimplePropertyValue

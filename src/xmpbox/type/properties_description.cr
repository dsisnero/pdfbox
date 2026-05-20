module Xmpbox
  module Type
    class PropertiesDescription
      getter types : Hash(String, PropertyTypeDesc)

      def initialize
        @types = {} of String => PropertyTypeDesc
      end

      def properties_names : Array(String)
        @types.keys
      end

      def add_new_property(name : String, type : PropertyTypeDesc) : Nil
        @types[name] = type
      end

      def property_type(name : String) : PropertyTypeDesc?
        @types[name]?
      end

      def to_s(io : IO) : Nil
        io << "PropertiesDescription{types=" << @types.to_s << '}'
      end
    end
  end
end

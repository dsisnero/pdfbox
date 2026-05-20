module Xmpbox
  module Type
    class Attribute
      property ns_uri : String?
      property name : String
      property value : String

      def initialize(@ns_uri : String?, @name : String, @value : String)
      end

      def to_s(io : IO) : Nil
        io << "[attr:{" << @ns_uri << "}" << @name << "=" << @value << "]"
      end
    end
  end
end

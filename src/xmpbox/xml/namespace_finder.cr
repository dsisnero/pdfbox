module Xmpbox
  module Xml
    class NamespaceFinder
      @stack : Array(Hash(String, String))

      def initialize
        @stack = [] of Hash(String, String)
      end

      # Push namespaces from an XML element onto the stack
      def push(element : XML::Node) : Nil
        map = {} of String => String
        element.namespace_definitions.each do |ns_def|
          if href = ns_def.href
            map[href] = ns_def.prefix || ""
          end
        end
        @stack << map
      end

      def pop : Hash(String, String)?
        @stack.pop?
      end

      def contains_namespace?(namespace : String) : Bool
        @stack.each do |mapping|
          return true if mapping.has_key?(namespace)
        end
        false
      end
    end
  end
end

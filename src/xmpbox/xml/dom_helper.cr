require "xml"

module Xmpbox
  module Xml
    module DomHelper
      XML_NS_URI     = "http://www.w3.org/XML/1998/namespace"
      RDF_RESOURCE_Q = "rdf:resource"
      PARSE_TYPE_RES = "Resource"

      # Returns all element children of a node
      def self.element_children(node : XML::Node) : Array(XML::Node)
        node.children.select(&.element?)
      end

      # Returns the first child element of a node
      def self.first_child_element(node : XML::Node) : XML::Node?
        node.first_element_child
      end

      # Returns the unique element child (first element child, or nil if multiple/none)
      def self.unique_element_child(node : XML::Node) : XML::Node?
        elems = element_children(node)
        elems.size == 1 ? elems.first : nil
      end

      # Check if a node has parseType="Resource"
      def self.parse_type_resource?(node : XML::Node) : Bool
        node[PARSE_TYPE_RES]? == "Resource"
      rescue KeyError
        false
      end

      # Build a QName from an XML element
      def self.qname(element : XML::Node) : Type::QName
        ns = element.namespace
        Type::QName.new(
          ns.try(&.href) || "",
          ns.try(&.prefix) || "",
          element.name
        )
      end
    end
  end
end

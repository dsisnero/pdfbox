require "xml"

module Pdfbox::Util
  # Simple XML operations: parse an XML stream into a document, and get the
  # text value of an element (direct text children only).
  # Java: org.apache.pdfbox.util.XMLUtil
  class XMLUtil
    # This will parse an XML stream and create a document.
    def self.parse(io : ::IO) : XML::Node
      XML.parse(io)
    end

    # This will parse an XML string and create a document.
    def self.parse(xml : String) : XML::Node
      XML.parse(xml)
    end

    # This will get the text value of an element — the concatenated text of its
    # direct text children (Java getNodeValue; descendant elements excluded).
    def self.get_node_value(node : XML::Node) : String
      sb = String::Builder.new
      node.children.each do |child|
        sb << child.text if child.text?
      end
      sb.to_s
    end
  end
end

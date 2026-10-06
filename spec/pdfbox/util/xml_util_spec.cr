require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/util/XMLUtil.java
#
# XMLUtil.parse parses an XML stream into a DOM document (with entity/DTD
# expansion disabled — the Crystal XML binding parses securely by default and
# the xmpbox parser uses it). getNodeValue returns the concatenated text of an
# element's text children.

module Pdfbox::Util
  describe XMLUtil do
    it "parses an XML stream into a document" do
      xml = "<root><child>hello</child></root>"
      doc = XMLUtil.parse(::IO::Memory.new(xml))
      root = doc.root
      root.should_not be_nil
      root.not_nil!.name.should eq("root")
    end

    it "parses XML with a namespace declaration" do
      xml = %(<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description/></rdf:RDF>)
      doc = XMLUtil.parse(::IO::Memory.new(xml))
      root = doc.root
      root.should_not be_nil
      # Crystal's XML binding is namespace-aware: the name is the local part and
      # the namespace href is exposed (used by the xmpbox parser).
      root.not_nil!.name.should eq("RDF")
      root.not_nil!.namespace.not_nil!.href.should eq("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
    end

    it "getNodeValue returns the concatenated text children" do
      xml = "<a>foo<b/>bar</a>"
      doc = XMLUtil.parse(::IO::Memory.new(xml))
      a = doc.root.not_nil!
      XMLUtil.get_node_value(a).should eq("foobar")
    end

    it "getNodeValue excludes text of descendant elements (Java parity)" do
      xml = "<a>foo<b>inner</b>bar</a>"
      doc = XMLUtil.parse(::IO::Memory.new(xml))
      XMLUtil.get_node_value(doc.root.not_nil!).should eq("foobar")
    end

    it "getNodeValue returns empty string for an element with no text" do
      xml = "<a><b/></a>"
      doc = XMLUtil.parse(::IO::Memory.new(xml))
      XMLUtil.get_node_value(doc.root.not_nil!).should eq("")
    end
  end
end

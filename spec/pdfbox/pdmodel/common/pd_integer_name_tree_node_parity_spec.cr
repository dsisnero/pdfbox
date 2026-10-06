require "../../../spec_helper"
require "../../../helpers/pd_integer_name_tree_node"

# Source of truth:
# vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/PDIntegerNameTreeNode.java
#
# PDIntegerNameTreeNode is a name-tree node whose values are COS integers.
# Ports convertCOSToPD (raises IO::Error on non-integer, matching Java's
# IOException "integer expected here") and createChildNode.

module Pdfbox::Pdmodel::Common
  describe PDIntegerNameTreeNode do
    it "PDIntegerNameTreeNode.convertCOSToPD raises on a non-integer value" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("Names")] = Pdfbox::Cos::Array.new([
        Pdfbox::Cos::String.new("k"),
        Pdfbox::Cos::String.new("not-an-integer"),
      ])
      node = PDIntegerNameTreeNode.new(dict)
      expect_raises(::IO::Error, /integer expected here/) do
        node.value("k")
      end
    end

    it "PDIntegerNameTreeNode.createChildNode returns a PDIntegerNameTreeNode" do
      child = PDIntegerNameTreeNode.new
      child.names = {"a" => Pdfbox::Cos::Integer.new(10)}
      root = PDIntegerNameTreeNode.new
      root.kids = [child]
      root.cos_object.has_key?(Pdfbox::Cos::Name::KIDS).should be_true
    end

    it "converts a COS integer value and reports nil for missing keys" do
      node = PDIntegerNameTreeNode.new
      node.names = {"one" => Pdfbox::Cos::Integer.new(1), "two" => Pdfbox::Cos::Integer.new(2)}
      node.value("one").should eq(Pdfbox::Cos::Integer.new(1))
      node.value("two").should eq(Pdfbox::Cos::Integer.new(2))
      node.value("three").should be_nil
    end
  end
end

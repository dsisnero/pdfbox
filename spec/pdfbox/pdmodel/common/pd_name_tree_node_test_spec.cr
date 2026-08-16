require "../../../spec_helper"
require "../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/TestPDNameTreeNode.java
# Uses a PDIntegerNameTreeNode (PDNameTreeNode<COSInteger>) like the Java test.
private class PDIntegerNameTreeNode < Pdfbox::Pdmodel::Common::PDNameTreeNode(Pdfbox::Cos::Integer)
  def initialize
    super
  end

  def initialize(dict : Pdfbox::Cos::Dictionary)
    super(dict)
  end

  protected def convert_cos_to_pd(base : Pdfbox::Cos::Base) : Pdfbox::Cos::Integer
    base.as(Pdfbox::Cos::Integer)
  end

  protected def create_child_node(dic : Pdfbox::Cos::Dictionary) : Pdfbox::Pdmodel::Common::PDNameTreeNode(Pdfbox::Cos::Integer)
    PDIntegerNameTreeNode.new(dic)
  end
end

private def build_name_tree
  node5 = PDIntegerNameTreeNode.new
  names5 = {"Actinium" => Pdfbox::Cos::Integer.new(89), "Aluminum" => Pdfbox::Cos::Integer.new(13),
            "Americium" => Pdfbox::Cos::Integer.new(95), "Antimony" => Pdfbox::Cos::Integer.new(51),
            "Argon" => Pdfbox::Cos::Integer.new(18), "Arsenic" => Pdfbox::Cos::Integer.new(33),
            "Astatine" => Pdfbox::Cos::Integer.new(85)}
  node5.names = names5

  node24 = PDIntegerNameTreeNode.new
  names24 = {"Xenon" => Pdfbox::Cos::Integer.new(54), "Ytterbium" => Pdfbox::Cos::Integer.new(70),
             "Yttrium" => Pdfbox::Cos::Integer.new(39), "Zinc" => Pdfbox::Cos::Integer.new(30),
             "Zirconium" => Pdfbox::Cos::Integer.new(40)}
  node24.names = names24

  node2 = PDIntegerNameTreeNode.new
  node2.kids = [node5]

  node4 = PDIntegerNameTreeNode.new
  node4.kids = [node24]

  node1 = PDIntegerNameTreeNode.new
  node1.kids = [node2, node4]

  {node1, node2, node4, node5, node24}
end

describe Pdfbox::Pdmodel::Common::PDNameTreeNode do
  it "TestPDNameTreeNode#testUpperLimit" do
    _node1, node2, node4, node5, node24 = build_name_tree

    node5.upper_limit.should eq("Astatine")
    node2.upper_limit.should eq("Astatine")

    node24.upper_limit.should eq("Zirconium")
    node4.upper_limit.should eq("Zirconium")

    _node1.upper_limit.should be_nil
  end

  it "TestPDNameTreeNode#testLowerLimit" do
    _node1, node2, node4, node5, node24 = build_name_tree

    node5.lower_limit.should eq("Actinium")
    node2.lower_limit.should eq("Actinium")

    node24.lower_limit.should eq("Xenon")
    node4.lower_limit.should eq("Xenon")

    _node1.lower_limit.should be_nil
  end
end

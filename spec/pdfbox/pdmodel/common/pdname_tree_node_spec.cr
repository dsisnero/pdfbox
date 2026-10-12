require "../../../spec_helper"
require "../../../helpers/pd_integer_name_tree_node"

# Source of truth:
# vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/TestPDNameTreeNode.java
module Pdfbox::Pdmodel::Common
  # Builds the name tree used by TestPDNameTreeNode.setUp.
  #   node1 -> [node2 -> [node5], node4 -> [node24]]
  # Setting a kid's parent recalculates that kid's /Limits.
  private def self.build_name_tree
    node5 = PDIntegerNameTreeNode.new
    node5.names = {
      "Actinium"  => Cos::Integer.new(89),
      "Aluminum"  => Cos::Integer.new(13),
      "Americium" => Cos::Integer.new(95),
      "Antimony"  => Cos::Integer.new(51),
      "Argon"     => Cos::Integer.new(18),
      "Arsenic"   => Cos::Integer.new(33),
      "Astatine"  => Cos::Integer.new(85),
    }

    node24 = PDIntegerNameTreeNode.new
    node24.names = {
      "Xenon"     => Cos::Integer.new(54),
      "Ytterbium" => Cos::Integer.new(70),
      "Yttrium"   => Cos::Integer.new(39),
      "Zinc"      => Cos::Integer.new(30),
      "Zirconium" => Cos::Integer.new(40),
    }

    node2 = PDIntegerNameTreeNode.new
    node2.kids = [node5] of PDNameTreeNode(Cos::Integer)

    node4 = PDIntegerNameTreeNode.new
    node4.kids = [node24] of PDNameTreeNode(Cos::Integer)

    node1 = PDIntegerNameTreeNode.new
    node1.kids = [node2, node4] of PDNameTreeNode(Cos::Integer)

    {node1, node2, node4, node5, node24}
  end

  describe PDIntegerNameTreeNode do
    it "TestPDNameTreeNode#testUpperLimit" do
      node1, node2, node4, node5, node24 = build_name_tree

      node5.upper_limit.should eq "Astatine"
      node2.upper_limit.should eq "Astatine"

      node24.upper_limit.should eq "Zirconium"
      node4.upper_limit.should eq "Zirconium"

      node1.upper_limit.should be_nil
    end

    it "TestPDNameTreeNode#testLowerLimit" do
      node1, node2, node4, node5, node24 = build_name_tree

      node5.lower_limit.should eq "Actinium"
      node2.lower_limit.should eq "Actinium"

      node24.lower_limit.should eq "Xenon"
      node4.lower_limit.should eq "Xenon"

      node1.lower_limit.should be_nil
    end

    # Characterization (upstream TestPDNameTreeNode has no getValue case): the
    # level-0 tree resolves values through the kid limits.
    it "TestPDNameTreeNode#getValue (characterization)" do
      node1, _node2, _node4, node5, _node24 = build_name_tree

      node5.value("Antimony").should eq Cos::Integer.new(51)
      node1.value("Ytterbium").should eq Cos::Integer.new(70)

      node1.kids = nil
      node1.names = nil
      node1.value("Actinium").should be_nil
    end
  end
end

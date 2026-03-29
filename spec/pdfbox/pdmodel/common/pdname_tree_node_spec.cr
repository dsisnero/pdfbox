require "../../../spec_helper"
require "../../../helpers/pd_integer_name_tree_node"

module Pdfbox::Pdmodel::Common
  describe PDIntegerNameTreeNode do
    node1 = nil.as(PDIntegerNameTreeNode?)
    node2 = nil.as(PDIntegerNameTreeNode?)
    node4 = nil.as(PDIntegerNameTreeNode?)
    node5 = nil.as(PDIntegerNameTreeNode?)
    node24 = nil.as(PDIntegerNameTreeNode?)

    before_each do
      node5 = PDIntegerNameTreeNode.new
      names = {} of String => Pdfbox::Cos::Integer
      names["Actinium"] = Pdfbox::Cos::Integer.new(89)
      names["Aluminum"] = Pdfbox::Cos::Integer.new(13)
      names["Americium"] = Pdfbox::Cos::Integer.new(95)
      names["Antimony"] = Pdfbox::Cos::Integer.new(51)
      names["Argon"] = Pdfbox::Cos::Integer.new(18)
      names["Arsenic"] = Pdfbox::Cos::Integer.new(33)
      names["Astatine"] = Pdfbox::Cos::Integer.new(85)
      node5.not_nil!.names = names

      node24 = PDIntegerNameTreeNode.new
      names = {} of String => Pdfbox::Cos::Integer
      names["Xenon"] = Pdfbox::Cos::Integer.new(54)
      names["Ytterbium"] = Pdfbox::Cos::Integer.new(70)
      names["Yttrium"] = Pdfbox::Cos::Integer.new(39)
      names["Zinc"] = Pdfbox::Cos::Integer.new(30)
      names["Zirconium"] = Pdfbox::Cos::Integer.new(40)
      node24.not_nil!.names = names

      node2 = PDIntegerNameTreeNode.new
      kids = node2.not_nil!.kids || COSArrayList(PDNameTreeNode(Cos::Integer)).new
      kids.add(node5.not_nil!)
      node2.not_nil!.kids = kids.to_a

      node4 = PDIntegerNameTreeNode.new
      kids = node4.not_nil!.kids || COSArrayList(PDNameTreeNode(Cos::Integer)).new
      kids.add(node24.not_nil!)
      node4.not_nil!.kids = kids.to_a

      node1 = PDIntegerNameTreeNode.new
      kids = node1.not_nil!.kids || COSArrayList(PDNameTreeNode(Cos::Integer)).new
      kids.add(node2.not_nil!)
      kids.add(node4.not_nil!)
      node1.not_nil!.kids = kids.to_a
    end

    it "TestPDNameTreeNode#testUpperLimit" do
      node5.not_nil!.upper_limit.should eq("Astatine")
      node2.not_nil!.upper_limit.should eq("Astatine")
      node24.not_nil!.upper_limit.should eq("Zirconium")
      node4.not_nil!.upper_limit.should eq("Zirconium")
      node1.not_nil!.upper_limit.should be_nil
    end

    it "TestPDNameTreeNode#testLowerLimit" do
      node5.not_nil!.lower_limit.should eq("Actinium")
      node2.not_nil!.lower_limit.should eq("Actinium")
      node24.not_nil!.lower_limit.should eq("Xenon")
      node4.not_nil!.lower_limit.should eq("Xenon")
      node1.not_nil!.lower_limit.should be_nil
    end
  end
end

require "../../../spec_helper"
require "../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/TestPDNumberTreeNode.java
private class PDNumberTest
  include Pdfbox::Pdmodel::Common::COSObjectable
  getter value : Int32

  def initialize(@value : Int32)
  end

  def self.from_cos(base : Pdfbox::Cos::Base) : PDNumberTest
    PDNumberTest.new(base.as(Pdfbox::Cos::Integer).value.to_i32)
  end

  def cos_object : Pdfbox::Cos::Base
    Pdfbox::Cos::Integer.new(value.to_i64)
  end
end

private def build_number_tree
  node5 = Pdfbox::Pdmodel::Common::PDNumberTreeNode(PDNumberTest).new(->(b : Pdfbox::Cos::Base) { PDNumberTest.from_cos(b) })
  numbers5 = {1 => PDNumberTest.new(89), 2 => PDNumberTest.new(13), 3 => PDNumberTest.new(95),
              4 => PDNumberTest.new(51), 5 => PDNumberTest.new(18), 6 => PDNumberTest.new(33), 7 => PDNumberTest.new(85)}
  node5.numbers = numbers5

  node24 = Pdfbox::Pdmodel::Common::PDNumberTreeNode(PDNumberTest).new(->(b : Pdfbox::Cos::Base) { PDNumberTest.from_cos(b) })
  numbers24 = {8 => PDNumberTest.new(54), 9 => PDNumberTest.new(70), 10 => PDNumberTest.new(39),
               11 => PDNumberTest.new(30), 12 => PDNumberTest.new(40)}
  node24.numbers = numbers24

  node2 = Pdfbox::Pdmodel::Common::PDNumberTreeNode(PDNumberTest).new(->(b : Pdfbox::Cos::Base) { PDNumberTest.from_cos(b) })
  node2.kids = [node5]

  node4 = Pdfbox::Pdmodel::Common::PDNumberTreeNode(PDNumberTest).new(->(b : Pdfbox::Cos::Base) { PDNumberTest.from_cos(b) })
  node4.kids = [node24]

  node1 = Pdfbox::Pdmodel::Common::PDNumberTreeNode(PDNumberTest).new(->(b : Pdfbox::Cos::Base) { PDNumberTest.from_cos(b) })
  node1.kids = [node2, node4]

  {node1, node2, node4, node5, node24}
end

describe Pdfbox::Pdmodel::Common::PDNumberTreeNode do
  it "TestPDNumberTreeNode#testGetValue" do
    node1, _node2, _node4, node5, _node24 = build_number_tree

    node5.value(4).not_nil!.value.should eq(51)
    node1.value(9).not_nil!.value.should eq(70)

    node1.kids = nil
    node1.numbers = nil
    node1.value(0).should be_nil
  end

  it "TestPDNumberTreeNode#testUpperLimit" do
    node1, node2, node4, node5, node24 = build_number_tree

    node5.upper_limit.should eq(7)
    node2.upper_limit.should eq(7)

    node24.upper_limit.should eq(12)
    node4.upper_limit.should eq(12)

    node1.upper_limit.should eq(12)

    node24.numbers = {} of Int32 => PDNumberTest
    node24.upper_limit.should be_nil

    node5.numbers = nil
    node5.upper_limit.should be_nil

    node1.kids = nil
    node1.upper_limit.should be_nil
  end

  it "TestPDNumberTreeNode#testLowerLimit" do
    node1, node2, node4, node5, node24 = build_number_tree

    node5.lower_limit.should eq(1)
    node2.lower_limit.should eq(1)

    node24.lower_limit.should eq(8)
    node4.lower_limit.should eq(8)

    node1.lower_limit.should eq(1)

    node24.numbers = {} of Int32 => PDNumberTest
    node24.lower_limit.should be_nil

    node5.numbers = nil
    node5.lower_limit.should be_nil

    node1.kids = nil
    node1.lower_limit.should be_nil
  end
end

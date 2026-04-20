require "../../../spec_helper"

module Pdfbox::Pdmodel::Common
  class PDTest
    include COSObjectable

    def initialize(@value : Int32); end

    def initialize(cos_int : Cos::Integer)
      @value = cos_int.value
    end

    def cos_object : Cos::Base
      Cos::Integer.new(@value.to_i64)
    end

    def_equals_and_hash @value
  end

  # Converter proc for PDTest
  PD_TEST_CONVERTER = ->(base : Cos::Base) do
    case base
    when Cos::Integer
      PDTest.new(base)
    else
      raise "Unexpected COS type: #{base.class}"
    end
  end

  describe PDNumberTreeNode do
    node1 = nil.as(PDNumberTreeNode(PDTest)?)
    node2 = nil.as(PDNumberTreeNode(PDTest)?)
    node4 = nil.as(PDNumberTreeNode(PDTest)?)
    node5 = nil.as(PDNumberTreeNode(PDTest)?)
    node24 = nil.as(PDNumberTreeNode(PDTest)?)

    before_each do
      node5 = PDNumberTreeNode(PDTest).new(PD_TEST_CONVERTER)
      numbers = {
        1 => PDTest.new(89),
        2 => PDTest.new(13),
        3 => PDTest.new(95),
        4 => PDTest.new(51),
        5 => PDTest.new(18),
        6 => PDTest.new(33),
        7 => PDTest.new(85),
      }
      node5.as(PDNumberTreeNode).numbers = numbers

      node24 = PDNumberTreeNode(PDTest).new(PD_TEST_CONVERTER)
      numbers = {
         8 => PDTest.new(54),
         9 => PDTest.new(70),
        10 => PDTest.new(39),
        11 => PDTest.new(30),
        12 => PDTest.new(40),
      }
      node24.as(PDNumberTreeNode).numbers = numbers

      node2 = PDNumberTreeNode(PDTest).new(PD_TEST_CONVERTER)
      kids = node2.not_nil!.kids
      if kids
        kids = kids.to_a
        kids << node5.not_nil!
      else
        kids = Common::COSArrayList(PDNumberTreeNode(PDTest)).new
        kids.add(node5.not_nil!)
      end
      node2.not_nil!.kids = kids.to_a

      kids = node4.not_nil!.kids
      if kids
        kids = kids.to_a
        kids << node24.not_nil!
      else
        kids = [] of PDNumberTreeNode(PDTest)
        kids << node24.not_nil!
      end
      node4.not_nil!.kids = kids.to_a

      kids = node1.not_nil!.kids
      if kids
        kids = kids.to_a
        kids << node2.not_nil!
        kids << node4.not_nil!
      else
        kids = [] of PDNumberTreeNode(PDTest)
        kids << node2.not_nil!
        kids << node4.not_nil!
      end
      node1.not_nil!.kids = kids.to_a

      node5.not_nil!.value(4).should eq PDTest.new(51)
      node1.not_nil!.value(9).should eq PDTest.new(70)
      node1.not_nil!.kids = nil
      node1.not_nil!.numbers = nil
      node1.not_nil!.value(0).should be_nil

      node5.not_nil!.upper_limit.should eq 7
      node2.not_nil!.upper_limit.should eq 7
      node24.not_nil!.upper_limit.should eq 12
      node4.not_nil!.upper_limit.should eq 12
      node1.not_nil!.upper_limit.should eq 12
      node24.not_nil!.numbers = {} of Int32 => PDTest
      node24.not_nil!.upper_limit.should be_nil
      node5.not_nil!.numbers = nil
      node5.not_nil!.upper_limit.should be_nil
      node1.not_nil!.kids = nil
      node1.not_nil!.upper_limit.should be_nil

      node5.not_nil!.lower_limit.should eq 1
      node2.not_nil!.lower_limit.should eq 1
      node24.not_nil!.lower_limit.should eq 8
      node4.not_nil!.lower_limit.should eq 8
      node1.not_nil!.lower_limit.should eq 1
      node24.not_nil!.numbers = {} of Int32 => PDTest
      node24.not_nil!.lower_limit.should be_nil
      node5.not_nil!.numbers = nil
      node5.not_nil!.lower_limit.should be_nil
      node1.not_nil!.kids = nil
      node1.not_nil!.lower_limit.should be_nil
    end
  end
end

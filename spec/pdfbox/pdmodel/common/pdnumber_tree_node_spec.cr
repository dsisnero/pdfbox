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
      node5.not_nil!.numbers = numbers

      node24 = PDNumberTreeNode(PDTest).new(PD_TEST_CONVERTER)
      numbers = {
        8 => PDTest.new(54),
        9 => PDTest.new(70),
        10 => PDTest.new(39),
        11 => PDTest.new(30),
        12 => PDTest.new(40),
      }
      node24.not_nil!.numbers = numbers

      node2 = PDNumberTreeNode(PDTest).new(PD_TEST_CONVERTER)
      kids = node2.not_nil!.kids
      if kids.nil?
        kids = COSArrayList(PDNumberTreeNode(PDTest)).new
      end
      kids.add(node5.not_nil!)
      node2.not_nil!.kids = kids.to_a

      node4 = PDNumberTreeNode(PDTest).new(PD_TEST_CONVERTER)
      kids = node4.not_nil!.kids
      if kids.nil?
        kids = COSArrayList(PDNumberTreeNode(PDTest)).new
      end
      kids.add(node24.not_nil!)
      node4.not_nil!.kids = kids.to_a

      node1 = PDNumberTreeNode(PDTest).new(PD_TEST_CONVERTER)
      kids = node1.not_nil!.kids
      if kids.nil?
        kids = COSArrayList(PDNumberTreeNode(PDTest)).new
      end
      kids.add(node2.not_nil!)
      kids.add(node4.not_nil!)
      node1.not_nil!.kids = kids.to_a
    end

    describe "#value" do
      it "retrieves value from leaf node" do
        node5.not_nil!.value(4).should eq PDTest.new(51)
      end

      it "retrieves value from tree" do
        node1.not_nil!.value(9).should eq PDTest.new(70)
      end

      it "returns nil when no kids or numbers" do
        node1.not_nil!.kids = nil
        node1.not_nil!.numbers = nil
        node1.not_nil!.value(0).should be_nil
      end
    end

    describe "#upper_limit" do
      it "returns correct upper limit for leaf node" do
        node5.not_nil!.upper_limit.should eq 7
        node2.not_nil!.upper_limit.should eq 7
      end

      it "returns correct upper limit for other leaf" do
        node24.not_nil!.upper_limit.should eq 12
        node4.not_nil!.upper_limit.should eq 12
      end

      it "returns correct upper limit for root" do
        node1.not_nil!.upper_limit.should eq 12
      end

      it "returns nil when numbers empty" do
        node24.not_nil!.numbers = {} of Int32 => PDTest
        node24.not_nil!.upper_limit.should be_nil
      end

      it "returns nil when numbers nil" do
        node5.not_nil!.numbers = nil
        node5.not_nil!.upper_limit.should be_nil
      end

      it "returns nil when kids nil" do
        node1.not_nil!.kids = nil
        node1.not_nil!.upper_limit.should be_nil
      end
    end

    describe "#lower_limit" do
      it "returns correct lower limit for leaf node" do
        node5.not_nil!.lower_limit.should eq 1
        node2.not_nil!.lower_limit.should eq 1
      end

      it "returns correct lower limit for other leaf" do
        node24.not_nil!.lower_limit.should eq 8
        node4.not_nil!.lower_limit.should eq 8
      end

      it "returns correct lower limit for root" do
        node1.not_nil!.lower_limit.should eq 1
      end

      it "returns nil when numbers empty" do
        node24.not_nil!.numbers = {} of Int32 => PDTest
        node24.not_nil!.lower_limit.should be_nil
      end

      it "returns nil when numbers nil" do
        node5.not_nil!.numbers = nil
        node5.not_nil!.lower_limit.should be_nil
      end

      it "returns nil when kids nil" do
        node1.not_nil!.kids = nil
        node1.not_nil!.lower_limit.should be_nil
      end
    end
  end
end
require "../../../spec_helper"

# Test struct similar to PDTest in Java test
record TestObject, value : Int32 do
  def initialize(cos_int : Pdfbox::Cos::Integer)
    initialize(cos_int.value.to_i32)
  end

  # Convert to COS object
  def cos_object : Pdfbox::Cos::Integer
    Pdfbox::Cos::Integer.new(value.to_i64)
  end
end

# Helper to create a NumberTreeNode with TestObject converter
def create_node : Pdfbox::Pdmodel::NumberTreeNode(TestObject)
  Pdfbox::Pdmodel::NumberTreeNode(TestObject).new(->(cos : Pdfbox::Cos::Base) {
    TestObject.new(cos.as(Pdfbox::Cos::Integer))
  })
end

describe Pdfbox::Pdmodel::NumberTreeNode do
  describe ".new" do
    it "creates an empty number tree node" do
      node = create_node
      node.should_not be_nil
    end

    it "creates a number tree node from a dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      node = Pdfbox::Pdmodel::NumberTreeNode(TestObject).new(dict) do |cos|
        TestObject.new(cos.as(Pdfbox::Cos::Integer))
      end
      node.should_not be_nil
    end
  end

  describe "#get_value" do
    it "retrieves value from leaf node" do
      # Create leaf node with numbers 1-7
      node5 = create_node
      numbers = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node5.numbers = numbers

      node5.get_value(4).should eq(TestObject.new(51))
    end

    it "retrieves value from tree structure" do
      # Build tree structure similar to Java test
      # node5: numbers 1-7
      node5 = create_node
      numbers5 = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node5.numbers = numbers5

      # node24: numbers 8-12
      node24 = create_node
      numbers24 = {
         8 => TestObject.new(54),
         9 => TestObject.new(70),
        10 => TestObject.new(39),
        11 => TestObject.new(30),
        12 => TestObject.new(40),
      }
      node24.numbers = numbers24

      # node2 has node5 as child
      node2 = create_node
      node2.kids = [node5]

      # node4 has node24 as child
      node4 = create_node
      node4.kids = [node24]

      # node1 has node2 and node4 as children
      node1 = create_node
      node1.kids = [node2, node4]

      # Test retrieving value from nested structure
      node1.get_value(9).should eq(TestObject.new(70))
    end

    it "returns nil for non-existent index" do
      node = create_node
      node.get_value(0).should be_nil
    end

    it "returns nil when kids and numbers are nil" do
      # Build tree structure similar to Java test
      node5 = create_node
      numbers5 = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node5.numbers = numbers5

      node24 = create_node
      numbers24 = {
         8 => TestObject.new(54),
         9 => TestObject.new(70),
        10 => TestObject.new(39),
        11 => TestObject.new(30),
        12 => TestObject.new(40),
      }
      node24.numbers = numbers24

      node2 = create_node
      node2.kids = [node5]

      node4 = create_node
      node4.kids = [node24]

      node1 = create_node
      node1.kids = [node2, node4]

      # Set kids and numbers to nil
      node1.kids = nil
      node1.numbers = nil
      node1.get_value(0).should be_nil
    end
  end

  describe "#upper_limit" do
    it "returns correct upper limit for leaf node" do
      node = create_node
      numbers = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node.numbers = numbers
      node.upper_limit.should eq(7)
    end

    it "returns correct upper limit for tree structure" do
      # Build tree structure
      node5 = create_node
      numbers5 = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node5.numbers = numbers5

      node24 = create_node
      numbers24 = {
         8 => TestObject.new(54),
         9 => TestObject.new(70),
        10 => TestObject.new(39),
        11 => TestObject.new(30),
        12 => TestObject.new(40),
      }
      node24.numbers = numbers24

      node2 = create_node
      node2.kids = [node5]

      node4 = create_node
      node4.kids = [node24]

      node1 = create_node
      node1.kids = [node2, node4]

      node1.upper_limit.should eq(12)
      node2.upper_limit.should eq(7)
      node4.upper_limit.should eq(12)
      node5.upper_limit.should eq(7)
      node24.upper_limit.should eq(12)
    end

    it "returns nil for empty node" do
      node = create_node
      node.numbers = {} of Int32 => TestObject
      node.upper_limit.should be_nil
    end

    it "returns nil for empty map" do
      node24 = create_node
      node24.numbers = {} of Int32 => TestObject
      node24.upper_limit.should be_nil
    end

    it "returns nil for null numbers" do
      node5 = create_node
      node5.numbers = nil
      node5.upper_limit.should be_nil
    end

    it "returns nil for null kids" do
      # Build tree structure
      node5 = create_node
      numbers5 = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node5.numbers = numbers5

      node24 = create_node
      numbers24 = {
         8 => TestObject.new(54),
         9 => TestObject.new(70),
        10 => TestObject.new(39),
        11 => TestObject.new(30),
        12 => TestObject.new(40),
      }
      node24.numbers = numbers24

      node2 = create_node
      node2.kids = [node5]

      node4 = create_node
      node4.kids = [node24]

      node1 = create_node
      node1.kids = [node2, node4]

      node1.kids = nil
      node1.upper_limit.should be_nil
    end
  end

  describe "#lower_limit" do
    it "returns correct lower limit for leaf node" do
      node = create_node
      numbers = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node.numbers = numbers
      node.lower_limit.should eq(1)
    end

    it "returns correct lower limit for tree structure" do
      # Build tree structure
      node5 = create_node
      numbers5 = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node5.numbers = numbers5

      node24 = create_node
      numbers24 = {
         8 => TestObject.new(54),
         9 => TestObject.new(70),
        10 => TestObject.new(39),
        11 => TestObject.new(30),
        12 => TestObject.new(40),
      }
      node24.numbers = numbers24

      node2 = create_node
      node2.kids = [node5]

      node4 = create_node
      node4.kids = [node24]

      node1 = create_node
      node1.kids = [node2, node4]

      node1.lower_limit.should eq(1)
      node2.lower_limit.should eq(1)
      node4.lower_limit.should eq(8)
      node5.lower_limit.should eq(1)
      node24.lower_limit.should eq(8)
    end

    it "returns nil for empty node" do
      node = create_node
      node.numbers = {} of Int32 => TestObject
      node.lower_limit.should be_nil
    end

    it "returns nil for empty map" do
      node24 = create_node
      node24.numbers = {} of Int32 => TestObject
      node24.lower_limit.should be_nil
    end

    it "returns nil for null numbers" do
      node5 = create_node
      node5.numbers = nil
      node5.lower_limit.should be_nil
    end

    it "returns nil for null kids" do
      # Build tree structure
      node5 = create_node
      numbers5 = {
        1 => TestObject.new(89),
        2 => TestObject.new(13),
        3 => TestObject.new(95),
        4 => TestObject.new(51),
        5 => TestObject.new(18),
        6 => TestObject.new(33),
        7 => TestObject.new(85),
      }
      node5.numbers = numbers5

      node24 = create_node
      numbers24 = {
         8 => TestObject.new(54),
         9 => TestObject.new(70),
        10 => TestObject.new(39),
        11 => TestObject.new(30),
        12 => TestObject.new(40),
      }
      node24.numbers = numbers24

      node2 = create_node
      node2.kids = [node5]

      node4 = create_node
      node4.kids = [node24]

      node1 = create_node
      node1.kids = [node2, node4]

      node1.kids = nil
      node1.lower_limit.should be_nil
    end
  end
end

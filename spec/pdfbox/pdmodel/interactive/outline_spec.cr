require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/documentnavigation/outline/PDOutlineItemTest.java
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/documentnavigation/outline/PDOutlineNodeTest.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/documentnavigation/outline/*.java
# Model surface parity: the doubly-linked outline tree — add_first/add_last, sibling
# insertion (before/after), parent resolution (PDDocumentOutline vs PDOutlineItem), open
# count bookkeeping (PDF 32000-1 table 152/153), node open/close, children iteration.
module OutlineSpecHelper
  def self.new_item : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItem
    Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItem.new
  end
end

describe Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItem do
  # PDOutlineItemTest.setUp
  it "builds a root with two children and an open child with two grandchildren" do
    root = OutlineSpecHelper.new_item
    first = OutlineSpecHelper.new_item
    second = OutlineSpecHelper.new_item
    root.add_last(first)
    root.add_last(second)
    new_sibling = OutlineSpecHelper.new_item
    new_sibling.add_last(OutlineSpecHelper.new_item)
    new_sibling.add_last(OutlineSpecHelper.new_item)
  end

  describe "insertSiblingAfter" do
    it "open child to open parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)
      new_sibling = OutlineSpecHelper.new_item
      new_sibling.add_last(OutlineSpecHelper.new_item)
      new_sibling.add_last(OutlineSpecHelper.new_item)

      new_sibling.open_node
      root.open_node
      root.open_count.should eq(2)
      first.insert_sibling_after(new_sibling)
      first.next_sibling.should eq(new_sibling)
      second.previous_sibling.should eq(new_sibling)
      root.open_count.should eq(5)
    end

    it "open child to closed parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)
      new_sibling = OutlineSpecHelper.new_item
      new_sibling.add_last(OutlineSpecHelper.new_item)
      new_sibling.add_last(OutlineSpecHelper.new_item)

      new_sibling.open_node
      root.open_count.should eq(-2)
      first.insert_sibling_after(new_sibling)
      first.next_sibling.should eq(new_sibling)
      second.previous_sibling.should eq(new_sibling)
      root.open_count.should eq(-5)
    end

    it "closed child to open parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)
      new_sibling = OutlineSpecHelper.new_item
      new_sibling.add_last(OutlineSpecHelper.new_item)
      new_sibling.add_last(OutlineSpecHelper.new_item)

      root.open_node
      root.open_count.should eq(2)
      first.insert_sibling_after(new_sibling)
      first.next_sibling.should eq(new_sibling)
      second.previous_sibling.should eq(new_sibling)
      root.open_count.should eq(3)
    end

    it "closed child to closed parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)
      new_sibling = OutlineSpecHelper.new_item
      new_sibling.add_last(OutlineSpecHelper.new_item)
      new_sibling.add_last(OutlineSpecHelper.new_item)

      root.open_count.should eq(-2)
      first.insert_sibling_after(new_sibling)
      first.next_sibling.should eq(new_sibling)
      second.previous_sibling.should eq(new_sibling)
      root.open_count.should eq(-3)
    end

    it "inserts at bottom" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)

      root.last_child.should eq(second)
      new_sibling = OutlineSpecHelper.new_item
      second.insert_sibling_after(new_sibling)
      second.next_sibling.should eq(new_sibling)
      root.last_child.should eq(new_sibling)
    end

    it "inserts at bottom without parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)

      root.last_child.should eq(second)
      new_sibling = OutlineSpecHelper.new_item
      root.insert_sibling_after(new_sibling)
      root.next_sibling.should eq(new_sibling)
    end
  end

  describe "insertSiblingBefore" do
    it "open child to open parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)
      new_sibling = OutlineSpecHelper.new_item
      new_sibling.add_last(OutlineSpecHelper.new_item)
      new_sibling.add_last(OutlineSpecHelper.new_item)

      new_sibling.open_node
      root.open_node
      root.open_count.should eq(2)
      second.insert_sibling_before(new_sibling)
      first.next_sibling.should eq(new_sibling)
      second.previous_sibling.should eq(new_sibling)
      root.open_count.should eq(5)
    end

    it "open child to closed parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)
      new_sibling = OutlineSpecHelper.new_item
      new_sibling.add_last(OutlineSpecHelper.new_item)
      new_sibling.add_last(OutlineSpecHelper.new_item)

      new_sibling.open_node
      root.open_count.should eq(-2)
      second.insert_sibling_before(new_sibling)
      first.next_sibling.should eq(new_sibling)
      second.previous_sibling.should eq(new_sibling)
      root.open_count.should eq(-5)
    end

    it "closed child to open parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)
      new_sibling = OutlineSpecHelper.new_item
      new_sibling.add_last(OutlineSpecHelper.new_item)
      new_sibling.add_last(OutlineSpecHelper.new_item)

      root.open_node
      root.open_count.should eq(2)
      second.insert_sibling_before(new_sibling)
      first.next_sibling.should eq(new_sibling)
      second.previous_sibling.should eq(new_sibling)
      root.open_count.should eq(3)
    end

    it "closed child to closed parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)
      new_sibling = OutlineSpecHelper.new_item
      new_sibling.add_last(OutlineSpecHelper.new_item)
      new_sibling.add_last(OutlineSpecHelper.new_item)

      root.open_count.should eq(-2)
      second.insert_sibling_before(new_sibling)
      first.next_sibling.should eq(new_sibling)
      second.previous_sibling.should eq(new_sibling)
      root.open_count.should eq(-3)
    end

    it "inserts at top" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)

      root.first_child.should eq(first)
      new_sibling = OutlineSpecHelper.new_item
      first.insert_sibling_before(new_sibling)
      first.previous_sibling.should eq(new_sibling)
      root.first_child.should eq(new_sibling)
    end

    it "inserts at top without parent" do
      root = OutlineSpecHelper.new_item
      first = OutlineSpecHelper.new_item
      second = OutlineSpecHelper.new_item
      root.add_last(first)
      root.add_last(second)

      root.first_child.should eq(first)
      new_sibling = OutlineSpecHelper.new_item
      root.insert_sibling_before(new_sibling)
      root.previous_sibling.should eq(new_sibling)
    end
  end

  describe "cannot insert a list" do
    it "throws when inserting a list before" do
      root = OutlineSpecHelper.new_item
      child = OutlineSpecHelper.new_item
      child.insert_sibling_after(OutlineSpecHelper.new_item)
      child.insert_sibling_after(OutlineSpecHelper.new_item)
      expect_raises(::ArgumentError) { root.insert_sibling_before(child) }
    end

    it "throws when inserting a list after" do
      root = OutlineSpecHelper.new_item
      child = OutlineSpecHelper.new_item
      child.insert_sibling_after(OutlineSpecHelper.new_item)
      child.insert_sibling_after(OutlineSpecHelper.new_item)
      expect_raises(::ArgumentError) { root.insert_sibling_after(child) }
    end
  end
end

describe Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineNode do
  it "resolves parents including PDDocumentOutline root" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    root.add_last(child)
    outline = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDDocumentOutline.new
    outline.add_last(root)
    outline.parent.should be_nil
    root.parent.should eq(outline)
    child.parent.should eq(root)
  end

  it "returns nil for last child of an empty node" do
    root = OutlineSpecHelper.new_item
    root.last_child.should be_nil
  end

  it "returns nil for first child of an empty node" do
    root = OutlineSpecHelper.new_item
    root.first_child.should be_nil
  end

  it "opening an already open node does nothing" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    root.open_count.should eq(0)
    root.add_last(child)
    root.open_node
    root.node_open?.should be_true
    root.open_count.should eq(1)
    root.open_node
    root.node_open?.should be_true
    root.open_count.should eq(1)
  end

  it "closing an already closed node does nothing" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    root.open_count.should eq(0)
    root.add_last(child)
    root.open_node
    root.close_node
    root.node_open?.should be_false
    root.open_count.should eq(-1)
    root.close_node
    root.node_open?.should be_false
    root.open_count.should eq(-1)
  end

  it "cannot open a leaf" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    root.add_last(child)
    child.open_node
    child.node_open?.should be_false
  end

  it "is closed by default" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    root.add_last(child)
    root.node_open?.should be_false
    root.open_count.should eq(-1)
  end

  it "closes a node with an open parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_last(OutlineSpecHelper.new_item)
    child.add_last(OutlineSpecHelper.new_item)
    child.open_node
    root.add_last(child)
    root.open_node
    root.open_count.should eq(3)
    child.open_count.should eq(2)
    child.close_node
    root.open_count.should eq(1)
    child.open_count.should eq(-2)
  end

  it "closes a node with a closed parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_last(OutlineSpecHelper.new_item)
    child.add_last(OutlineSpecHelper.new_item)
    child.open_node
    root.add_last(child)
    root.open_count.should eq(-3)
    child.open_count.should eq(2)
    child.close_node
    root.open_count.should eq(-1)
    child.open_count.should eq(-2)
  end

  it "opens a node with an open parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_last(OutlineSpecHelper.new_item)
    child.add_last(OutlineSpecHelper.new_item)
    root.add_last(child)
    root.open_node
    root.open_count.should eq(1)
    child.open_count.should eq(-2)
    child.open_node
    root.open_count.should eq(3)
    child.open_count.should eq(2)
  end

  it "opens a node with a closed parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_last(OutlineSpecHelper.new_item)
    child.add_last(OutlineSpecHelper.new_item)
    root.add_last(child)
    root.open_count.should eq(-1)
    child.open_count.should eq(-2)
    child.open_node
    root.open_count.should eq(-3)
    child.open_count.should eq(2)
  end

  it "adds a single last child" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    root.add_last(child)
    root.first_child.should eq(child)
    root.last_child.should eq(child)
  end

  it "adds a single first child" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    root.add_first(child)
    root.first_child.should eq(child)
    root.last_child.should eq(child)
  end

  it "adds a last open child to an open parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_last(OutlineSpecHelper.new_item)
    child.add_last(OutlineSpecHelper.new_item)
    child.open_node
    root.add_last(OutlineSpecHelper.new_item)
    root.open_node
    root.open_count.should eq(1)
    child.open_count.should eq(2)
    root.add_last(child)
    root.first_child.should_not eq(child)
    root.last_child.should eq(child)
    root.open_count.should eq(4)
  end

  it "adds a first open child to an open parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_first(OutlineSpecHelper.new_item)
    child.add_first(OutlineSpecHelper.new_item)
    child.open_node
    root.add_first(OutlineSpecHelper.new_item)
    root.open_node
    root.open_count.should eq(1)
    child.open_count.should eq(2)
    root.add_first(child)
    root.last_child.should_not eq(child)
    root.first_child.should eq(child)
    root.open_count.should eq(4)
  end

  it "adds a last open child to a closed parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_last(OutlineSpecHelper.new_item)
    child.add_last(OutlineSpecHelper.new_item)
    child.open_node
    root.add_last(OutlineSpecHelper.new_item)
    root.open_count.should eq(-1)
    child.open_count.should eq(2)
    root.add_last(child)
    root.first_child.should_not eq(child)
    root.last_child.should eq(child)
    root.open_count.should eq(-4)
  end

  it "adds a first open child to a closed parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_first(OutlineSpecHelper.new_item)
    child.add_first(OutlineSpecHelper.new_item)
    child.open_node
    root.add_first(OutlineSpecHelper.new_item)
    root.open_count.should eq(-1)
    child.open_count.should eq(2)
    root.add_first(child)
    root.last_child.should_not eq(child)
    root.first_child.should eq(child)
    root.open_count.should eq(-4)
  end

  it "adds a last closed child to an open parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_last(OutlineSpecHelper.new_item)
    child.add_last(OutlineSpecHelper.new_item)
    root.add_last(OutlineSpecHelper.new_item)
    root.open_node
    root.open_count.should eq(1)
    child.open_count.should eq(-2)
    root.add_last(child)
    root.first_child.should_not eq(child)
    root.last_child.should eq(child)
    root.open_count.should eq(2)
  end

  it "adds a first closed child to an open parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_first(OutlineSpecHelper.new_item)
    child.add_first(OutlineSpecHelper.new_item)
    root.add_first(OutlineSpecHelper.new_item)
    root.open_node
    root.open_count.should eq(1)
    child.open_count.should eq(-2)
    root.add_first(child)
    root.last_child.should_not eq(child)
    root.first_child.should eq(child)
    root.open_count.should eq(2)
  end

  it "adds a last closed child to a closed parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_last(OutlineSpecHelper.new_item)
    child.add_last(OutlineSpecHelper.new_item)
    root.add_last(OutlineSpecHelper.new_item)
    root.open_count.should eq(-1)
    child.open_count.should eq(-2)
    root.add_last(child)
    root.first_child.should_not eq(child)
    root.last_child.should eq(child)
    root.open_count.should eq(-2)
  end

  it "adds a first closed child to a closed parent" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.add_first(OutlineSpecHelper.new_item)
    child.add_first(OutlineSpecHelper.new_item)
    root.add_first(OutlineSpecHelper.new_item)
    root.open_count.should eq(-1)
    child.open_count.should eq(-2)
    root.add_first(child)
    root.last_child.should_not eq(child)
    root.first_child.should eq(child)
    root.open_count.should eq(-2)
  end

  it "cannot add a list as last child" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.insert_sibling_after(OutlineSpecHelper.new_item)
    child.insert_sibling_after(OutlineSpecHelper.new_item)
    expect_raises(::ArgumentError) { root.add_last(child) }
  end

  it "cannot add a list as first child" do
    root = OutlineSpecHelper.new_item
    child = OutlineSpecHelper.new_item
    child.insert_sibling_after(OutlineSpecHelper.new_item)
    child.insert_sibling_after(OutlineSpecHelper.new_item)
    expect_raises(::ArgumentError) { root.add_first(child) }
  end

  it "equals nodes wrapping the same dictionary" do
    root = OutlineSpecHelper.new_item
    root.add_first(OutlineSpecHelper.new_item)
    root.first_child.should eq(root.last_child)
  end

  it "iterates over children" do
    root = OutlineSpecHelper.new_item
    first = OutlineSpecHelper.new_item
    root.add_first(first)
    root.add_last(OutlineSpecHelper.new_item)
    second = OutlineSpecHelper.new_item
    first.insert_sibling_after(second)
    counter = 0
    root.children.each { |_current| counter += 1 }
    counter.should eq(3)
  end

  it "iterates over no children" do
    counter = 0
    OutlineSpecHelper.new_item.children.each { |_current| counter += 1 }
    counter.should eq(0)
  end
end

describe Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDDocumentOutline do
  it "is always open and cannot be opened or closed" do
    outline = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDDocumentOutline.new
    outline.node_open?.should be_true
    outline.open_node
    outline.node_open?.should be_true
    outline.close_node
    outline.node_open?.should be_true
  end

  it "PDDocumentOutlineTest#outlinesCountShouldNotBeNegative" do
    outline = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDDocumentOutline.new
    first_level_child = OutlineSpecHelper.new_item
    outline.add_last(first_level_child)
    second_level_child = OutlineSpecHelper.new_item
    first_level_child.add_last(second_level_child)
    second_level_child.open_count.should eq(0)
    first_level_child.open_count.should eq(-1)
    outline.open_count.should_not be < 0
  end

  it "PDDocumentOutlineTest#outlinesCount" do
    outline = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDDocumentOutline.new
    root = OutlineSpecHelper.new_item
    outline.add_last(root)
    outline.open_count.should eq(1)
    root.add_last(OutlineSpecHelper.new_item)
    root.open_count.should eq(-1)
    outline.open_count.should eq(1)
    root.add_last(OutlineSpecHelper.new_item)
    root.open_count.should eq(-2)
    outline.open_count.should eq(1)
    root.open_node
    root.open_count.should eq(2)
    outline.open_count.should eq(3)
  end
end

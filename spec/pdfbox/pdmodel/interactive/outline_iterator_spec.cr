require "../../../spec_helper"

# Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/documentnavigation/outline/PDOutlineItemIteratorTest.java
# Source of truth: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/documentnavigation/outline/PDOutlineItemIterator.java
describe Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItemIterator do
  it "iterates a single item" do
    first = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItem.new
    iterator = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItemIterator.new(first)
    iterator.has_next?.should be_true
    iterator.next.should eq(first)
    iterator.has_next?.should be_false
  end

  it "iterates multiple items" do
    outline = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItem.new
    first = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItem.new
    second = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItem.new
    outline.add_last(first)
    outline.add_last(second)

    iterator = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItemIterator.new(first)
    iterator.has_next?.should be_true
    iterator.next.should eq(first)
    iterator.has_next?.should be_true
    iterator.next.should eq(second)
    iterator.has_next?.should be_false
  end

  it "raises UnsupportedOperationError on remove" do
    iterator = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItemIterator.new(
      Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItem.new
    )
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { iterator.remove }
  end

  it "has no next when there are no children" do
    iterator = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline::PDOutlineItemIterator.new(nil)
    iterator.has_next?.should be_false
  end
end

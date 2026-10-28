require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSIncrement.java
#
# COSIncrement walks the structures reachable from a COSUpdateInfo and decides
# which COSBase values must be written as top level objects of the next
# incremental revision. Upstream only exercises it end-to-end
# (TestCOSIncrement, ported in increment_spec.cr), so these examples pin the
# collection rules themselves:
#   - direct structures are written by their parent, never as an increment entry
#   - indirect objects are written as their dereferenced base
#   - arrays are always treated as direct structures
#   - entries originating from another document state are treated as updated
private def increment_state : Pdfbox::Cos::DocumentState
  state = Pdfbox::Cos::DocumentState.new
  state.parsing = false
  state
end

describe "Pdfbox::Cos::Increment" do
  it "collects an updated dictionary" do
    state = increment_state
    dictionary = Pdfbox::Cos::Dictionary.new
    dictionary.update_state.origin_document_state = state

    objects = Pdfbox::Cos::Increment.new(dictionary).objects

    objects.size.should eq(1)
    objects.first.same?(dictionary).should be_true
  end

  it "does not collect objects that are not updated" do
    state = increment_state
    dictionary = Pdfbox::Cos::Dictionary.new
    dictionary[Pdfbox::Cos::Name.new("Value")] = Pdfbox::Cos::Integer.new(1)
    dictionary.update_state.origin_document_state = state
    dictionary.set_need_to_be_updated(false)

    Pdfbox::Cos::Increment.new(dictionary).objects.should be_empty
  end

  it "collects the parent of an updated direct child and excludes the child" do
    state = increment_state
    parent = Pdfbox::Cos::Dictionary.new
    child = Pdfbox::Cos::Dictionary.new
    parent[Pdfbox::Cos::Name.new("Child")] = child
    parent.update_state.origin_document_state = state
    parent.set_need_to_be_updated(false)
    # Only the direct child changed: the parent must be rewritten for it.
    child.set_need_to_be_updated(true)

    objects = Pdfbox::Cos::Increment.new(parent).objects

    objects.size.should eq(1)
    objects.first.same?(parent).should be_true
  end

  it "collects an updated indirect object instead of its COSObject wrapper" do
    state = increment_state
    target = Pdfbox::Cos::Dictionary.new
    wrapper = Pdfbox::Cos::Object.new(11_i64, 0_i64, target)
    parent = Pdfbox::Cos::Dictionary.new
    parent[Pdfbox::Cos::Name.new("Ref")] = wrapper
    parent.update_state.origin_document_state = state
    parent.set_need_to_be_updated(false)
    target.set_need_to_be_updated(true)

    increment = Pdfbox::Cos::Increment.new(parent)
    objects = increment.objects

    objects.size.should eq(1)
    objects.first.same?(target).should be_true
    # The wrapper was processed, so a second reference to it is skipped.
    increment.contains?(wrapper).should be_true
  end

  it "treats a changed array as a direct child of its parent" do
    state = increment_state
    array = Pdfbox::Cos::Array.new
    parent = Pdfbox::Cos::Dictionary.new
    parent[Pdfbox::Cos::Name.new("Kids")] = array
    parent.update_state.origin_document_state = state
    parent.set_need_to_be_updated(false)
    array.set_need_to_be_updated(false)

    array.add(Pdfbox::Cos::Integer.new(1))

    objects = Pdfbox::Cos::Increment.new(parent).objects

    objects.size.should eq(1)
    objects.first.same?(parent).should be_true
  end

  it "skips bases that have been excluded" do
    state = increment_state
    dictionary = Pdfbox::Cos::Dictionary.new
    child = Pdfbox::Cos::Dictionary.new
    dictionary[Pdfbox::Cos::Name.new("Child")] = child
    dictionary.update_state.origin_document_state = state

    increment = Pdfbox::Cos::Increment.new(dictionary).exclude(dictionary)

    increment.objects.should be_empty
    # exclude() returns the increment so it can be chained (Java varargs API).
    increment.exclude(child).should be(increment)
  end

  it "treats entries originating from another document state as updated" do
    state = increment_state
    foreign_state = increment_state
    parent = Pdfbox::Cos::Dictionary.new
    foreign = Pdfbox::Cos::Dictionary.new
    foreign.update_state.origin_document_state = foreign_state
    parent[Pdfbox::Cos::Name.new("Foreign")] = foreign
    parent.update_state.origin_document_state = state
    parent.set_need_to_be_updated(false)
    foreign.set_need_to_be_updated(false)

    objects = Pdfbox::Cos::Increment.new(parent).objects

    # The foreign entry must be written, so its parent is rewritten with it.
    foreign.need_to_be_updated?.should be_true
    objects.size.should eq(1)
    objects.first.same?(parent).should be_true
  end

  it "iterates over the collected objects" do
    state = increment_state
    dictionary = Pdfbox::Cos::Dictionary.new
    dictionary.update_state.origin_document_state = state

    collected = [] of Pdfbox::Cos::Base
    Pdfbox::Cos::Increment.new(dictionary).each { |base| collected << base }

    collected.size.should eq(1)
    collected.first.same?(dictionary).should be_true
  end
end

# The writer starts at the trailer, exactly like COSWriter#write:
#   trailer.toIncrement().exclude(trailer)
# These examples run that collection over a parsed-style document graph
# (indirect catalog, page tree and page, as a PDF parser builds them).
private def increment_document_graph
  # Parsing lifecycle: the document state is linked to the trailer while the
  # document is still parsing, so the initial link does not mark anything
  # updated (Java links in COSDocument#setTrailer, before PDDocument flips
  # setParsing(false)).
  state = Pdfbox::Cos::DocumentState.new
  trailer = Pdfbox::Cos::Dictionary.new
  catalog = Pdfbox::Cos::Dictionary.new
  pages = Pdfbox::Cos::Dictionary.new
  kids = Pdfbox::Cos::Array.new
  page = Pdfbox::Cos::Dictionary.new

  catalog.set_item(Pdfbox::Cos::Name.new("Type"), Pdfbox::Cos::Name.new("Catalog"))
  pages.set_item(Pdfbox::Cos::Name.new("Type"), Pdfbox::Cos::Name.new("Pages"))
  pages.set_item(Pdfbox::Cos::Name.new("Kids"), kids)
  page.set_item(Pdfbox::Cos::Name.new("Type"), Pdfbox::Cos::Name.new("Page"))
  kids.add(Pdfbox::Cos::Object.new(3_i64, 0_i64, page))
  catalog.set_item(Pdfbox::Cos::Name.new("Pages"), Pdfbox::Cos::Object.new(2_i64, 0_i64, pages))
  trailer.set_item(Pdfbox::Cos::Name.new("Root"), Pdfbox::Cos::Object.new(1_i64, 0_i64, catalog))

  # COSDocument#setTrailer links the document state to the trailer, which is the
  # root of the update tracking.
  trailer.update_state.origin_document_state = state
  # PDDocument flips the state to "editable" once parsing is complete.
  state.parsing = false

  {state: state, trailer: trailer, catalog: catalog, pages: pages, kids: kids, page: page}
end

private def increment_of_trailer(graph) : Pdfbox::Cos::Increment
  graph[:trailer].to_increment.exclude(graph[:trailer])
end

describe "Pdfbox::Cos::Increment rooted at the document trailer" do
  it "is empty for a document that was not modified" do
    increment_of_trailer(increment_document_graph).objects.should be_empty
  end

  it "collects the updated object and nothing around it" do
    graph = increment_document_graph
    graph[:catalog].set_item(Pdfbox::Cos::Name.new("Lang"), Pdfbox::Cos::String.new("en"))

    objects = increment_of_trailer(graph).objects

    objects.size.should eq(1)
    objects.first.same?(graph[:catalog]).should be_true
  end

  it "rewrites the page tree node when only its direct kids array changed" do
    graph = increment_document_graph
    graph[:kids].add(Pdfbox::Cos::Object.new(4_i64, 0_i64, Pdfbox::Cos::Dictionary.new))

    increment = increment_of_trailer(graph)
    objects = increment.objects

    objects.any? { |base| base.same?(graph[:pages]) }.should be_true
    # The changed array is a direct structure: Java writes it inside its parent.
    objects.any? { |base| base.same?(graph[:kids]) }.should be_false
    # Nothing above the page tree node changed.
    objects.any? { |base| base.same?(graph[:catalog]) }.should be_false
    # A processed COSObject stays queryable once the increment is evaluated.
    increment.contains?(graph[:pages]).should be_true
  end

  it "rewrites only the updated page dictionary" do
    graph = increment_document_graph
    graph[:page].set_item(Pdfbox::Cos::Name.new("Rotate"), Pdfbox::Cos::Integer.new(90))

    objects = increment_of_trailer(graph).objects

    # The page keeps its object number and its /Parent reference, so the
    # unchanged page tree node and catalog stay in the source revision.
    objects.size.should eq(1)
    objects.first.same?(graph[:page]).should be_true
  end

  it "never collects the excluded trailer" do
    graph = increment_document_graph
    graph[:trailer].set_item(Pdfbox::Cos::Name.new("Info"), Pdfbox::Cos::Dictionary.new)
    graph[:catalog].set_item(Pdfbox::Cos::Name.new("Lang"), Pdfbox::Cos::String.new("en"))

    objects = increment_of_trailer(graph).objects

    # The trailer is rewritten as the cross-reference trailer, never as an
    # object of the revision body (COSWriter excludes it explicitly).
    objects.any? { |base| base.same?(graph[:trailer]) }.should be_false
    objects.any? { |base| base.same?(graph[:catalog]) }.should be_true
  end
end

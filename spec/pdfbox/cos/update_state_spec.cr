require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSUpdateState.java
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/cos/TestCOSUpdateInfo.java
#     (the getter/setter half is ported in update_info_spec.cr)
#
# COSUpdateState links a COSDocumentState to a COSUpdateInfo and records whether
# that object changed after the document finished parsing. The incremental
# writer relies on it to know which objects belong to an appended revision, so
# these examples pin the whole mechanism: linking the origin state down a
# structure, the mutation hooks of COSDictionary/COSArray, and the dereferencing
# hook COSObject uses when it resolves an indirect reference.
private def update_state_origin : Pdfbox::Cos::DocumentState
  state = Pdfbox::Cos::DocumentState.new
  state.parsing = false
  state
end

describe "Pdfbox::Cos::UpdateState" do
  it "links the origin document state into dictionaries, arrays and dereferenced COSObjects" do
    origin = update_state_origin
    inner = Pdfbox::Cos::Dictionary.new
    inner[Pdfbox::Cos::Name.new("Value")] = Pdfbox::Cos::Integer.new(1)
    array = Pdfbox::Cos::Array.new
    array.add(inner)
    referenced = Pdfbox::Cos::Dictionary.new
    wrapper = Pdfbox::Cos::Object.new(7_i64, 0_i64, referenced)
    parent = Pdfbox::Cos::Dictionary.new
    parent[Pdfbox::Cos::Name.new("Array")] = array
    parent[Pdfbox::Cos::Name.new("Ref")] = wrapper

    parent.update_state.origin_document_state = origin

    parent.update_state.origin_document_state.should be(origin)
    array.update_state.origin_document_state.should be(origin)
    inner.update_state.origin_document_state.should be(origin)
    wrapper.update_state.origin_document_state.should be(origin)
    referenced.update_state.origin_document_state.should be(origin)
    # setOriginDocumentState initializes the updated flag: everything that was
    # linked without dereferencing counts as updated (Java calls update()).
    parent.need_to_be_updated?.should be_true
    inner.need_to_be_updated?.should be_true
    referenced.need_to_be_updated?.should be_true
  end

  it "refuses to overwrite an already linked origin document state" do
    first = update_state_origin
    second = update_state_origin
    child = Pdfbox::Cos::Dictionary.new
    dictionary = Pdfbox::Cos::Dictionary.new
    dictionary[Pdfbox::Cos::Name.new("Child")] = child

    dictionary.update_state.origin_document_state = first
    dictionary.update_state.origin_document_state = second

    dictionary.update_state.origin_document_state.should be(first)
    child.update_state.origin_document_state.should be(first)
  end

  it "does not accept updates before an origin document state is linked" do
    dictionary = Pdfbox::Cos::Dictionary.new
    dictionary.update_state.accepting_updates?.should be_false
    dictionary.need_to_be_updated = true
    dictionary.need_to_be_updated?.should be_false

    # A document that is still parsing does not accept updates either.
    parsing = Pdfbox::Cos::DocumentState.new
    dictionary.update_state.origin_document_state = parsing
    dictionary.need_to_be_updated = true
    dictionary.need_to_be_updated?.should be_false

    parsing.parsing = false
    dictionary.update_state.accepting_updates?.should be_true
    dictionary.need_to_be_updated = true
    dictionary.need_to_be_updated?.should be_true
  end

  it "marks a dictionary updated and links the children that are set into it" do
    origin = update_state_origin
    parent = Pdfbox::Cos::Dictionary.new
    parent.update_state.origin_document_state = origin
    parent.set_need_to_be_updated(false)

    child = Pdfbox::Cos::Dictionary.new
    parent[Pdfbox::Cos::Name.new("Child")] = child

    parent.need_to_be_updated?.should be_true
    child.update_state.origin_document_state.should be(origin)
    # A newly added child is linked after parsing completed, hence updated.
    child.need_to_be_updated?.should be_true
  end

  it "marks a dictionary updated when items are removed or cleared" do
    origin = update_state_origin
    dictionary = Pdfbox::Cos::Dictionary.new
    dictionary[Pdfbox::Cos::Name.new("Value")] = Pdfbox::Cos::Integer.new(1)
    dictionary.update_state.origin_document_state = origin

    dictionary.set_need_to_be_updated(false)
    dictionary.delete(Pdfbox::Cos::Name.new("Value"))
    dictionary.need_to_be_updated?.should be_true

    dictionary.set_need_to_be_updated(false)
    dictionary.clear
    dictionary.need_to_be_updated?.should be_true
  end

  it "marks an array updated when items are added, replaced or removed" do
    origin = update_state_origin
    array = Pdfbox::Cos::Array.new
    array.update_state.origin_document_state = origin

    item = Pdfbox::Cos::Dictionary.new
    array.add(item)
    array.need_to_be_updated?.should be_true
    item.update_state.origin_document_state.should be(origin)
    item.need_to_be_updated?.should be_true

    array.set_need_to_be_updated(false)
    array[0] = Pdfbox::Cos::Integer.new(1)
    array.need_to_be_updated?.should be_true

    array.set_need_to_be_updated(false)
    array.delete_at(0)
    array.need_to_be_updated?.should be_true

    array.set_need_to_be_updated(false)
    array.clear
    array.need_to_be_updated?.should be_true
  end

  it "links a dereferenced COSObject's target without marking it updated" do
    origin = update_state_origin
    wrapper = Pdfbox::Cos::Object.new(9_i64, 0_i64, nil)
    wrapper.update_state.origin_document_state = origin
    wrapper.set_need_to_be_updated(false)

    target = Pdfbox::Cos::Dictionary.new
    wrapper.object = target
    target.update_state.origin_document_state.should be_nil

    wrapper.update_state.dereference_child(target)

    target.update_state.origin_document_state.should be(origin)
    # Dereferencing only links, it never counts as a modification.
    target.need_to_be_updated?.should be_false
  end

  it "creates an increment over its object" do
    origin = update_state_origin
    dictionary = Pdfbox::Cos::Dictionary.new
    dictionary.update_state.origin_document_state = origin

    increment = dictionary.update_state.to_increment
    increment.objects.size.should eq(1)
    increment.objects.first.same?(dictionary).should be_true

    # COSUpdateInfo#toIncrement is the same shortcut on the COS object itself.
    shortcut = dictionary.to_increment
    shortcut.objects.size.should eq(1)
    shortcut.objects.first.same?(dictionary).should be_true

    # An object that is not linked to a document state yields an empty increment.
    Pdfbox::Cos::Dictionary.new.to_increment.objects.should be_empty
  end
end

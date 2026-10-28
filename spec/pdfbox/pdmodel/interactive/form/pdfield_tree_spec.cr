require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDFieldTree.java
#     PDFieldTree(PDAcroForm) ("root cannot be null"), iterator(), FieldIterator
#     (queue + identity set on COSDictionary to prevent recursion, PDFBOX-5044).
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroForm.java
#     getFieldTree() returns a PDFieldTree; getFieldIterator() returns
#     new PDFieldTree(this).iterator(); flatten() copies the tree into a list.
#
# The upstream test (`PDFieldTreeTest#test5044`, the cyclic PDFBOX-4131-0
# fixture) is ported in pdfield_tree_test_spec.cr. These examples pin the class
# contract the array-based port did not express: the Java type, the parent-first
# order, re-iteration, and the identity guard on duplicated kid dictionaries.
private def field_tree_text_field(name : String) : Pdfbox::Cos::Dictionary
  dictionary = Pdfbox::Cos::Dictionary.new
  dictionary[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new(name)
  dictionary[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Tx")
  dictionary
end

# A form with one non-terminal field ("parent") holding two terminal kids, plus
# an optional duplicated kid to build the PDFBOX-5044 cycle.
private def field_tree_form(duplicate_kid : Bool = false)
  document = Pdfbox::Pdmodel::Document.create
  acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
  document.document_catalog.not_nil!.acro_form = acro_form

  kids = Pdfbox::Cos::Array.new
  first_kid = field_tree_text_field("kid1")
  kids.add(first_kid)
  kids.add(duplicate_kid ? first_kid : field_tree_text_field("kid2"))

  parent = Pdfbox::Cos::Dictionary.new
  parent[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("parent")
  parent[Pdfbox::Cos::Name.new("Kids")] = kids

  fields = Pdfbox::Cos::Array.new
  fields.add(parent)
  acro_form.cos_object[Pdfbox::Cos::Name.new("Fields")] = fields

  {document, acro_form}
end

describe Pdfbox::Pdmodel::Interactive::Form::PDFieldTree do
  it "rejects a nil AcroForm" do
    expect_raises(ArgumentError, /root cannot be null/) do
      Pdfbox::Pdmodel::Interactive::Form::PDFieldTree.new(nil)
    end
  end

  it "walks the fields parent before children" do
    document, acro_form = field_tree_form
    begin
      tree = acro_form.get_field_tree
      tree.should be_a(Pdfbox::Pdmodel::Interactive::Form::PDFieldTree)
      tree.map(&.fully_qualified_name).should eq(["parent", "parent.kid1", "parent.kid2"])
    ensure
      document.close
    end
  end

  it "can be iterated more than once" do
    document, acro_form = field_tree_form
    begin
      tree = acro_form.get_field_tree
      first = tree.map(&.fully_qualified_name)
      second = tree.map(&.fully_qualified_name)
      first.should eq(second)
      tree.size.should eq(3)
    ensure
      document.close
    end
  end

  it "exposes the same order through the field iterator" do
    document, acro_form = field_tree_form
    begin
      acro_form.field_iterator.to_a.map(&.fully_qualified_name)
        .should eq(acro_form.get_field_tree.map(&.fully_qualified_name))
    ensure
      document.close
    end
  end

  # PDFBOX-5044: the same kid dictionary must not be walked twice (that would
  # recurse forever on a self-referencing tree).
  it "yields each field once when a kid appears twice" do
    document, acro_form = field_tree_form(duplicate_kid: true)
    begin
      names = acro_form.get_field_tree.map(&.fully_qualified_name)
      names.should eq(["parent", "parent.kid1"])
    ensure
      document.close
    end
  end

  # Java PDFieldTree#iterator() returns a PDFieldTree.FieldIterator: a
  # pull-based iterator, not a materialized sequence.
  it "returns a pull-based FieldIterator from each and from field_iterator" do
    document, acro_form = field_tree_form
    begin
      iterator = acro_form.field_iterator
      iterator.should be_a(Pdfbox::Pdmodel::Interactive::Form::PDFieldTree::FieldIterator)
      iterator.should be_a(Iterator(Pdfbox::Pdmodel::Interactive::Form::PDField))

      names = [] of String
      while (field = iterator.next).is_a?(Pdfbox::Pdmodel::Interactive::Form::PDField)
        names << field.fully_qualified_name.not_nil!
      end
      names.should eq(["parent", "parent.kid1", "parent.kid2"])

      # the tree hands out a fresh iterator per call, so it can be re-iterated
      acro_form.get_field_tree.each
        .should be_a(Pdfbox::Pdmodel::Interactive::Form::PDFieldTree::FieldIterator)
    ensure
      document.close
    end
  end

  it "stops an iteration early without consuming the rest" do
    document, acro_form = field_tree_form
    begin
      tree = acro_form.get_field_tree
      seen = [] of String
      tree.each do |field|
        seen << field.fully_qualified_name.not_nil!
        break
      end
      seen.should eq(["parent"])
      # a second pass starts from the top again
      tree.map(&.fully_qualified_name).should eq(["parent", "parent.kid1", "parent.kid2"])
    ensure
      document.close
    end
  end
end

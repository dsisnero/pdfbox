require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDStructureElement.java
#
# Characterization spec: upstream PDStructureElementTest does not cover the
# attribute/class-name mutation helpers, so these assertions are inferred from
# the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  describe PDStructureElement do
    it "adds and removes attribute objects (addAttribute/removeAttribute)" do
      element = PDStructureElement.new("S", nil)
      element.revision_number = 5

      attr1 = PDDefaultAttributeObject.new
      element.add_attribute(attr1)
      element.attributes.size.should eq(1)
      element.attributes.get_object(0).cos_object.should be(attr1.cos_object)
      element.attributes.get_revision_number(0).should eq(5)

      attr2 = PDDefaultAttributeObject.new
      element.add_attribute(attr2)
      element.attributes.size.should eq(2)
      element.attributes.get_revision_number(1).should eq(5)

      element.remove_attribute(attr1)
      element.attributes.size.should eq(1)
      element.attributes.get_object(0).cos_object.should be(attr2.cos_object)
    end

    it "clears a single direct attribute dictionary when removed" do
      element = PDStructureElement.new("S", nil)
      only = PDDefaultAttributeObject.new

      revisions = Revisions(PDAttributeObject).new
      revisions.add_object(only, 0)
      element.attributes = revisions
      element.cos_object.get_dictionary_object(Pdfbox::Cos::Name.new("A"))
        .should be_a(Pdfbox::Cos::Dictionary)

      element.remove_attribute(only)
      element.cos_object.get_dictionary_object(Pdfbox::Cos::Name.new("A")).should be_nil
    end

    it "adds and removes class names (addClassName/removeClassName)" do
      element = PDStructureElement.new("S", nil)
      element.revision_number = 7

      element.add_class_name("MyClass")
      element.class_names.get_object(0).should eq("MyClass")
      element.class_names.get_revision_number(0).should eq(7)

      element.add_class_name("Other")
      element.class_names.size.should eq(2)

      element.remove_class_name("MyClass")
      element.class_names.size.should eq(1)
      element.class_names.get_object(0).should eq("Other")

      element.remove_class_name("Other")
      element.class_names.size.should eq(0)

      # A single direct class-name entry is cleared from the dictionary.
      direct = PDStructureElement.new("S", nil)
      direct.cos_object.set_item(Pdfbox::Cos::Name.new("C"), Pdfbox::Cos::Name.new("Only"))
      direct.remove_class_name("Only")
      direct.cos_object.get_dictionary_object(Pdfbox::Cos::Name.new("C")).should be_nil
    end

    it "resolves the containing structure tree root through the /P chain" do
      root = PDStructureTreeRoot.new

      section = PDStructureElement.new("Sect", nil)
      section.cos_object.set_item(Pdfbox::Cos::Name.new("P"), root.cos_object)

      child = PDStructureElement.new("P", nil)
      child.cos_object.set_item(Pdfbox::Cos::Name.new("P"), section.cos_object)

      child.structure_tree_root.should be_a(PDStructureTreeRoot)
      child.structure_tree_root.not_nil!.cos_object.should be(root.cos_object)

      orphan = PDStructureElement.new("P", nil)
      orphan.structure_tree_root.should be_nil
    end
  end
end

require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDStructureNode.java
#
# Characterization spec: upstream has no dedicated test for insert/remove kid, so
# these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  describe PDStructureElement do
    it "inserts a structure element before a reference kid (insertBefore)" do
      element = PDStructureElement.new("S", nil)
      child1 = PDStructureElement.new("P", nil)
      child2 = PDStructureElement.new("Span", nil)
      element.append_kid(child1)
      element.append_kid(child2)
      element.kids.size.should eq(2)

      new_kid = PDStructureElement.new("Em", nil)
      element.insert_before(new_kid, child2.cos_object)
      kids = element.kids
      kids.size.should eq(3)
      kids[0].as(PDStructureElement).structure_type.should eq("P")
      kids[1].as(PDStructureElement).structure_type.should eq("Em")
      kids[2].as(PDStructureElement).structure_type.should eq("Span")
    end

    it "removes a kid and collapses the array (removeKid)" do
      element = PDStructureElement.new("S", nil)
      child1 = PDStructureElement.new("P", nil)
      child2 = PDStructureElement.new("Span", nil)
      element.append_kid(child1)
      element.append_kid(child2)

      element.remove_kid(child1).should be_true
      element.kids.size.should eq(1)
      element.kids[0].as(PDStructureElement).structure_type.should eq("Span")

      element.remove_kid(child2).should be_true
      element.kids.should be_empty
      element.cos_object.get_dictionary_object(Pdfbox::Cos::Name.new("K")).should be_nil
    end

    it "inserts and removes integer marked-content identifiers" do
      element = PDStructureElement.new("S", nil)
      element.append_kid(5)
      element.kids.should eq([5])

      element.insert_before(3, Pdfbox::Cos::Integer.get(5_i64))
      element.kids.should eq([3, 5])

      element.remove_kid(3).should be_true
      element.kids.should eq([5])
    end

    it "creates the appropriate structure node from a dictionary (create)" do
      root_dict = Pdfbox::Cos::Dictionary.new
      root_dict.set_name("Type", PDStructureTreeRoot::TYPE)
      PDStructureElement.create(root_dict).should be_a(PDStructureTreeRoot)

      elem_dict = Pdfbox::Cos::Dictionary.new
      elem_dict.set_name("Type", PDStructureElement::TYPE)
      PDStructureElement.create(elem_dict).should be_a(PDStructureElement)

      no_type = Pdfbox::Cos::Dictionary.new
      PDStructureElement.create(no_type).should be_a(PDStructureElement)

      bad = Pdfbox::Cos::Dictionary.new
      bad.set_name("Type", "SomethingElse")
      expect_raises(ArgumentError) { PDStructureElement.create(bad) }
    end

    it "sets the whole kid list (setKids)" do
      element = PDStructureElement.new("S", nil)
      child = PDStructureElement.new("P", nil)
      mcr = PDMarkedContentReference.new
      mcr.mcid = 7

      element.kids = [child, mcr, 4]
      element.kids.size.should eq(3)
      element.kids[0].as(PDStructureElement).structure_type.should eq("P")
      element.kids[1].as(PDMarkedContentReference).mcid.should eq(7)
      element.kids[2].should eq(4)
    end
  end
end

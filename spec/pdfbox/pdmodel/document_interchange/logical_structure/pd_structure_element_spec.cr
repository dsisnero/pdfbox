require "../../../../spec_helper"

module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDStructureElementTest.java
  describe PDStructureElement do
    it "PDStructureElementTest#testSimple" do
      structure_element = PDStructureElement.new("S", nil)
      structure_element.type.should eq(PDStructureElement::TYPE)
      structure_element.structure_type.should eq("S")
      structure_element.parent.should be_nil

      structure_element.structure_type = "T"
      structure_element.structure_type.should eq("T")

      structure_element.element_identifier = "Ident"
      structure_element.element_identifier.should eq("Ident")

      structure_element.revision_number = 33
      structure_element.revision_number.should eq(33)

      structure_element.increment_revision_number
      structure_element.revision_number.should eq(34)

      expect_raises(ArgumentError) { structure_element.revision_number = -1 }

      structure_element.title = "Title"
      structure_element.title.should eq("Title")

      structure_element.language = "Klingon"
      structure_element.language.should eq("Klingon")

      structure_element.alternate_description = "Alto"
      structure_element.alternate_description.should eq("Alto")

      structure_element.actual_text = "Actual"
      structure_element.actual_text.should eq("Actual")

      structure_element.expanded_form = "ExpF"
      structure_element.expanded_form.should eq("ExpF")

      expect_raises(ArgumentError) { structure_element.append_kid(-1) }

      structure_element.append_kid(0)

      mcr1 = PDMarkedContentReference.new
      mcr1.mcid = 1
      structure_element.append_kid(mcr1)

      mcr2 = PDMarkedContentReference.new
      mcr2.mcid = 2
      mc2 = Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent.create(
        Pdfbox::Cos::Name.new("S"), mcr2.cos_object
      )
      structure_element.append_kid(mc2)

      mcr_sub_zero = PDMarkedContentReference.new
      expect_raises(ArgumentError) { mcr_sub_zero.mcid = -1 }
      mcr_sub_zero.cos_object.set_int(Pdfbox::Cos::Name.new("MCID"), -1)
      mc_sub_zero = Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent.create(
        Pdfbox::Cos::Name.new("S"), mcr_sub_zero.cos_object
      )
      expect_raises(ArgumentError) { structure_element.append_kid(mc_sub_zero) }

      kids = structure_element.kids
      kids.size.should eq(3)
      kids[0].should eq(0)
      kids[1].should be_a(PDMarkedContentReference)
      mcr1 = kids[1].as(PDMarkedContentReference)
      mcr1.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("Type")).should eq(PDMarkedContentReference::TYPE)
      mcr1.mcid.should eq(1)
      kids[2].should eq(2)
    end
  end
end

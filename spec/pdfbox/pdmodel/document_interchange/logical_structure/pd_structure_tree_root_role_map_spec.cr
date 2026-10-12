require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDStructureTreeRoot.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDStructureElement.java
#
# Characterization spec: upstream exercises the role map via PDFMergerUtilityTest
# (structure-tree split assertions); the standard-structure-type mapping is
# inferred from PDStructureElement#getStandardStructureType.
module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  describe PDStructureTreeRoot do
    it "round-trips the role map through the /RoleMap dictionary" do
      root = PDStructureTreeRoot.new
      root.role_map.should be_empty

      root.role_map = {"CustomH" => "H", "TOCI2" => "TOCI"}

      read = root.role_map
      read.size.should eq(2)
      read["CustomH"].should eq("H")
      read["TOCI2"].should eq("TOCI")

      role_map_dict = root.cos_object.get_dictionary(Cos::Name::ROLE_MAP)
      role_map_dict.should_not be_nil
      role_map_dict.not_nil!.get_name_as_string(Cos::Name.new("CustomH")).should eq("H")
    end
  end

  describe PDStructureElement do
    it "resolves the standard structure type through the containing root role map" do
      root = PDStructureTreeRoot.new
      root.role_map = {"CustomH" => "H"}

      parent = PDStructureElement.new("Sect", nil)
      parent.cos_object.set_item("P", root.cos_object)

      mapped = PDStructureElement.new("CustomH", parent)
      mapped.standard_structure_type.should eq("H")

      unmapped = PDStructureElement.new("P", parent)
      unmapped.standard_structure_type.should eq("P")
    end

    it "falls back to the element's own type without a containing root" do
      element = PDStructureElement.new("CustomH", nil)
      element.standard_structure_type.should eq("CustomH")
    end
  end
end

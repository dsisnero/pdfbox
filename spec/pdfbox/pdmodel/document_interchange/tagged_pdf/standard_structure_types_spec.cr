require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/StandardStructureTypes.java
#
# Data-parity spec: upstream has no dedicated test; the constants and the
# reflected `types` list are checked against the PDF 32000-1 Table 333 values.
module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  describe StandardStructureTypes do
    it "exposes the standard structure type names" do
      StandardStructureTypes::DOCUMENT.should eq("Document")
      StandardStructureTypes::PART.should eq("Part")
      StandardStructureTypes::BLOCK_QUOTE.should eq("BlockQuote")
      StandardStructureTypes::NON_STRUCT.should eq("NonStruct")
      StandardStructureTypes::P.should eq("P")
      StandardStructureTypes::H1.should eq("H1")
      StandardStructureTypes::L_BODY.should eq("LBody")
      StandardStructureTypes::TABLE.should eq("Table")
      StandardStructureTypes::T_HEAD.should eq("THead")
      StandardStructureTypes::T_FOOT.should eq("TFoot")
      StandardStructureTypes::BIB_ENTRY.should eq("BibEntry")
      StandardStructureTypes::WARICHU.should eq("Warichu")
      StandardStructureTypes::Figure.should eq("Figure")
      StandardStructureTypes::FORMULA.should eq("Formula")
      StandardStructureTypes::FORM.should eq("Form")
    end

    it "lists all standard structure types exactly once" do
      StandardStructureTypes::TYPES.size.should eq(49)
      StandardStructureTypes::TYPES.uniq.size.should eq(StandardStructureTypes::TYPES.size)
      StandardStructureTypes::TYPES.should contain("Document")
      StandardStructureTypes::TYPES.should contain("Figure")
      StandardStructureTypes::TYPES.should contain("Form")
    end
  end
end

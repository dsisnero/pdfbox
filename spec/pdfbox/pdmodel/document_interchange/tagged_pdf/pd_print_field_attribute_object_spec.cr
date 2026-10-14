require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/PDPrintFieldAttributeObject.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  describe PDPrintFieldAttributeObject do
    it "sets the PrintField owner" do
      attr = PDPrintFieldAttributeObject.new
      attr.owner.should eq(PDPrintFieldAttributeObject::OWNER_PRINT_FIELD)
    end

    it "round-trips role, checked state, and alternate name" do
      attr = PDPrintFieldAttributeObject.new
      attr.role.should be_nil
      attr.checked_state.should eq(PDPrintFieldAttributeObject::CHECKED_STATE_OFF)
      attr.alternate_name.should be_nil

      attr.role = PDPrintFieldAttributeObject::ROLE_CB
      attr.checked_state = PDPrintFieldAttributeObject::CHECKED_STATE_ON
      attr.alternate_name = "Check Box"

      attr.role.should eq("cb")
      attr.checked_state.should eq("on")
      attr.alternate_name.should eq("Check Box")
    end
  end
end

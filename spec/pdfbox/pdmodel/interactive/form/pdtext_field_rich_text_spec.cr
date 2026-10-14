require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDTextField.java
#
# Characterization spec: upstream has no dedicated test for the rich-text flag,
# so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDTextField do
    it "round-trips the rich-text flag (/Ff bit 25)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        field = PDTextField.new(acro)
        field.rich_text?.should be_false

        field.rich_text = true
        field.rich_text?.should be_true
        (field.field_flags & PDTextField::FLAG_RICH_TEXT).should eq(PDTextField::FLAG_RICH_TEXT)

        field.rich_text = false
        field.rich_text?.should be_false
        (field.field_flags & PDTextField::FLAG_RICH_TEXT).should eq(0)
      ensure
        document.close
      end
    end
  end
end

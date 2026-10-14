require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDSignatureField.java
#
# Characterization spec: upstream covers the constructor/convenience path; these
# assertions cover setValue/getDefaultValue and are inferred from the Java behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDSignatureField do
    it "round-trips the signature value and default value" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        field = PDSignatureField.new(acro)
        field.signature.should be_nil
        field.signed?.should be_false

        signature = PDSignature.new
        signature.name = "Alice"
        field.set_value(signature)
        field.signed?.should be_true
        field.signature.not_nil!.name.should eq("Alice")

        field.default_value.should be_nil
        default = PDSignature.new
        default.name = "Default"
        field.default_value = default
        field.default_value.not_nil!.name.should eq("Default")
      ensure
        document.close
      end
    end

    it "does not generate appearances (Java PDFBOX-3524 no-op)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        field = PDSignatureField.new(acro)
        field.construct_appearances
      ensure
        document.close
      end
    end
  end
end

require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocument.java
#
# Characterization spec: upstream has no dedicated test for these helpers, so
# these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel
  describe Document do
    it "lists signature fields and their signature dictionaries" do
      document = Document.new
      begin
        acro = Interactive::Form::PDAcroForm.new(document)
        document.document_catalog.not_nil!.acro_form = acro

        field1 = Interactive::Form::PDSignatureField.new(acro)
        field2 = Interactive::Form::PDSignatureField.new(acro)
        acro.set_fields([field1, field2])

        document.signature_fields.size.should eq(2)
        document.signature_dictionaries.should be_empty
        document.last_signature_dictionary.should be_nil

        sig1 = Interactive::Form::PDSignature.new
        sig1.name = "First"
        sig1.sign_date = Time.utc(2020, 1, 1)
        field1.set_value(sig1)

        sig2 = Interactive::Form::PDSignature.new
        sig2.name = "Second"
        sig2.sign_date = Time.utc(2021, 6, 1)
        field2.set_value(sig2)

        document.signature_dictionaries.size.should eq(2)
        document.last_signature_dictionary.not_nil!.name.should eq("Second")
      ensure
        document.close
      end
    end
  end
end

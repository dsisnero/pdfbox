require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDSignatureFieldTest.java
describe Pdfbox::Pdmodel::Interactive::Form::PDSignatureField do
  it "PDSignatureFieldTest#createDefaultSignatureField" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      sig_field = Pdfbox::Pdmodel::Interactive::Form::PDSignatureField.new(acro_form)
      sig_field.partial_name = "SignatureField"

      sig_field.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("FT")).should eq(sig_field.field_type)
      sig_field.field_type.should eq("Sig")

      sig_field.cos_object[Pdfbox::Cos::Name::TYPE].as(Pdfbox::Cos::Name).value.should eq("Annot")
      sig_field.cos_object.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE).should eq("Widget")

      acro_form.set_fields([sig_field])

      acro_form.get_field("SignatureField").should_not be_nil
    ensure
      document.close
    end
  end

  it "PDSignatureFieldTest#setValueForAbstractedSignatureField" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      sig_field = Pdfbox::Pdmodel::Interactive::Form::PDSignatureField.new(acro_form)
      sig_field.partial_name = "SignatureField"
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
        sig_field.value = "Can't set value using String"
      end
    ensure
      document.close
    end
  end

  it "PDSignatureFieldTest#testGetContents" do
    signature = Pdfbox::Pdmodel::Interactive::Form::PDSignature.new
    signature.byte_range = [0, 10, 30, 10]
    data = "AAAAAAAAAA<313233343536373839>BBBBBBBBBB".to_slice

    String.new(signature.get_contents(data)).should eq("123456789")

    io = ::IO::Memory.new(data)
    String.new(signature.get_contents(io)).should eq("123456789")
  end
end

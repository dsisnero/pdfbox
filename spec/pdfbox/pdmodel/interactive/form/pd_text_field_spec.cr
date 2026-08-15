require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDTextFieldTest.java
describe Pdfbox::Pdmodel::Interactive::Form::PDTextField do
  it "PDTextFieldTest#createDefaultTextField" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      text_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form)

      text_field.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("FT")).should eq(text_field.field_type)
      text_field.field_type.should eq("Tx")
    ensure
      document.close
    end
  end

  it "PDTextFieldTest#createWidgetForGet" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      text_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form)

      text_field.cos_object[Pdfbox::Cos::Name::TYPE]?.should be_nil
      text_field.cos_object.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE).should be_nil

      widget = text_field.widgets[0]

      text_field.cos_object[Pdfbox::Cos::Name::TYPE].as(Pdfbox::Cos::Name).value.should eq("Annot")
      text_field.cos_object.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE).should eq("Widget")

      widget.cos_object.should be(text_field.cos_object)
    ensure
      document.close
    end
  end
end

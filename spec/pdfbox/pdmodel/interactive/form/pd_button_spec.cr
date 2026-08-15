require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDButtonTest.java
describe Pdfbox::Pdmodel::Interactive::Form::PDButton do
  it "PDButtonTest#createCheckBox" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      button_field = Pdfbox::Pdmodel::Interactive::Form::PDCheckBox.new(acro_form)

      button_field.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("FT")).should eq(button_field.field_type)
      button_field.field_type.should eq("Btn")
      button_field.push_button?.should be_false
      button_field.radio_button?.should be_false
    ensure
      document.close
    end
  end

  it "PDButtonTest#createPushButton" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      button_field = Pdfbox::Pdmodel::Interactive::Form::PDPushButton.new(acro_form)

      button_field.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("FT")).should eq(button_field.field_type)
      button_field.field_type.should eq("Btn")
      button_field.push_button?.should be_true
      button_field.radio_button?.should be_false
    ensure
      document.close
    end
  end

  it "PDButtonTest#createRadioButton" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      button_field = Pdfbox::Pdmodel::Interactive::Form::PDRadioButton.new(acro_form)

      button_field.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("FT")).should eq(button_field.field_type)
      button_field.field_type.should eq("Btn")
      button_field.radio_button?.should be_true
      button_field.push_button?.should be_false
    ensure
      document.close
    end
  end
end

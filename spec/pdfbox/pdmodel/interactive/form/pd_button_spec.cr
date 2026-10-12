require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Loads the AcroFormsBasicFields.pdf fixture used by PDButtonTest's fixture-based
# cases (Java @BeforeEach). The PDFBOX-3656.pdf / PDFBOX-3682.pdf fixtures live
# only under target/pdfs in the vendor tree, so those two cases are not ported.
private def with_acro_form_basic_fields(&)
  path = SpecPaths.resolve(
    "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form/AcroFormsBasicFields.pdf")
  document = Pdfbox::Pdmodel::Document.load(path)
  begin
    yield document.document_catalog.not_nil!.acro_form.not_nil!
  ensure
    document.close
  end
end

private def cos_name_at(dict : Pdfbox::Cos::Dictionary, key : String) : String?
  value = dict.get_dictionary_object(Pdfbox::Cos::Name.new(key))
  value.as?(Pdfbox::Cos::Name).try(&.value)
end

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

  it "PDButtonTest#retrieveAcrobatCheckBoxProperties" do
    with_acro_form_basic_fields do |form|
      checkbox = form.get_field("Checkbox").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      checkbox.get_on_value.should eq("Yes")
      checkbox.get_on_values.size.should eq(1)
      checkbox.get_on_values.includes?("Yes").should be_true
    end
  end

  it "PDButtonTest#testAcrobatCheckBoxProperties" do
    with_acro_form_basic_fields do |form|
      checkbox = form.get_field("Checkbox").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      checkbox.value.should eq("Off")
      checkbox.checked?.should be_false

      checkbox.check
      checkbox.value.should eq(checkbox.get_on_value)
      checkbox.checked?.should be_true

      checkbox.value = "Yes"
      checkbox.value.should eq(checkbox.get_on_value)
      checkbox.checked?.should be_true
      cos_name_at(checkbox.cos_object, "AS").should eq("Yes")

      checkbox.value = "Off"
      checkbox.value.should eq("Off")
      checkbox.checked?.should be_false
      cos_name_at(checkbox.cos_object, "AS").should eq("Off")

      default_checkbox = form.get_field("Checkbox-DefaultValue").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      default_checkbox.default_value.should eq(default_checkbox.get_on_value)
      default_checkbox.default_value = "Off"
      default_checkbox.default_value.should eq("Off")
    end
  end

  it "PDButtonTest#setValueForAbstractedAcrobatCheckBox" do
    with_acro_form_basic_fields do |form|
      checkbox = form.get_field("Checkbox").not_nil!

      checkbox.value = "Yes"
      checkbox.value_as_string.should eq("Yes")
      checkbox.as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox).checked?.should be_true
      cos_name_at(checkbox.cos_object, "AS").should eq("Yes")

      checkbox.value = "Off"
      checkbox.value_as_string.should eq("Off")
      checkbox.as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox).checked?.should be_false
      cos_name_at(checkbox.cos_object, "AS").should eq("Off")
    end
  end

  it "PDButtonTest#testAcrobatCheckBoxGroupProperties" do
    with_acro_form_basic_fields do |form|
      checkbox = form.get_field("CheckboxGroup").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      checkbox.value.should eq("Off")
      checkbox.checked?.should be_false

      checkbox.check
      checkbox.value.should eq(checkbox.get_on_value)
      checkbox.checked?.should be_true

      checkbox.get_on_values.size.should eq(3)
      checkbox.get_on_values.includes?("Option1").should be_true
      checkbox.get_on_values.includes?("Option2").should be_true
      checkbox.get_on_values.includes?("Option3").should be_true

      checkbox.value = "Option1"
      checkbox.value.should eq("Option1")
      checkbox.value_as_string.should eq("Option1")
      checkbox.widgets[0].appearance_state.try(&.value).should eq("Option1")
      checkbox.widgets[1].appearance_state.try(&.value).should eq("Off")
      checkbox.widgets[2].appearance_state.try(&.value).should eq("Off")
      checkbox.widgets[3].appearance_state.try(&.value).should eq("Off")

      checkbox.value = "Option3"
      checkbox.value.should eq("Option3")
      checkbox.value_as_string.should eq("Option3")
      checkbox.widgets[0].appearance_state.try(&.value).should eq("Off")
      checkbox.widgets[1].appearance_state.try(&.value).should eq("Off")
      checkbox.widgets[2].appearance_state.try(&.value).should eq("Option3")
      checkbox.widgets[3].appearance_state.try(&.value).should eq("Option3")
    end
  end

  it "PDButtonTest#setValueForAbstractedCheckBoxGroup" do
    with_acro_form_basic_fields do |form|
      checkbox = form.get_field("CheckboxGroup").not_nil!

      checkbox.value = "Option1"
      checkbox.value_as_string.should eq("Option1")
      checkbox.widgets[0].appearance_state.try(&.value).should eq("Option1")
      checkbox.widgets[1].appearance_state.try(&.value).should eq("Off")
      checkbox.widgets[2].appearance_state.try(&.value).should eq("Off")
      checkbox.widgets[3].appearance_state.try(&.value).should eq("Off")

      checkbox.value = "Option3"
      checkbox.value_as_string.should eq("Option3")
      checkbox.widgets[0].appearance_state.try(&.value).should eq("Off")
      checkbox.widgets[1].appearance_state.try(&.value).should eq("Off")
      checkbox.widgets[2].appearance_state.try(&.value).should eq("Option3")
      checkbox.widgets[3].appearance_state.try(&.value).should eq("Option3")
    end
  end

  it "PDButtonTest#setCheckboxInvalidValue" do
    with_acro_form_basic_fields do |form|
      checkbox = form.get_field("Checkbox").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      expect_raises(ArgumentError) { checkbox.value = "InvalidValue" }
    end
  end

  it "PDButtonTest#setCheckboxGroupInvalidValue" do
    with_acro_form_basic_fields do |form|
      checkbox = form.get_field("CheckboxGroup").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      expect_raises(ArgumentError) { checkbox.value = "InvalidValue" }
    end
  end

  it "PDButtonTest#setAbstractedCheckboxInvalidValue" do
    with_acro_form_basic_fields do |form|
      expect_raises(ArgumentError) { form.get_field("Checkbox").not_nil!.value = "InvalidValue" }
    end
  end

  it "PDButtonTest#setAbstractedCheckboxGroupInvalidValue" do
    with_acro_form_basic_fields do |form|
      expect_raises(ArgumentError) { form.get_field("CheckboxGroup").not_nil!.value = "InvalidValue" }
    end
  end

  it "PDButtonTest#retrieveAcrobatRadioButtonProperties" do
    with_acro_form_basic_fields do |form|
      radio_button = form.get_field("RadioButtonGroup").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      radio_button.get_on_values.size.should eq(2)
      radio_button.get_on_values.includes?("RadioButton01").should be_true
      radio_button.get_on_values.includes?("RadioButton02").should be_true
    end
  end

  it "PDButtonTest#testAcrobatRadioButtonProperties" do
    with_acro_form_basic_fields do |form|
      radio_button = form.get_field("RadioButtonGroup").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)

      radio_button.value = "RadioButton01"
      radio_button.value.should eq("RadioButton01")
      cos_name_at(radio_button.widgets[0].cos_object, "AS").should eq("RadioButton01")
      cos_name_at(radio_button.widgets[1].cos_object, "AS").should eq("Off")

      radio_button.value = "RadioButton02"
      radio_button.value.should eq("RadioButton02")
      cos_name_at(radio_button.widgets[0].cos_object, "AS").should eq("Off")
      cos_name_at(radio_button.widgets[1].cos_object, "AS").should eq("RadioButton02")
    end
  end

  it "PDButtonTest#setValueForAbstractedAcrobatRadioButton" do
    with_acro_form_basic_fields do |form|
      radio_button = form.get_field("RadioButtonGroup").not_nil!

      radio_button.value = "RadioButton01"
      radio_button.value_as_string.should eq("RadioButton01")
      cos_name_at(radio_button.widgets[0].cos_object, "AS").should eq("RadioButton01")
      cos_name_at(radio_button.widgets[1].cos_object, "AS").should eq("Off")

      radio_button.value = "RadioButton02"
      radio_button.value_as_string.should eq("RadioButton02")
      cos_name_at(radio_button.widgets[0].cos_object, "AS").should eq("Off")
      cos_name_at(radio_button.widgets[1].cos_object, "AS").should eq("RadioButton02")
    end
  end

  it "PDButtonTest#setRadioButtonInvalidValue" do
    with_acro_form_basic_fields do |form|
      radio_button = form.get_field("RadioButtonGroup").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      expect_raises(ArgumentError) { radio_button.value = "InvalidValue" }
    end
  end

  it "PDButtonTest#setAbstractedRadioButtonInvalidValue" do
    with_acro_form_basic_fields do |form|
      expect_raises(ArgumentError) { form.get_field("RadioButtonGroup").not_nil!.value = "InvalidValue" }
    end
  end
end

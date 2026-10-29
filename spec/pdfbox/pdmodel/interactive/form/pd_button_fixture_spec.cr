require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "AcroFormsBasicFields.pdf"
private RESOURCE_DIR   = "spec/resources/pdfbox/pdmodel/interactive/form"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDButtonTest.java
# Fixture-based tests against AcroFormsBasicFields.pdf plus the PDFBOX-3656
# (radio button with /Opt) and PDFBOX-3682 (option names that are not indices)
# files, which are vendored under spec/resources/.
describe Pdfbox::Pdmodel::Interactive::Form::PDButton do
  it "PDButtonTest#retrieveAcrobatCheckBoxProperties" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      checkbox = acro_form.not_nil!.get_field("Checkbox").as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      checkbox.should_not be_nil
      checkbox.get_on_value.should eq("Yes")
      checkbox.get_on_values.size.should eq(1)
      checkbox.get_on_values.includes?("Yes").should be_true
    ensure
      document.close
    end
  end

  it "PDButtonTest#testAcrobatCheckBoxProperties" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      checkbox = acro_form.not_nil!.get_field("Checkbox").as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      checkbox.value.should eq("Off")
      checkbox.checked?.should be_false

      checkbox.check
      checkbox.value.should eq(checkbox.get_on_value)
      checkbox.checked?.should be_true

      checkbox.value = "Yes"
      checkbox.value.should eq(checkbox.get_on_value)
      checkbox.checked?.should be_true
      checkbox.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Yes")

      checkbox.value = "Off"
      Pdfbox::Cos::Name.new("Off").value.should eq(checkbox.value)
      checkbox.checked?.should be_false
      checkbox.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")

      checkbox = acro_form.not_nil!.get_field("Checkbox-DefaultValue").as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      checkbox.default_value.should eq(checkbox.get_on_value)

      checkbox.default_value = "Off"
      Pdfbox::Cos::Name.new("Off").value.should eq(checkbox.default_value)
    ensure
      document.close
    end
  end

  it "PDButtonTest#setCheckboxInvalidValue" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      checkbox = acro_form.not_nil!.get_field("Checkbox").as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      expect_raises(ArgumentError) { checkbox.value = "InvalidValue" }
    ensure
      document.close
    end
  end

  it "PDButtonTest#retrieveAcrobatRadioButtonProperties" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      radio_button = acro_form.not_nil!.get_field("RadioButtonGroup").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      radio_button.should_not be_nil
      radio_button.get_on_values.size.should eq(2)
      radio_button.get_on_values.includes?("RadioButton01").should be_true
      radio_button.get_on_values.includes?("RadioButton02").should be_true
    ensure
      document.close
    end
  end

  it "PDButtonTest#testAcrobatRadioButtonProperties" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      radio_button = acro_form.not_nil!.get_field("RadioButtonGroup").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)

      # Set value so that first radio button option is selected
      radio_button.value = "RadioButton01"
      radio_button.value.should eq("RadioButton01")
      radio_button.widgets[0].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("RadioButton01")
      radio_button.widgets[1].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")

      # Set value so that second radio button option is selected
      radio_button.value = "RadioButton02"
      radio_button.value.should eq("RadioButton02")
      radio_button.widgets[0].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")
      radio_button.widgets[1].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("RadioButton02")
    ensure
      document.close
    end
  end

  it "PDButtonTest#testAcrobatCheckBoxGroupProperties" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      checkbox = acro_form.not_nil!.get_field("CheckboxGroup").as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      checkbox.value.should eq("Off")
      checkbox.checked?.should be_false

      checkbox.check
      checkbox.value.should eq(checkbox.get_on_value)
      checkbox.checked?.should be_true

      checkbox.get_on_values.size.should eq(3)
      checkbox.get_on_values.includes?("Option1").should be_true
      checkbox.get_on_values.includes?("Option2").should be_true
      checkbox.get_on_values.includes?("Option3").should be_true

      # test a value which sets one of the individual checkboxes within the group
      checkbox.value = "Option1"
      checkbox.value.should eq("Option1")
      checkbox.value_as_string.should eq("Option1")

      checkbox.widgets[0].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Option1")
      checkbox.widgets[1].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")
      checkbox.widgets[2].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")
      checkbox.widgets[3].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")

      # test a value which sets two of the individual checkboxes within the group
      checkbox.value = "Option3"
      checkbox.value.should eq("Option3")
      checkbox.value_as_string.should eq("Option3")

      checkbox.widgets[0].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")
      checkbox.widgets[1].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")
      checkbox.widgets[2].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Option3")
      checkbox.widgets[3].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Option3")
    ensure
      document.close
    end
  end

  it "PDButtonTest#setCheckboxGroupInvalidValue" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      checkbox = acro_form.not_nil!.get_field("CheckboxGroup").as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox)
      expect_raises(ArgumentError) { checkbox.value = "InvalidValue" }
    ensure
      document.close
    end
  end

  it "PDButtonTest#setValueForAbstractedAcrobatCheckBox" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      checkbox = acro_form.not_nil!.get_field("Checkbox").as(Pdfbox::Pdmodel::Interactive::Form::PDField)
      checkbox.value = "Yes"
      checkbox.value_as_string.should eq(checkbox.as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox).get_on_value)
      checkbox.as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox).checked?.should be_true
      checkbox.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Yes")

      checkbox.value = "Off"
      Pdfbox::Cos::Name.new("Off").value.should eq(checkbox.value_as_string)
      checkbox.as(Pdfbox::Pdmodel::Interactive::Form::PDCheckBox).checked?.should be_false
      checkbox.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")
    ensure
      document.close
    end
  end

  it "PDButtonTest#setValueForAbstractedAcrobatRadioButton" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      radio_button = acro_form.not_nil!.get_field("RadioButtonGroup").as(Pdfbox::Pdmodel::Interactive::Form::PDField)

      radio_button.value = "RadioButton01"
      radio_button.value_as_string.should eq("RadioButton01")
      radio_button.widgets[0].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("RadioButton01")
      radio_button.widgets[1].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")

      radio_button.value = "RadioButton02"
      radio_button.value_as_string.should eq("RadioButton02")
      radio_button.widgets[0].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")
      radio_button.widgets[1].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("RadioButton02")
    ensure
      document.close
    end
  end

  it "PDButtonTest#setAbstractedCheckboxInvalidValue" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      checkbox = acro_form.not_nil!.get_field("Checkbox").as(Pdfbox::Pdmodel::Interactive::Form::PDField)
      expect_raises(ArgumentError) { checkbox.value = "InvalidValue" }
    ensure
      document.close
    end
  end

  it "PDButtonTest#setAbstractedRadioButtonInvalidValue" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      radio_button = acro_form.not_nil!.get_field("RadioButtonGroup").as(Pdfbox::Pdmodel::Interactive::Form::PDField)
      expect_raises(ArgumentError) { radio_button.value = "InvalidValue" }
    ensure
      document.close
    end
  end

  it "PDButtonTest#setRadioButtonInvalidValue" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      radio_button = acro_form.not_nil!.get_field("RadioButtonGroup").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      expect_raises(ArgumentError) { radio_button.value = "InvalidValue" }
    ensure
      document.close
    end
  end

  it "PDButtonTest#testRadioButtonWithOptions (PDFBOX-3656)" do
    # Fixture downloaded from the Java maven-wget URL (SHA512 verified).
    file = SpecPaths.resolve("#{RESOURCE_DIR}/PDFBOX-3656.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      radio_button = document.document_catalog.not_nil!.acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      radio_button.value = "Off"
      radio_button.widgets.each do |widget|
        widget.cos_object[Pdfbox::Cos::Name.new("AS")].as(Pdfbox::Cos::Name).value.should eq("Off")
      end
    ensure
      document.close
    end
  end

  it "PDButtonTest#testOptionsAndNamesNotNumbers (PDFBOX-3682)" do
    # Fixture downloaded from the Java maven-wget URL (SHA512 verified).
    file = SpecPaths.resolve("#{RESOURCE_DIR}/PDFBOX-3682.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.get_field("RadioButton").as(Pdfbox::Pdmodel::Interactive::Form::PDField).value = "c"
      radio_button = acro_form.not_nil!.get_field("RadioButton").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      radio_button.value = "c"

      # test that the old behavior is now invalid
      radio_button.value_as_string.should_not eq("2")
      radio_button.widgets[2].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should_not eq("2")

      # test for the correct behavior
      radio_button.value_as_string.should eq("c")
      radio_button.widgets[2].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("c")
    ensure
      document.close
    end
  end

  # PDFBOX-3656: setting a radio button to Off must clear every widget's /AS.
  it "PDButtonTest#testRadioButtonWithOptions" do
    file = SpecPaths.resolve("#{RESOURCE_DIR}/PDFBOX-3656.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form.not_nil!
      field = acro_form.get_field("Checking/Savings")
      field.should_not be_nil
      radio_button = field.not_nil!.as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      radio_button.value = "Off"

      radio_button.widgets.each do |widget|
        widget.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("Off")
      end
    ensure
      document.close
    end
  end

  # PDFBOX-3682: a radio button with /Opt whose On state is named after the
  # option (not after the index) must use that name for /V and /AS.
  it "PDButtonTest#testOptionsAndNamesNotNumbers" do
    file = SpecPaths.resolve("#{RESOURCE_DIR}/PDFBOX-3682.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form.not_nil!
      field = acro_form.get_field("RadioButton")
      field.should_not be_nil
      radio_button = field.not_nil!.as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      radio_button.value = "c"

      # the old index-based behavior is invalid
      radio_button.value_as_string.should_not eq("2")
      radio_button.widgets[2].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should_not eq("2")

      # the option name is the value
      radio_button.value_as_string.should eq("c")
      radio_button.widgets[2].cos_object.get_name_as_string(Pdfbox::Cos::Name.new("AS")).should eq("c")
    ensure
      document.close
    end
  end
end

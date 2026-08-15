require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private TESTFILE_3656  = "PDFBOX-3656-SF1199AEG (Complete).pdf"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/TestRadioButtons.java
# PDFBOX-5831 uses a remote JIRA attachment (not checked in) - out of scope.
describe Pdfbox::Pdmodel::Interactive::Form::PDRadioButton do
  it "TestRadioButtons#testRadioButtonPDModel" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      radio_button = Pdfbox::Pdmodel::Interactive::Form::PDRadioButton.new(acro_form)

      radio_button.default_value.should_not be_nil
      radio_button.get_selected_export_values.should_not be_nil
      radio_button.get_export_values.should_not be_nil
      radio_button.value.should_not be_nil

      options = ["Value01", "Value02"]
      radio_button.set_export_values(options)

      widgets = [] of Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget
      options.each do |option|
        widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
        ap_n_dict = Pdfbox::Cos::Dictionary.new
        ap_n_dict[Pdfbox::Cos::Name.new("Off")] = Pdfbox::Cos::Stream.new
        ap_n_dict[Pdfbox::Cos::Name.new(option)] = Pdfbox::Cos::Stream.new

        appearance = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new
        appearance_entry = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceEntry.new(ap_n_dict)
        appearance.normal_appearance = appearance_entry
        widget.appearance = appearance
        widget.appearance_state = "Off"
        widgets << widget
      end
      radio_button.set_widgets(widgets)

      radio_button.value = "Value01"
      radio_button.value.should eq("Value01")
      radio_button.get_selected_export_values.size.should eq(1)
      radio_button.get_selected_export_values[0].should eq("Value01")
      widgets[0].appearance_state.try(&.value).should eq("Value01")
      widgets[1].appearance_state.try(&.value).should eq("Off")

      radio_button.value = "Value02"
      radio_button.value.should eq("Value02")
      radio_button.get_selected_export_values.size.should eq(1)
      radio_button.get_selected_export_values[0].should eq("Value02")
      widgets[0].appearance_state.try(&.value).should eq("Off")
      widgets[1].appearance_state.try(&.value).should eq("Value02")

      radio_button.value = "Off"
      radio_button.value.should eq("Off")
      radio_button.get_selected_export_values.size.should eq(0)
      widgets[0].appearance_state.try(&.value).should eq("Off")
      widgets[1].appearance_state.try(&.value).should eq("Off")

      opt_item = radio_button.cos_object[Pdfbox::Cos::Name.new("Opt")]?.as(Pdfbox::Cos::Array)
      radio_button.cos_object[Pdfbox::Cos::Name.new("Opt")]?.should_not be_nil
      opt_item.size.should eq(2)
      opt_item.get_string(0).should eq(options[0])

      retrieved_options = radio_button.get_export_values
      retrieved_options.size.should eq(2)
      retrieved_options.should eq(options)

      radio_button.set_export_values(nil)
      radio_button.cos_object[Pdfbox::Cos::Name.new("Opt")]?.should be_nil
      radio_button.get_export_values.should be_empty
    ensure
      document.close
    end
  end

  it "TestRadioButtons#testPDFBox3656NotInUnison" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{TESTFILE_3656}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      field.radios_in_unison?.should be_false
    ensure
      document.close
    end
  end

  it "TestRadioButtons#testPDFBox3656ByValidExportValue" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{TESTFILE_3656}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      field.radios_in_unison?.should be_false
      field.value.should eq("Off")
      field.value = "Checking"
      field.value.should eq("Checking")
    ensure
      document.close
    end
  end

  it "TestRadioButtons#testPDFBox3656ByInvalidExportValue" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{TESTFILE_3656}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      field.radios_in_unison?.should be_false
      field.value.should eq("Off")

      exception = expect_raises(ArgumentError) { field.value = "Invalid" }

      exception.message.not_nil!.should contain("value 'Invalid' is not a valid option for the field Checking/Savings, valid values are: [Checking, Savings] and Off")

      field.value.should eq("Off")
      field.get_selected_export_values.should be_empty
    ensure
      document.close
    end
  end

  it "TestRadioButtons#testPDFBox3656ByValidIndex" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{TESTFILE_3656}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      field.radios_in_unison?.should be_false
      field.value.should eq("Off")
      field.set_value_index(4)
      field.value.should eq("Checking")
    ensure
      document.close
    end
  end

  it "TestRadioButtons#testPDFBox3656ByInvalidIndex" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{TESTFILE_3656}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      field.radios_in_unison?.should be_false
      field.value.should eq("Off")

      exception = expect_raises(ArgumentError) { field.set_value_index(6) }

      exception.message.not_nil!.should contain("index '6' is not a valid index for the field Checking/Savings, valid indices are from 0 to 5")

      field.value.should eq("Off")
      field.get_selected_export_values.should be_empty
    ensure
      document.close
    end
  end

  it "TestRadioButtons#testPDFBox4617IndexNoneSelected" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{TESTFILE_3656}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      field.get_selected_index.should eq(-1)
    ensure
      document.close
    end
  end

  it "TestRadioButtons#testPDFBox4617IndexForSetByOption" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{TESTFILE_3656}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      field.value = "Checking"
      field.get_selected_index.should eq(0)
    ensure
      document.close
    end
  end

  it "TestRadioButtons#testPDFBox4617IndexForSetByIndex" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{TESTFILE_3656}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Checking/Savings").as(Pdfbox::Pdmodel::Interactive::Form::PDRadioButton)
      field.set_value_index(4)
      field.value.should eq("Checking")
      field.get_selected_index.should eq(4)
    ensure
      document.close
    end
  end
end

require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDChoiceTest.java
describe Pdfbox::Pdmodel::Interactive::Form::PDChoice do
  it "PDChoiceTest#createListBox" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      choice_field = Pdfbox::Pdmodel::Interactive::Form::PDListBox.new(acro_form)

      choice_field.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("FT")).should eq(choice_field.field_type)
      choice_field.field_type.should eq("Ch")
      choice_field.combo?.should be_false
    ensure
      document.close
    end
  end

  it "PDChoiceTest#createComboBox" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      choice_field = Pdfbox::Pdmodel::Interactive::Form::PDComboBox.new(acro_form)

      choice_field.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("FT")).should eq(choice_field.field_type)
      choice_field.field_type.should eq("Ch")
      choice_field.combo?.should be_true
    ensure
      document.close
    end
  end

  it "PDChoiceTest#getOptionsFromStrings" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      choice_field = Pdfbox::Pdmodel::Interactive::Form::PDComboBox.new(acro_form)

      options_array = Pdfbox::Cos::Array.new
      options_array.add(Pdfbox::Cos::String.new(" "))
      options_array.add(Pdfbox::Cos::String.new("A"))
      options_array.add(Pdfbox::Cos::String.new("B"))
      choice_field.cos_object[Pdfbox::Cos::Name.new("Opt")] = options_array

      choice_field.get_options.should eq([" ", "A", "B"])
    ensure
      document.close
    end
  end

  it "PDChoiceTest#getOptionsFromCOSArray" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      choice_field = Pdfbox::Pdmodel::Interactive::Form::PDComboBox.new(acro_form)

      options_array = Pdfbox::Cos::Array.new
      [" ", "A", "B"].each do |value|
        entry = Pdfbox::Cos::Array.new
        entry.add(Pdfbox::Cos::String.new(value))
        options_array.add(entry)
      end

      choice_field.cos_object[Pdfbox::Cos::Name.new("Opt")] = options_array

      choice_field.get_options.should eq([" ", "A", "B"])
    ensure
      document.close
    end
  end

  it "PDChoiceTest#getOptionsFromMixed" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      choice_field = Pdfbox::Pdmodel::Interactive::Form::PDComboBox.new(acro_form)

      options_array = Pdfbox::Cos::Array.new
      options_array.add(Pdfbox::Cos::String.new(" "))
      entry = Pdfbox::Cos::Array.new
      entry.add(Pdfbox::Cos::String.new("A"))
      options_array.add(entry)
      entry = Pdfbox::Cos::Array.new
      entry.add(Pdfbox::Cos::String.new("B"))
      options_array.add(entry)

      choice_field.cos_object[Pdfbox::Cos::Name.new("Opt")] = options_array

      choice_field.get_options.should eq([" ", "A", "B"])
    ensure
      document.close
    end
  end
end

require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/TestCheckBox.java
describe Pdfbox::Pdmodel::Interactive::Form::PDCheckBox do
  it "TestCheckBox#testCheckboxPDModel" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      check_box = Pdfbox::Pdmodel::Interactive::Form::PDCheckBox.new(acro_form)

      check_box.get_export_values.should_not be_nil
      check_box.value.should_not be_nil

      options = ["Value01", "Value02"]
      check_box.set_export_values(options)

      opt_item = check_box.cos_object[Pdfbox::Cos::Name.new("Opt")]?.as(Pdfbox::Cos::Array)
      check_box.cos_object[Pdfbox::Cos::Name.new("Opt")]?.should_not be_nil
      opt_item.size.should eq(2)
      opt_item.get_string(0).should eq(options[0])

      retrieved_options = check_box.get_export_values
      retrieved_options.size.should eq(2)
      retrieved_options.should eq(options)

      check_box.set_export_values(nil)
      check_box.cos_object[Pdfbox::Cos::Name.new("Opt")]?.should be_nil
      check_box.get_export_values.should be_empty
    ensure
      document.close
    end
  end

  it "TestCheckBox#testCheckBoxNoAppearance" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      document.add_page(page)
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      acro_form.need_appearances = true
      document.document_catalog.not_nil!.acro_form = acro_form

      check_box = Pdfbox::Pdmodel::Interactive::Form::PDCheckBox.new(acro_form)
      check_box.partial_name = "checkbox"
      widget = check_box.widgets[0]
      widget.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 600.0_f32, 100.0_f32, 100.0_f32)
      border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
      border_style.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary::STYLE_SOLID
      border_style.width = 1

      acd = Pdfbox::Cos::Dictionary.new
      appearance_characteristics = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(acd)
      appearance_characteristics.background = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
      appearance_characteristics.border_colour = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
      appearance_characteristics.normal_caption = "4"
      widget.appearance_characteristics = appearance_characteristics
      widget.border_style = border_style

      check_box.value = "Off"
      page.annotations.add(widget)
      acro_form.add_field(check_box)
      check_box.value.should eq("Off")
    ensure
      document.close
    end
  end
end

require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "AcroFormsBasicFields.pdf"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/TestFields.java
describe Pdfbox::Pdmodel::Interactive::Form::PDTextField do
  it "TestFields#testFlags" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      text_box = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form)

      text_box.comb?.should be_false

      text_box.comb = true
      text_box.comb?.should be_true
      text_box.comb = false
      text_box.comb?.should be_false

      text_box.comb = true
      text_box.do_not_scroll = true
      text_box.comb?.should be_true
      text_box.do_not_scroll?.should be_true

      text_box.comb = false
      text_box.do_not_scroll = false
      text_box.comb?.should be_false
      text_box.do_not_scroll?.should be_false

      text_box.comb = false
      text_box.comb?.should be_false
      text_box.comb = false
      text_box.comb?.should be_false

      text_box.comb = true
      text_box.comb?.should be_true
      text_box.comb = true
      text_box.comb?.should be_true
    ensure
      document.close
    end
  end

  it "TestFields#testAcroFormsBasicFields" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.should_not be_nil

      text_field = acro_form.not_nil!.get_field("TextField").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      text_field.cos_object[Pdfbox::Cos::Name.new("V")]?.should be_nil
      text_field.value = "field value"
      text_field.cos_object[Pdfbox::Cos::Name.new("V")]?.should_not be_nil
      text_field.value.should eq("field value")

      text_field.cos_object[Pdfbox::Cos::Name.new("V")]?.should_not be_nil
      text_field.value = nil
      text_field.cos_object[Pdfbox::Cos::Name.new("V")]?.should be_nil

      text_field = acro_form.not_nil!.get_field("TextField-DefaultValue").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      text_field.should_not be_nil
      text_field.default_value.should eq("DefaultValue")
      text_field.cos_object[Pdfbox::Cos::Name.new("DV")].as(Pdfbox::Cos::String).value.should eq(text_field.default_value)
      text_field.default_appearance.should eq("/Helv 12 Tf 0 g")

      text_field = acro_form.not_nil!.get_field("RichTextField-DefaultValue").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      text_field.should_not be_nil
      text_field.default_value.should eq("DefaultValue")
      text_field.cos_object[Pdfbox::Cos::Name.new("DV")].as(Pdfbox::Cos::String).value.should eq(text_field.default_value)
      text_field.value.should eq("DefaultValue")
      text_field.default_appearance.should eq("/Helv 12 Tf 0 g")
      text_field.default_style_string.should eq("font: Helvetica,sans-serif 12.0pt; text-align:left; color:#000000 ")
      text_field.rich_text_value.size.should eq(338)

      text_field = acro_form.not_nil!.get_field("LongRichTextField").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      text_field.should_not be_nil
      v_value = text_field.cos_object[Pdfbox::Cos::Name.new("V")]?
      v_value = v_value.object if v_value.is_a?(Pdfbox::Cos::Object)
      v_value.should be_a(Pdfbox::Cos::Stream)
      text_field.value.size.should eq(145396)
    ensure
      document.close
    end
  end

  it "TestFields#testWidgetMissingRect" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form

      text_field = acro_form.not_nil!.get_field("TextField-DefaultValue").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      widget = text_field.widgets[0]

      widget.cos_object[Pdfbox::Cos::Name.new("AP")]?.should_not be_nil
      widget.cos_object.delete(Pdfbox::Cos::Name.new("Rect"))
      text_field.value = "field value"

      # There shall be no appearance entry if there is no /Rect to behave as
      # Adobe Acrobat does
      widget.cos_object[Pdfbox::Cos::Name.new("AP")]?.should be_nil
    ensure
      document.close
    end
  end
end

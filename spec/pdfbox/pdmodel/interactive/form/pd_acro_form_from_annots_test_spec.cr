require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private RESOURCE_DIR = "spec/resources/pdfbox/pdmodel/interactive/form"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormFromAnnotsTest.java
# Fixtures downloaded from the Java JIRA attachment URLs (SHA512 recorded in
# spec/resources/pdfbox/pdmodel/interactive/form/SHA512SUMS).
describe Pdfbox::Pdmodel::Document do
  it "PDAcroFormFromAnnotsTest#testFromAnnots4985DefaultMode (PDFBOX-4985)" do
    acrobat_file = SpecPaths.resolve("#{RESOURCE_DIR}/POPPLER-806-acrobat.pdf")
    acrobat_doc = Pdfbox::Loader.load_pdf(acrobat_file)
    num_fields_by_acrobat = 0
    begin
      acro_form = acrobat_doc.document_catalog.not_nil!.acro_form
      num_fields_by_acrobat = acro_form.not_nil!.get_field_tree.size
    ensure
      acrobat_doc.close
    end

    file = SpecPaths.resolve("#{RESOURCE_DIR}/POPPLER-806.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form_dict = document.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("AcroForm")]
      acro_form_dict = acro_form_dict.object if acro_form_dict.is_a?(Pdfbox::Cos::Object)
      fields_value = acro_form_dict.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Fields")]
      fields_value = fields_value.object if fields_value.is_a?(Pdfbox::Cos::Object)
      cos_fields = fields_value.as(Pdfbox::Cos::Array)
      cos_fields.items.size.should eq(0)

      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.rebuild_fields_from_widgets
      acro_form.not_nil!.get_field_tree.size.should eq(num_fields_by_acrobat)
    ensure
      document.close
    end
  end

  it "PDAcroFormFromAnnotsTest#testFromAnnots3891DontCreateFields" do
    file = SpecPaths.resolve("#{RESOURCE_DIR}/merge-test.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form_dict = document.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("AcroForm")]
      acro_form_dict = acro_form_dict.object if acro_form_dict.is_a?(Pdfbox::Cos::Object)
      cos_fields = acro_form_dict.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Fields")].as(Pdfbox::Cos::Array)
      cos_fields.items.size.should eq(0)

      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.get_field_tree.size.should eq(0)
    ensure
      document.close
    end
  end

  it "PDAcroFormFromAnnotsTest#testFromAnnots3891CreateFields" do
    acrobat_file = SpecPaths.resolve("#{RESOURCE_DIR}/merge-test-na-acrobat.pdf")
    acrobat_doc = Pdfbox::Loader.load_pdf(acrobat_file)
    fields_by_name = {} of String => Pdfbox::Pdmodel::Interactive::Form::PDField
    num_fields_by_acrobat = 0
    begin
      acro_form = acrobat_doc.document_catalog.not_nil!.acro_form
      num_fields_by_acrobat = acro_form.not_nil!.get_field_tree.size
      acro_form.not_nil!.get_field_tree.each do |field|
        fields_by_name[field.fully_qualified_name] = field
      end
    ensure
      acrobat_doc.close
    end

    file = SpecPaths.resolve("#{RESOURCE_DIR}/merge-test.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form_dict = document.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("AcroForm")]
      acro_form_dict = acro_form_dict.object if acro_form_dict.is_a?(Pdfbox::Cos::Object)
      cos_fields = acro_form_dict.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Fields")].as(Pdfbox::Cos::Array)
      cos_fields.items.size.should eq(0)

      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.rebuild_fields_from_widgets
      acro_form.not_nil!.get_field_tree.size.should eq(num_fields_by_acrobat)

      acro_form.not_nil!.get_field_tree.each do |field|
        fields_by_name.has_key?(field.fully_qualified_name).should be_true
      end

      fields_by_name.each_key do |field_name|
        acro_form.not_nil!.get_field(field_name).should_not be_nil
      end
    ensure
      document.close
    end
  end

  it "PDAcroFormFromAnnotsTest#testFromAnnots3891NullField" do
    file = SpecPaths.resolve("#{RESOURCE_DIR}/poppler-14433-0.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      # Getting the AcroForm with the create-fields fixup shall not throw
      document.document_catalog.not_nil!.acro_form.not_nil!.rebuild_fields_from_widgets
    ensure
      document.close
    end
  end
end

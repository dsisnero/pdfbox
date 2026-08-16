require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "AcroFormsRotation.pdf"
private TEST_VALUE     = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr,"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/AcroFormsRotationTest.java
# The Java rendering comparison is advisory; the behavioral assertion is that
# every rotated field's value round-trips through appearance generation
# (exercises the rotation matrix path).
describe Pdfbox::Pdmodel::Interactive::Form::PDAcroForm do
  it "AcroFormsRotationTest#fillFields" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form

      %w(
        pdfbox.portrait.single.rotation0 pdfbox.portrait.single.rotation90
        pdfbox.portrait.single.rotation180 pdfbox.portrait.single.rotation270
      ).each do |name|
        field = acro_form.not_nil!.get_field(name).as(Pdfbox::Pdmodel::Interactive::Form::PDField)
        field.value = field.fully_qualified_name
        field.value_as_string.should eq(field.fully_qualified_name)
      end

      %w(
        pdfbox.portrait.multi.rotation0 pdfbox.portrait.multi.rotation90
        pdfbox.portrait.multi.rotation180 pdfbox.portrait.multi.rotation270
      ).each do |name|
        field = acro_form.not_nil!.get_field(name).as(Pdfbox::Pdmodel::Interactive::Form::PDField)
        expected = "#{field.fully_qualified_name}\n#{TEST_VALUE}"
        field.value = expected
        field.value_as_string.should eq(expected)
      end

      %w(
        pdfbox.page90.single.rotation0 pdfbox.page90.single.rotation90
        pdfbox.page90.single.rotation180 pdfbox.page90.single.rotation270
      ).each do |name|
        field = acro_form.not_nil!.get_field(name).as(Pdfbox::Pdmodel::Interactive::Form::PDField)
        field.value = name
        field.value_as_string.should eq(name)
      end

      %w(
        pdfbox.page90.multi.rotation0 pdfbox.page90.multi.rotation90
        pdfbox.page90.multi.rotation180 pdfbox.page90.multi.rotation270
      ).each do |name|
        field = acro_form.not_nil!.get_field(name).as(Pdfbox::Pdmodel::Interactive::Form::PDField)
        expected = "#{field.fully_qualified_name}\n#{TEST_VALUE}"
        field.value = expected
        field.value_as_string.should eq(expected)
      end
    ensure
      document.close
    end
  end
end

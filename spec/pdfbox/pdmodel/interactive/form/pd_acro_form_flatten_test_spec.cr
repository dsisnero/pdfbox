require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "AlignmentTests.pdf"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormTest.java
#   testFlatten / testFlattenWidgetNoRef. The Java rendering comparison
#   (TestPDFToImage.doTestFile) is advisory (only logs on mismatch); the
#   behavioral assertions are fields-empty and annotation-count checks.

private def count_widgets(document : Pdfbox::Pdmodel::Document) : Int32
  count = 0
  document.pages.each do |page|
    page.annotations.each do |annot|
      count += 1 if annot.is_a?(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget)
    end
  end
  count
end

describe Pdfbox::Pdmodel::Interactive::Form::PDAcroForm do
  it "PDAcroFormTest#testFlatten" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.flatten
      acro_form.not_nil!.get_field_tree.size.should eq(0)
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testFlattenWidgetNoRef" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.get_field_tree.each do |field|
        field.widgets.each do |widget|
          widget.cos_object.delete(Pdfbox::Cos::Name.new("P"))
        end
      end
      acro_form.not_nil!.flatten

      # 36 non widget annotations shall not be flattened
      document.pages[0].annotations.size.should eq(36)

      acro_form.not_nil!.get_field_tree.size.should eq(0)
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testFlattenSpecificFieldsOnly" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      num_fields_before = acro_form.not_nil!.get_field_tree.size
      num_widgets_before = count_widgets(document)

      fields_to_flatten = [
        acro_form.not_nil!.get_field("AlignLeft-Border_Small-Filled"),
        acro_form.not_nil!.get_field("AlignLeft-Border_Medium-Filled"),
        acro_form.not_nil!.get_field("AlignLeft-Border_Wide-Filled"),
        acro_form.not_nil!.get_field("AlignLeft-Border_Wide_Clipped-Filled"),
      ].compact

      acro_form.not_nil!.flatten(fields_to_flatten, true)
      num_fields_after = acro_form.not_nil!.get_field_tree.size
      num_widgets_after = count_widgets(document)

      num_fields_before.should eq(num_fields_after + fields_to_flatten.size)
      num_widgets_before.should eq(num_widgets_after + fields_to_flatten.size)
    ensure
      document.close
    end
  end
end

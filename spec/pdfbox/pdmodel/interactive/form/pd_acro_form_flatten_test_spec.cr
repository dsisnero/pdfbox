require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "AlignmentTests.pdf"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormTest.java
#   testFlatten / testFlattenWidgetNoRef. The Java rendering comparison
#   (TestPDFToImage.doTestFile) is advisory (only logs on mismatch); the
#   behavioral assertions are fields-empty and annotation-count checks.
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
end

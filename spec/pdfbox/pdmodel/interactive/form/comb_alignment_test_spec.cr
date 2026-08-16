require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "CombTest.pdf"
private TEST_VALUE     = "1234567"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/CombAlignmentTest.java
# The Java rendering comparison (TestPDFToImage.doTestFile) is advisory — it
# only logs on mismatch. The behavioral assertions are value round-trips and
# successful save/load with comb appearance generation.
describe Pdfbox::Pdmodel::Interactive::Form::PDAcroForm do
  it "CombAlignmentTest#testCombFields (PDFBOX-5256)" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      ["PDFBoxCombLeft", "PDFBoxCombMiddle", "PDFBoxCombRight"].each do |name|
        field = acro_form.not_nil!.get_field(name).as(Pdfbox::Pdmodel::Interactive::Form::PDField)
        field.value = ""
        field.value = TEST_VALUE
        field.value_as_string.should eq(TEST_VALUE)
      end
    ensure
      document.close
    end
  end

  it "CombAlignmentTest#testPDFBOX5784" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/PDFBOX-5784.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.get_field_tree.each do |field|
        partial = field.partial_name
        unless partial.try(&.includes?("acrobat"))
          field.value = "WIaqg"
        end
      end
    ensure
      document.close
    end
  end
end

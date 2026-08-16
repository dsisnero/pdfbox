require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "AlignmentTests.pdf"
private TEST_VALUE     = "Test"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/AlignmentTest.java
# The Java rendering comparison (TestPDFToImage.doTestFile) is advisory — it
# only logs on mismatch. The behavioral assertion is value round-trips for all
# alignment fields (left/middle/right with various border sizes).
describe Pdfbox::Pdmodel::Interactive::Form::PDAcroForm do
  it "AlignmentTest#fillFields" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      %w(
        AlignLeft AlignLeft-Border_Small AlignLeft-Border_Medium AlignLeft-Border_Wide
        AlignLeft-Border_Wide_Clipped AlignLeft-Border_Small_Outside
        AlignMiddle AlignMiddle-Border_Small AlignMiddle-Border_Medium AlignMiddle-Border_Wide
        AlignMiddle-Border_Wide_Clipped AlignMiddle-Border_Medium_Outside
        AlignRight AlignRight-Border_Small AlignRight-Border_Medium AlignRight-Border_Wide
        AlignRight-Border_Wide_Clipped AlignRight-Border_Wide_Outside
      ).each do |name|
        field = acro_form.not_nil!.get_field(name)
        field.should_not be_nil
        field.not_nil!.value = TEST_VALUE
        field.not_nil!.value_as_string.should eq(TEST_VALUE)
      end
    ensure
      document.close
    end
  end
end

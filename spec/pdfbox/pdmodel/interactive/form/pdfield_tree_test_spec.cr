require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private RESOURCE_DIR = "spec/resources/pdfbox/pdmodel/interactive/form"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDFieldTreeTest.java
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormTest.java
# Fixtures downloaded from the Java JIRA attachment URLs (SHA512 recorded).
describe Pdfbox::Pdmodel::Document do
  it "PDFieldTreeTest#test5044 (PDFBOX-5044)" do
    # PDFBOX-5044 stack overflow: getAcroForm().getFieldTree() must not overflow.
    file = SpecPaths.resolve("#{RESOURCE_DIR}/PDFBOX-4131-0.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      count = 0
      acro_form.not_nil!.get_field_tree.each { |_field| count += 1 }
      count.should eq(4)
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testIllegalFieldsDefinition" do
    # Getting the AcroForm shall not throw an exception when /Fields is a
    # COSDictionary instead of an array.
    file = SpecPaths.resolve("#{RESOURCE_DIR}/D1790B.PDF")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      document.document_catalog.not_nil!.acro_form.should_not be_nil
    ensure
      document.close
    end
  end
end

require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private RESOURCE_DIR = "spec/resources/pdfbox/pdmodel/interactive/form"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormGenerateAppearancesTest.java
# Fixtures downloaded from the Java JIRA attachment URLs (SHA512 recorded in
# spec/resources/pdfbox/pdmodel/interactive/form/SHA512SUMS).
describe Pdfbox::Pdmodel::Document do
  {
    "PDFBOX-5041 Missing font descriptor"        => "PDFBOX-5041.pdf",
    "PDFBOX-4086 Character missing for encoding" => "PDFBOX-4086.pdf",
    "PDFBOX-5043 PaperMetaData"                  => "PDFBOX-5043.pdf",
  }.each do |label, file_name|
    it "PDAcroFormGenerateAppearancesTest#testGetAcroForm (#{label})" do
      file = SpecPaths.resolve("#{RESOURCE_DIR}/#{file_name}")
      document = Pdfbox::Loader.load_pdf(file)
      begin
        # Getting the AcroForm shall not throw an exception
        document.document_catalog.not_nil!.acro_form.should_not be_nil
      ensure
        document.close
      end
    end
  end
end

require "../../spec_helper"

module Pdfbox::Pdmodel
  describe PDPageTree do
    it "TestPDPageTree#testNodeLoop" do
      path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/PDFBOX-6040-nodeloop.pdf")
      doc = Pdfbox::Loader.load_pdf(path)
      begin
        doc.get_page(0).resources.should be_nil
      ensure
        doc.close
      end
    end
  end
end

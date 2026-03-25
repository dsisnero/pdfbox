require "../../spec_helper"

describe "PDFTextStripper bidi fixtures" do
  it "extracts BidiSample.pdf like the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text/BidiSample.pdf")
    expected_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text/BidiSample.pdf.txt")

    expected = File.read(expected_path, encoding: "UTF-8").strip

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      actual = Pdfbox::Text::PDFTextStripper.new.get_text(doc).strip
      actual.should eq(expected)
    ensure
      doc.close
    end
  end
end

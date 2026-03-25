require "../../spec_helper"

describe Pdfbox::Text::PDFTextStripper do
  it "extracts text from hello3.pdf using the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")
    expected_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf.txt")

    expected = File.read(expected_path, encoding: "UTF-8")
    expected = expected[1..] if expected.starts_with?('\uFEFF')
    expected = expected.strip

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      actual = Pdfbox::Text::PDFTextStripper.new.get_text(doc).strip
      actual.should eq(expected)
    ensure
      doc.close
    end
  end
end

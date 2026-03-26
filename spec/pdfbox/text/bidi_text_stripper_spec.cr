require "../../spec_helper"

describe "PDFTextStripper bidi fixtures" do
  it "extracts BidiSample.pdf without sorting like the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text/BidiSample.pdf")
    expected_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text/BidiSample.pdf.txt")

    expected = File.read(expected_path, encoding: "UTF-8").strip

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.sort_by_position = false

      actual = stripper.get_text(doc).strip
      actual.should eq(expected)
    ensure
      doc.close
    end
  end

  it "extracts BidiSample.pdf with sorting like the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text/BidiSample.pdf")
    expected_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text/BidiSample.pdf-sorted.txt")

    expected = File.read(expected_path, encoding: "UTF-8").strip

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.sort_by_position = true

      actual = stripper.get_text(doc).strip
      actual.should eq(expected)
    ensure
      doc.close
    end
  end
end

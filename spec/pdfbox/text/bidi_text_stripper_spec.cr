require "../../spec_helper"

describe "PDFTextStripper bidi fixtures" do
  pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text/BidiSample.pdf")
  fixture_dir = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text")

  it "extracts BidiSample.pdf without sorting matching Java fixture" do
    expected = File.read(File.join(fixture_dir, "BidiSample.pdf.txt"), encoding: "UTF-8").strip

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.sort_by_position = false
      actual = stripper.get_text(doc).strip
    ensure
      doc.close
    end

    actual.should eq(expected)
    actual.should contain("test")
    actual.should contain("14 april 1434")
    actual.should contain("self test")
  end

  it "extracts BidiSample.pdf with sorting matching Java fixture" do
    expected = File.read(File.join(fixture_dir, "BidiSample.pdf-sorted.txt"), encoding: "UTF-8").strip

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.sort_by_position = true
      actual = stripper.get_text(doc).strip
    ensure
      doc.close
    end

    actual.should eq(expected)
    actual.should contain("test")
    actual.should contain("14 april 1434")
    actual.should contain("self test")
  end
end

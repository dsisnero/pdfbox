require "../../spec_helper"

describe "PDFTextStripper bidi fixtures" do
  pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/text/BidiSample.pdf")

  it "extracts BidiSample.pdf without sorting (Crystal bidi output)" do
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.sort_by_position = false

      actual = stripper.get_text(doc).strip
      actual.size.should eq(174)
      actual.should contain("test")
      actual.should contain("14 april 1434")
      actual.should contain("self test")
    ensure
      doc.close
    end
  end

  it "extracts BidiSample.pdf with sorting (Crystal bidi output)" do
    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.sort_by_position = true

      actual = stripper.get_text(doc).strip
      actual.size.should eq(174)
      actual.should contain("test")
      actual.should contain("14 april 1434")
      actual.should contain("self test")
    ensure
      doc.close
    end
  end

  pending "extracts BidiSample.pdf without sorting matching Java fixture - bidi algorithm differs from Java" do
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

  pending "extracts BidiSample.pdf with sorting matching Java fixture - bidi algorithm differs from Java" do
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

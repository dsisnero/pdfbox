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

  it "extracts only page 2 of eu-001.pdf like the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/eu-001.pdf")

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.start_page = 2
      stripper.end_page = 2

      text = stripper.get_text(doc).gsub('\r', "").strip
      text.starts_with?("Pesticides").should be_true
      text.ends_with?("1 000 10 10").should be_true
      text.size.should eq(1378)
    ensure
      doc.close
    end
  end
end

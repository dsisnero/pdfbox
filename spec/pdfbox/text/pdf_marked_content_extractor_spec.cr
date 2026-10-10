require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/text/PDFMarkedContentExtractor.java
# (exercised by PDFMergerUtilityTest#checkWithNumberTree).
describe Pdfbox::Text::PDFMarkedContentExtractor do
  it "extracts nested marked-content sequences and their MCIDs" do
    path = SpecPaths.resolve("spec/resources/pdfbox/multipdf/PDFBOX-4408.pdf").to_s
    doc = Pdfbox::Loader.load_pdf(path)
    begin
      extractor = Pdfbox::Text::PDFMarkedContentExtractor.new
      extractor.process_page(doc.get_page(0))
      contents = extractor.get_marked_contents
      contents.should_not be_empty

      mcids = [] of Int32
      stack = contents.dup
      until stack.empty?
        marked_content = stack.pop
        mcids << marked_content.mcid if marked_content.mcid >= 0
        stack.concat(marked_content.marked_contents)
      end

      mcids.should_not be_empty
      mcids.each { |mcid| mcid.should be >= 0 }
    ensure
      doc.close
    end
  end
end

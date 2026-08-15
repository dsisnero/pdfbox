require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PlainTextTest.java
describe Pdfbox::Pdmodel::Interactive::PlainText do
  it "PlainTextTest#characterCR" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("CR\rCR")
    text.paragraphs.size.should eq(2)
  end

  it "PlainTextTest#characterLF" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("LF\nLF")
    text.paragraphs.size.should eq(2)
  end

  it "PlainTextTest#characterCRLF" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("CRLF\r\nCRLF")
    text.paragraphs.size.should eq(2)
  end

  it "PlainTextTest#characterLFCR" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("LFCR\n\rLFCR")
    text.paragraphs.size.should eq(3)
  end

  it "PlainTextTest#characterUnicodeLinebreak" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("linebreak\u2028linebreak")
    text.paragraphs.size.should eq(2)
  end

  it "PlainTextTest#characterUnicodeParagraphbreak" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("paragraphbreak\u2029paragraphbreak")
    text.paragraphs.size.should eq(2)
  end
end

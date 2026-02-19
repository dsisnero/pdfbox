require "../spec_helper"

describe "Porting parity pdfbox-uyy" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PlainTextTest.java
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/PlainText.java
  it "splits CR into two paragraphs" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("CR\rCR")
    text.paragraphs.size.should eq(2)
  end

  it "splits LF into two paragraphs" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("LF\nLF")
    text.paragraphs.size.should eq(2)
  end

  it "splits CRLF into two paragraphs" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("CRLF\r\nCRLF")
    text.paragraphs.size.should eq(2)
  end

  it "splits LFCR into three paragraphs" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("LFCR\n\rLFCR")
    text.paragraphs.size.should eq(3)
  end

  it "splits Unicode line separator into two paragraphs" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("linebreak\u2028linebreak")
    text.paragraphs.size.should eq(2)
  end

  it "splits Unicode paragraph separator into two paragraphs" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("paragraphbreak\u2029paragraphbreak")
    text.paragraphs.size.should eq(2)
  end
end

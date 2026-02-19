require "../../spec_helper"

describe "Pdfbox::Pdfwriter parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdfwriter/
  #
  # Blocked by unported writer stack (COSWriter, ContentStreamWriter, compression pools/document compression parity).

  it "COSDocumentCompressionTest#testCompressAcroformDoc" do
  end

  it "COSDocumentCompressionTest#testCompressAttachmentsDoc" do
  end

  it "COSDocumentCompressionTest#testCompressEncryptedDoc" do
  end

  it "COSDocumentCompressionTest#testAlteredDoc" do
  end

  it "COSDocumentCompressionTest#testPDFBox5927" do
  end

  it "COSWriterCompressionPoolTest#testPDFBox6036" do
  end

  it "COSWriterTest#testPDFBox4321" do
  end

  it "COSWriterTest#testPDFBox5485" do
  end

  it "COSWriterTest#testPDFBox5945" do
  end

  it "COSWriterTest#testPDFBox6036" do
  end

  it "ContentStreamWriterTest#testPDFBox4750" do
  end
end

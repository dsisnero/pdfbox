require "../../spec_helper"

describe "Pdfbox::Pdfwriter parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdfwriter/
  #
  # Blocked by unported writer stack (COSWriter, ContentStreamWriter, compression pools/document compression parity).

  pending "COSDocumentCompressionTest#testCompressAcroformDoc" do
  end

  pending "COSDocumentCompressionTest#testCompressAttachmentsDoc" do
  end

  pending "COSDocumentCompressionTest#testCompressEncryptedDoc" do
  end

  pending "COSDocumentCompressionTest#testAlteredDoc" do
  end

  pending "COSDocumentCompressionTest#testPDFBox5927" do
  end

  pending "COSWriterCompressionPoolTest#testPDFBox6036" do
  end

  pending "COSWriterTest#testPDFBox4321" do
  end

  pending "COSWriterTest#testPDFBox5485" do
  end

  pending "COSWriterTest#testPDFBox5945" do
  end

  pending "COSWriterTest#testPDFBox6036" do
  end

  pending "ContentStreamWriterTest#testPDFBox4750" do
  end
end

require "../../spec_helper"

describe "Pdfbox::Pdfwriter parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdfwriter/
  #
  # Progress:
  # - ContentStreamWriter token roundtrip parity is covered below.
  # - Compression/document writer parity tests are still pending broader writer stack work.

  pending "COSDocumentCompressionTest#testCompressAcroformDoc requires document compression writer parity" do
  end

  pending "COSDocumentCompressionTest#testCompressAttachmentsDoc requires document compression writer parity" do
  end

  pending "COSDocumentCompressionTest#testCompressEncryptedDoc requires encryption + compression writer parity" do
  end

  pending "COSDocumentCompressionTest#testAlteredDoc requires document compression writer parity" do
  end

  pending "COSDocumentCompressionTest#testPDFBox5927 requires document compression writer parity" do
  end

  pending "COSWriterCompressionPoolTest#testPDFBox6036 requires COS writer compression pool parity" do
  end

  pending "COSWriterTest#testPDFBox4321 requires COS writer object graph parity" do
  end

  pending "COSWriterTest#testPDFBox5485 requires COS writer object graph parity" do
  end

  pending "COSWriterTest#testPDFBox5945 requires COS writer object graph parity" do
  end

  pending "COSWriterTest#testPDFBox6036 requires COS writer object graph parity" do
  end

  it "ContentStreamWriterTest#testPDFBox4750" do
    source = <<-PDF
    q
    BI
    /W 1
    /H 1
    /BPC 8
    /CS /RGB
    ID
    12EI5
    EI
    Q
    PDF

    parser = Pdfbox::Pdfparser::PDFStreamParser.new(source)
    tokens = parser.parse

    written = IO::Memory.new
    writer = Pdfbox::Pdfwriter::ContentStreamWriter.new(written)
    writer.write_tokens(tokens)

    reparsed = Pdfbox::Pdfparser::PDFStreamParser.new(written.to_slice).parse

    # Round-tripped stream must preserve operator sequence and inline image payload.
    tokens.size.should eq(reparsed.size)
    tokens[0].as(Pdfbox::ContentStream::Operator).name.should eq("q")
    reparsed[0].as(Pdfbox::ContentStream::Operator).name.should eq("q")
    tokens[1].as(Pdfbox::ContentStream::Operator).name.should eq("BI")
    reparsed[1].as(Pdfbox::ContentStream::Operator).name.should eq("BI")
    tokens[2].as(Pdfbox::ContentStream::Operator).name.should eq("Q")
    reparsed[2].as(Pdfbox::ContentStream::Operator).name.should eq("Q")

    original_inline = tokens[1].as(Pdfbox::ContentStream::Operator)
    reparsed_inline = reparsed[1].as(Pdfbox::ContentStream::Operator)
    original_inline.image_data.should_not be_nil
    reparsed_inline.image_data.should_not be_nil
    original_data = original_inline.image_data.not_nil!
    reparsed_data = reparsed_inline.image_data.not_nil!

    trimmed_size = ->(bytes : Bytes) do
      size = bytes.size
      while size > 0 && bytes[size - 1] == '\n'.ord.to_u8
        size -= 1
      end
      size
    end

    original_data[0, trimmed_size.call(original_data)].should eq(reparsed_data[0, trimmed_size.call(reparsed_data)])
    original_data[0, 5].should eq("12EI5".to_slice)
    original_inline.image_parameters.not_nil!.size.should eq(reparsed_inline.image_parameters.not_nil!.size)
  end
end

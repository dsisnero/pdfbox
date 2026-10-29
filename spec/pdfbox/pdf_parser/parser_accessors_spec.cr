require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/PDFParser.java
#     and org/apache/pdfbox/pdfparser/COSParser.java: the parsed header version is
#     kept on the COSDocument (`getVersion`), the catalog is reachable through the
#     trailer `/Root`, the information dictionary through the trailer `/Info`, and
#     `COSDocument#isEncrypted` is "the trailer has /Encrypt".
#
# These accessors on `Pdfbox::Pdfparser::Parser` were TODO stubs returning
# `false`, `"1.4"` and `nil` for every input.
private def parser_bytes(encrypted : Bool = false) : Bytes
  output = IO::Memory.new
  document = Pdfbox::Pdmodel::Document.create
  document.header_version = "1.7"
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(100.0, 100.0)
  document.add_page(page)
  information = Pdfbox::Pdmodel::DocumentInformation.new
  information.title = "Parser Title"
  document.set_document_information(information)
  if encrypted
    policy = Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy.new(
      "owner", "user", Pdfbox::Pdmodel::Encryption::AccessPermission.new
    )
    policy.encryption_key_length = 128
    policy.prefer_aes = true
    document.protect(policy)
  end
  document.save(output, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
  document.close
  output.to_slice
end

private def parser_for(bytes : Bytes, password : String = "") : Pdfbox::Pdfparser::Parser
  Pdfbox::Pdfparser::Parser.new(Pdfbox::IO::RandomAccessReadBuffer.new(bytes), password)
end

describe Pdfbox::Pdfparser::Parser do
  it "exposes the parsed version, catalog and information dictionary" do
    parser = parser_for(parser_bytes)
    document = parser.parse
    begin
      parser.version.should eq("1.7")
      parser.catalog.should_not be_nil
      parser.catalog.not_nil!.get_name_as_string(Pdfbox::Cos::Name.new("Type")).should eq("Catalog")

      information = parser.document_information
      information.should_not be_nil
      information.not_nil!.get_string(Pdfbox::Cos::Name.new("Title")).should eq("Parser Title")

      parser.encrypted?.should be_false
      parser.trailer.should_not be_nil
    ensure
      document.close
    end
  end

  it "reports an encrypted document" do
    parser = parser_for(parser_bytes(encrypted: true), "user")
    document = parser.parse("user")
    begin
      parser.encrypted?.should be_true
      parser.version.should eq("1.7")
      parser.catalog.should_not be_nil
    ensure
      document.close
    end
  end
end

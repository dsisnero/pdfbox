require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/COSWriter.java
#     incremental constructor: `willEncrypt` stays true for a document with an
#     encryption dictionary (`prepareDocumentForEncryption`), so the strings and
#     streams written into the appended revision are encrypted with the object
#     key like a full save; `doWriteXRefInc` writes the trailer (or the xref
#     stream dictionary) from the document trailer, which includes `/Encrypt`.
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocument.java
#     saveIncremental() only rejects a document without source bytes, not an
#     encrypted one.
#
# Upstream covers re-signing/re-saving encrypted files only through the
# `TestCreateSignature` parameterized tests (which need a JKS keystore and CMS);
# these examples pin the byte-level contract instead: the source stays the
# prefix (so no full rewrite), the new revision repeats `/Encrypt`, and the
# rewritten strings are encrypted.
private def encrypted_incremental_policy : Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy
  policy = Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy.new(
    "owner", "user", Pdfbox::Pdmodel::Encryption::AccessPermission.new
  )
  policy.encryption_key_length = 128
  policy.prefer_aes = true
  policy
end

# Saves an encrypted document and returns its bytes plus the user password.
private def encrypted_incremental_source(compress : Bool) : Bytes
  output = IO::Memory.new
  document = Pdfbox::Pdmodel::Document.create
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(200.0, 200.0)
  document.add_page(page)
  information = Pdfbox::Pdmodel::DocumentInformation.new
  information.title = "Original Title"
  document.set_document_information(information)
  document.protect(encrypted_incremental_policy)
  if compress
    document.save(output)
  else
    document.save(output, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
  end
  document.close
  output.to_slice
end

describe "encrypted incremental save" do
  it "appends an encrypted revision to a classic-table file" do
    source = encrypted_incremental_source(compress: false)
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(source, "user")
    begin
      document.encrypted?.should be_true
      document.get_page(0).media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(42.0, 42.0)
      document.document_information.not_nil!.title = "Incremental Secret Title"
      document.save_incremental(output)
    ensure
      document.close
    end

    updated = output.to_slice
    # not a full rewrite: the encrypted source stays the prefix
    updated[0, source.size].should eq(source)
    appended = String.new(updated[source.size..])
    appended.should contain("/Encrypt")
    # strings written into the revision are encrypted, like a full save
    appended.should_not contain("Incremental Secret Title")

    reloaded = Pdfbox::Loader.load_pdf(updated, "user")
    begin
      reloaded.encrypted?.should be_true
      reloaded.number_of_pages.should eq(1)
      reloaded.get_page(0).media_box.not_nil!.width.should eq(42.0)
      reloaded.document_information.not_nil!.title.should eq("Incremental Secret Title")
    ensure
      reloaded.close
    end
  end

  it "appends an encrypted revision to an xref-stream file" do
    source = encrypted_incremental_source(compress: true)
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(source, "user")
    begin
      document.get_page(0).media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(24.0, 24.0)
      document.save_incremental(output)
    ensure
      document.close
    end

    updated = output.to_slice
    updated[0, source.size].should eq(source)
    # the new cross-reference stream repeats /Encrypt in its dictionary and is
    # itself written unencrypted (PDF 32000-1 7.5.8.2)
    appended = String.new(updated[source.size..])
    appended.should contain("/Type /XRef")
    appended.should contain("/Encrypt")

    reloaded = Pdfbox::Loader.load_pdf(updated, "user")
    begin
      reloaded.get_page(0).media_box.not_nil!.width.should eq(24.0)
    ensure
      reloaded.close
    end
  end
end

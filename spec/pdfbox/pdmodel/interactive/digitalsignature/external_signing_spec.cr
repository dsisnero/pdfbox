require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocument.java
#     addSignature(PDSignature, SignatureInterface, SignatureOptions),
#     saveIncrementalForExternalSigning(OutputStream), RESERVE_BYTE_RANGE,
#     prepareNonVisibleSignature / checkSignatureField / checkSignatureAnnotation.
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/COSWriter.java
#     incremental constructor (writes the increment into a buffer, the standard
#     output is positioned at the source length), doWriteSignature,
#     getDataToSign, writeExternalSignature.
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/
#     digitalsignature/ExternalSigningSupport.java and SigningSupport.java.
#   vendor/pdfbox/examples/src/test/java/org/apache/pdfbox/examples/pdmodel/
#     TestCreateSignature.java#testPDFBox3811, which is the one upstream test for
#     external signing that needs no CMS/keystore: it only compares the digest of
#     the data to sign across repeated calls.
#
# The CMS signature itself (BouncyCastle / JCA) is out of scope, so the
# signature bytes here are arbitrary: the assertions pin the byte accounting
# that makes a real signature verifiable — /ByteRange must cover the whole file
# except the /Contents hex string, and the data handed to the signer must be
# exactly those ranges of the final file.
private def external_signing_reserve
  [0, 1_000_000_000, 1_000_000_000, 1_000_000_000]
end

# A document saved to bytes, so that it can be loaded and incrementally signed.
private def external_signing_source : Bytes
  output = IO::Memory.new
  document = Pdfbox::Pdmodel::Document.create
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(200.0, 200.0)
  document.add_page(page)
  document.save(output, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
  document.close
  output.to_slice
end

private def external_signing_signature : Pdfbox::Pdmodel::Interactive::Form::PDSignature
  signature = Pdfbox::Pdmodel::Interactive::Form::PDSignature.new
  signature.filter = Pdfbox::Pdmodel::Interactive::Form::PDSignature::FILTER_ADOBE_PPKLITE
  signature.sub_filter = Pdfbox::Pdmodel::Interactive::Form::PDSignature::SUBFILTER_ADBE_PKCS7_DETACHED
  signature
end

private def external_signing_digest(bytes : Bytes) : String
  Digest::SHA256.hexdigest(bytes)
end

# Builds a visual-signature template with PDFTemplateCreator (the document model
# PDVisibleSigProperties/PDVisibleSignDesigner/PDFTemplateCreator cluster) and
# returns its PDF bytes, for SignatureOptions#set_visual_signature.
private def external_signing_visual_template : Bytes
  image = CrImage::RGBA.new(CrImage.rect(0, 0, 100, 50))
  page_document = Pdfbox::Pdmodel::Document.create
  template_page = Pdfbox::Pdmodel::Page.new
  template_page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(612.0, 792.0)
  page_document.add_page(template_page)
  designer = Pdfbox::Pdmodel::Interactive::DigitalSignature::Visible::PDVisibleSignDesigner.new(
    page_document, image, 1
  )
  properties = Pdfbox::Pdmodel::Interactive::DigitalSignature::Visible::PDVisibleSigProperties.new
  properties.visual_sign_enabled(true).page(1).set_pd_visible_signature(designer)
  properties.build_signature
  page_document.close
  properties.visible_signature.not_nil!
end

describe "external signing" do
  # TestCreateSignature#testPDFBox3811: calling saveIncrementalForExternalSigning()
  # more than once brings the same result (the second call must fail because the
  # reserved byte range was overwritten, and succeed again once it is restored).
  it "produces the same data to sign for repeated calls (PDFBOX-3811)" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      # for a stable digest, like Java's PDDocument#setDocumentId(long)
      document.set_document_id(12_345_i64)
      signature = external_signing_signature
      document.add_signature(signature)
      reserve_byte_range = signature.byte_range

      first = document.save_incremental_for_external_signing(IO::Memory.new)
      digest = external_signing_digest(first.content)

      expect_raises(Pdfbox::Pdmodel::IllegalStateError) do
        document.save_incremental_for_external_signing(IO::Memory.new)
      end

      signature.byte_range = reserve_byte_range
      second = document.save_incremental_for_external_signing(IO::Memory.new)
      external_signing_digest(second.content).should eq(digest)
    ensure
      document.close
    end
  end

  # PDDocument#addSignature: reserves /Contents (preferred size or
  # SignatureOptions.DEFAULT_SIGNATURE_SIZE) and the /ByteRange placeholder, then
  # creates the signature field, its widget and the AcroForm wiring.
  it "reserves the signature contents and byte range" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      signature = external_signing_signature
      document.add_signature(signature)

      signature.byte_range.should eq(external_signing_reserve)
      signature.contents.size.should eq(
        Pdfbox::Pdmodel::Interactive::DigitalSignature::SignatureOptions::DEFAULT_SIGNATURE_SIZE
      )
    ensure
      document.close
    end
  end

  it "reserves the preferred signature size" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      options = Pdfbox::Pdmodel::Interactive::DigitalSignature::SignatureOptions.new
      options.preferred_signature_size = 1234
      signature = external_signing_signature
      document.add_signature(signature, options)

      signature.contents.size.should eq(1234)
    ensure
      document.close
    end
  end

  it "creates a signature field with a printed, invisible widget" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      signature = external_signing_signature
      document.add_signature(signature)

      fields = document.signature_fields
      fields.size.should eq(1)
      field = fields.first
      field.signature.not_nil!.cos_object.should be(signature.cos_object)

      widget = field.widgets.first
      widget.printed?.should be_true
      # an invisible signature has a zero-sized rectangle
      rectangle = widget.rectangle.not_nil!
      rectangle.width.should eq(0.0)
      rectangle.height.should eq(0.0)

      # ... but still needs an (empty) appearance stream
      appearance = widget.appearance.not_nil!
      normal = appearance.normal_appearance.not_nil!
      bbox_array = normal.cos_object.get_array(Pdfbox::Cos::Name.new("BBox"))
      bbox_array.should_not be_nil
      bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(bbox_array.not_nil!)
      bbox.width.should eq(0.0)
      bbox.height.should eq(0.0)

      acro_form = document.document_catalog.not_nil!.acro_form(nil).not_nil!
      acro_form.signatures_exist?.should be_true
      acro_form.append_only?.should be_true
      acro_form.fields.map(&.cos_object.object_id).should contain(field.cos_object.object_id)
    ensure
      document.close
    end
  end

  it "rejects a second signature on the same document" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      document.add_signature(external_signing_signature)
      expect_raises(Pdfbox::Pdmodel::IllegalStateError, /Only one signature may be added in a document/) do
        document.add_signature(external_signing_signature)
      end
    ensure
      document.close
    end
  end

  it "rejects external signing when the document has no signature field" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      expect_raises(Pdfbox::Pdmodel::IllegalStateError, /document does not contain signature fields/) do
        document.save_incremental_for_external_signing(IO::Memory.new)
      end
    ensure
      document.close
    end
  end

  it "rejects external signing when the reserved byte range was changed" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      signature = external_signing_signature
      document.add_signature(signature)
      signature.byte_range = [0, 10, 20, 30]

      expect_raises(Pdfbox::Pdmodel::IllegalStateError, /signature reserve byte range has been changed/) do
        document.save_incremental_for_external_signing(IO::Memory.new)
      end
    ensure
      document.close
    end
  end

  # The defining property of the byte accounting: the data handed to the signer
  # is the final file with the /Contents hex string cut out, and /ByteRange says
  # exactly where it was cut.
  it "signs every byte except the signature contents" do
    source = external_signing_source
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(source)
    begin
      signature = external_signing_signature
      document.add_signature(signature)
      support = document.save_incremental_for_external_signing(output)
      content = support.content
      byte_range = signature.byte_range

      byte_range[0].should eq(0)
      content.size.should eq(byte_range[1] + byte_range[3])
      # the source bytes are the prefix of the signed data
      content[0, source.size].should eq(source)

      cms = Bytes.new(64) { |index| ((index * 7 + 3) % 256).to_u8 }
      support.set_signature(cms)

      signed = output.to_slice
      signed[0, source.size].should eq(source)

      # A verifier recomputes the signed data from the final file.
      signed[0, byte_range[1]].to_slice.should eq(content[0, byte_range[1]])
      after = signed[byte_range[2], byte_range[3]]
      after.should eq(content[byte_range[1], byte_range[3]])

      reloaded = Pdfbox::Loader.load_pdf(signed)
      begin
        dictionaries = reloaded.signature_dictionaries
        dictionaries.size.should eq(1)
        reloaded_dictionary = dictionaries.first
        reloaded_dictionary.byte_range.should eq(byte_range)
        contents = reloaded_dictionary.contents
        contents[0, cms.size].should eq(cms)
        contents.size.should eq(
          Pdfbox::Pdmodel::Interactive::DigitalSignature::SignatureOptions::DEFAULT_SIGNATURE_SIZE
        )
        reloaded.last_signature_dictionary.not_nil!.contents[0, cms.size].should eq(cms)
      ensure
        reloaded.close
      end
    ensure
      document.close
    end
  end

  it "rejects a signature that does not fit the reserved contents" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      options = Pdfbox::Pdmodel::Interactive::DigitalSignature::SignatureOptions.new
      options.preferred_signature_size = 32
      document.add_signature(external_signing_signature, options)
      support = document.save_incremental_for_external_signing(IO::Memory.new)

      expect_raises(::IO::Error, /Can't write signature, not enough space/) do
        # 33 bytes of CMS become 66 hex digits, two more than the 32-byte reserve.
        support.set_signature(Bytes.new(33))
      end
    ensure
      document.close
    end
  end

  it "keeps the earlier revisions loadable after signing" do
    source = external_signing_source
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(source)
    begin
      document.add_signature(external_signing_signature)
      support = document.save_incremental_for_external_signing(output)
      support.set_signature(Bytes.new(16) { |index| index.to_u8 })
    ensure
      document.close
    end

    signed = output.to_slice
    # the appended revision is one more revision, not a rewrite
    Pdfbox::Loader.load_pdf(signed[0, source.size]).close
    reloaded = Pdfbox::Loader.load_pdf(signed)
    begin
      reloaded.number_of_pages.should eq(1)
    ensure
      reloaded.close
    end
  end

  # Java PDDocument#prepareVisibleSignature: the widget's /Rect, the appearance
  # dictionary and the AcroForm default resources come from the visual-signature
  # template built by PDFTemplateCreator.
  it "takes the rectangle, appearance and default resources from the visual signature" do
    template = external_signing_visual_template
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      options = Pdfbox::Pdmodel::Interactive::DigitalSignature::SignatureOptions.new
      options.set_visual_signature(template)
      document.add_signature(external_signing_signature, options)

      field = document.signature_fields.first
      widget = field.widgets.first

      rectangle = widget.rectangle.not_nil!
      rectangle.width.should eq(100.0)
      rectangle.height.should eq(50.0)
      rectangle.upper_right_y.should eq(792.0)

      appearance = widget.appearance.not_nil!
      holder = appearance.normal_appearance.not_nil!.cos_object
      holder_stream = holder.as(Pdfbox::Cos::Stream)
      holder_stream.create_input_stream.gets_to_end.should eq("q 1 0 0 1 0 0 cm /FRM Do Q\n")

      acro_form = document.document_catalog.not_nil!.acro_form(nil).not_nil!
      default_resources = acro_form.default_resources
      default_resources.should_not be_nil
      xobjects = default_resources.not_nil!.cos_object.get_dictionary(Pdfbox::Cos::Name.new("XObject"))
      xobjects.should_not be_nil
      xobjects.not_nil!.entries.keys.map(&.value).should eq(["FRM"])
    ensure
      document.close
    end
  end

  it "rejects a visual signature template that has no signature field" do
    document = Pdfbox::Loader.load_pdf(external_signing_source)
    begin
      options = Pdfbox::Pdmodel::Interactive::DigitalSignature::SignatureOptions.new
      # the plain source document has neither a signature field nor a widget
      options.set_visual_signature(external_signing_source)
      expect_raises(ArgumentError, /Template is missing required objects/) do
        document.add_signature(external_signing_signature, options)
      end
    ensure
      document.close
    end
  end
end

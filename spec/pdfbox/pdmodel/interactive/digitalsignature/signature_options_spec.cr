require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/SignatureOptions.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior (the visible-signature properties
# overload is out of scope until the PDVisibleSig* cluster is ported).
module Pdfbox::Pdmodel::Interactive::DigitalSignature
  describe SignatureOptions do
    it "has the documented defaults" do
      options = SignatureOptions.new
      options.page.should eq(0)
      options.preferred_signature_size.should eq(0)
      options.visual_signature.should be_nil
      SignatureOptions::DEFAULT_SIGNATURE_SIZE.should eq(0x2500)
    end

    it "considers only positive preferred signature sizes" do
      options = SignatureOptions.new
      options.preferred_signature_size = 100
      options.preferred_signature_size.should eq(100)
      options.preferred_signature_size = 0
      options.preferred_signature_size.should eq(100)
      options.preferred_signature_size = -1
      options.preferred_signature_size.should eq(100)
    end

    it "loads a visual signature document from bytes" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.add_page(Pdfbox::Pdmodel::Page.new)
      io = ::IO::Memory.new
      doc.save(io)
      doc.close

      options = SignatureOptions.new
      options.set_visual_signature(io.to_slice)
      options.visual_signature.should_not be_nil
      options.visual_signature.not_nil!.number_of_pages.should eq(1)
      options.close
    end
  end
end

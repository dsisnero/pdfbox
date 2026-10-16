require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFCatalog.java
#     getSignature (/Sig as PDSignature) and setSignature. Upstream has no
#     dedicated test; this is a characterization spec.
module Pdfbox::Pdmodel::Fdf
  describe FDFCatalog do
    it "reads and writes the /Sig signature" do
      catalog = FDFCatalog.new
      catalog.signature.should be_nil

      signature = Pdfbox::Pdmodel::Interactive::Form::PDSignature.new
      signature.name = "Signature1"
      catalog.signature = signature

      catalog.signature.not_nil!.cos_object.should be(signature.cos_object)
      catalog.cos_object.get_dictionary(Pdfbox::Cos::Name.new("Sig")).should be(signature.cos_object)
    end
  end
end

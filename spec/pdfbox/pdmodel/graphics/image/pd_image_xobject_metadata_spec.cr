require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/image/PDImageXObject.java
#
# Characterization spec: upstream has no dedicated test for the metadata accessor,
# so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Image
  describe PDImageXObject do
    it "round-trips the metadata stream (/Metadata)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        stream = Pdfbox::Cos::Stream.new
        stream.data = "pixels".to_slice
        image = PDImageXObject.new(document, stream, stream)
        image.metadata.should be_nil

        meta_stream = Pdfbox::Cos::Stream.new
        meta = Pdfbox::Pdmodel::Common::PDMetadata.new(meta_stream)
        image.metadata = meta
        image.metadata.not_nil!.cos_object.should be(meta_stream)
        stream.get_dictionary_object(Pdfbox::Cos::Name.new("Metadata")).should be(meta_stream)

        image.metadata = nil
        image.metadata.should be_nil
      ensure
        document.close
      end
    end
  end
end

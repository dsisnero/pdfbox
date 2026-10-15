require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/image/PDImageXObject.java
#     createThumbnail(COSStream): wraps the stream as an image XObject without
#     requiring a document.
module Pdfbox::Pdmodel::Graphics::Image
  describe PDImageXObject do
    it "wraps a thumbnail stream without a document (Java createThumbnail)" do
      stream = Cos::Stream.new
      stream.set_name(Cos::Name.new("Subtype"), "Image")

      image = PDImageXObject.create_thumbnail(stream)
      image.cos_object.should be(stream)
      # The subtype is preserved and no document is required.
      stream.get_name_as_string(Cos::Name.new("Subtype")).should eq("Image")
    end
  end
end

require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSStream.java
#     createView() (RandomAccessRead over the decoded stream data) and
#   vendor/pdfbox/pdfbox/.../graphics/form/PDFormXObject.java
#     getContentsForRandomAccess(). Upstream has no dedicated test; this is a
#     characterization spec.
module Pdfbox
  module Cos
    describe Stream do
      it "create_view returns a random access read over the decoded stream data" do
        encoded = Pdfbox::Filter::FlateFilter.new.encode("hello world".to_slice)

        stream = Stream.new
        stream[Name::FILTER] = Name.new("FlateDecode")
        stream.data = encoded

        stream.create_view.read_all.should eq("hello world".to_slice)
      end

      it "create_view returns an empty read when there is no data" do
        Stream.new.create_view.length.should eq(0)
      end
    end
  end
end

module Pdfbox::Pdmodel::Graphics::Form
  describe PDFormXObject do
    it "contents_for_random_access returns a random access read over the decoded contents" do
      stream = Pdfbox::Cos::Stream.new
      stream.data = "BT ET".to_slice

      form = PDFormXObject.new(stream)
      form.contents_for_random_access.read_all.should eq("BT ET".to_slice)
    end
  end
end

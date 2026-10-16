require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/pattern/PDTilingPattern.java
#     getContents (decoded contents stream) and getContentsForRandomAccess.
# Upstream has no dedicated test; this is a characterization spec.
module Pdfbox::Pdmodel::Graphics::Pattern
  describe PDTilingPattern do
    it "exposes the decoded contents as an IO and as a random access read" do
      stream = Pdfbox::Cos::Stream.new(data: "q Q".to_slice)
      pattern = PDTilingPattern.new(stream)

      pattern.contents.gets_to_end.should eq("q Q")
      pattern.contents_for_random_access.read_all.should eq("q Q".to_slice)
    end
  end
end

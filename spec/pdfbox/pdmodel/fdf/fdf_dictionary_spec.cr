require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFDictionary.java
#     getDifferences (/Differences stream) and get/setEmbeddedFDFs (/EmbeddedFDFs
#     file specifications). Upstream has no dedicated test; this is a
#     characterization spec.
module Pdfbox::Pdmodel::Fdf
  describe FDFDictionary do
    it "reads and writes the /Differences stream" do
      fdf = FDFDictionary.new
      fdf.differences.should be_nil

      diff = Pdfbox::Cos::Stream.new(data: "diff".to_slice)
      fdf.differences = diff
      fdf.differences.should be(diff)
    end

    it "reads and writes the /EmbeddedFDFs file specifications" do
      fdf = FDFDictionary.new
      fdf.embedded_fdfs.should be_nil

      spec = Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(
        Pdfbox::Cos::String.new("/tmp/a.fdf")).not_nil!
      fdf.embedded_fdfs = [spec]

      loaded = fdf.embedded_fdfs.not_nil!
      loaded.size.should eq(1)
      loaded.first.cos_object.should eq(spec.cos_object)
    end
  end
end

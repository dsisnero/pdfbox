require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PDFRenderer.java
#     get/setDefaultDestination (null by default) and
#     get/setImageDownscalingOptimizationThreshold (0.5f default). Upstream has no
#     dedicated test; this is a characterization spec.
module Pdfbox::Rendering
  describe PDFRenderer do
    it "has no default destination until one is set (Java null default)" do
      renderer = PDFRenderer.new(Pdfbox::Pdmodel::Document.new)

      renderer.default_destination.should be_nil

      renderer.default_destination = RenderDestination::PRINT
      renderer.default_destination.should eq(RenderDestination::PRINT)
    end

    it "defaults the image downscaling optimization threshold to 0.5" do
      renderer = PDFRenderer.new(Pdfbox::Pdmodel::Document.new)

      renderer.image_downscaling_optimization_threshold.should eq(0.5_f32)

      renderer.image_downscaling_optimization_threshold = 0.25_f32
      renderer.image_downscaling_optimization_threshold.should eq(0.25_f32)
    end
  end
end

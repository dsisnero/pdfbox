require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceRGB.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceGray.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceCMYK.java
#
# Characterization spec: upstream has no dedicated test for getDefaultDecode, so
# these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Color
  describe "device color space default decode" do
    it "returns the Java default decode arrays" do
      PDDeviceGray::INSTANCE.default_decode(1).should eq([0.0_f32, 1.0_f32])
      PDDeviceRGB::INSTANCE.default_decode(8).should eq([0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32])
      PDDeviceCMYK::INSTANCE.default_decode(8)
        .should eq([0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32])

      # The bits-per-component argument is ignored, so the no-arg form still works.
      PDDeviceCMYK::INSTANCE.default_decode
        .should eq([0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32])
    end
  end
end

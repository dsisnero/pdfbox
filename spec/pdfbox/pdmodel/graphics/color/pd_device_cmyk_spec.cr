require "../../../../spec_helper"

module Pdfbox::Pdmodel::Graphics::Color
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceCMYKTest.java
  #
  # testCMYK: a power user can create a custom default CMYK color space by
  # subclassing PDDeviceCMYK and reassigning the INSTANCE singleton. Crystal
  # INSTANCE is a constant, so the port asserts that a custom subclass can be
  # instantiated and satisfies the PDDeviceCMYK contract (name/components/
  # default decode/initial color).
  #
  # testPDFBox5787: exercises java.awt AWT ICC profile + ColorConvertOp CMYK->RGB
  # machinery (jdk21 homebrew check). That path is AWT/ICC-specific and out of
  # scope for the Crystal port (advisory, Chunk K render policy). Likewise the
  # ICC-profile-backed toRGB/toRGBImage (PDDeviceCMYK.init loads
  # CGATS001Compat-v2-micro.icc via ICC_Profile) is not ported; the Crystal
  # to_rgb uses the standard subtractive CMYK->RGB formula.
  describe PDDeviceCMYK do
    it "testCMYK: a custom PDDeviceCMYK subclass can be instantiated" do
      custom = CustomDeviceCMYK.new
      custom.should be_a(PDDeviceCMYK)
    end

    it "testCMYK: the custom instance satisfies the DeviceCMYK contract" do
      custom = CustomDeviceCMYK.new
      custom.name.should eq("DeviceCMYK")
      custom.number_of_components.should eq(4)
      custom.default_decode.should eq([0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32])
      custom.initial_color.components.should eq([0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32])
    end

    it "matches the Java INSTANCE singleton contract" do
      PDDeviceCMYK::INSTANCE.should be_a(PDDeviceCMYK)
      PDDeviceCMYK::INSTANCE.name.should eq("DeviceCMYK")
      PDDeviceCMYK::INSTANCE.number_of_components.should eq(4)
      PDDeviceCMYK::INSTANCE.default_decode.should eq([0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32])
    end

    it "reports the COS name DeviceCMYK" do
      PDDeviceCMYK::INSTANCE.cos_object.should eq(Pdfbox::Cos::Name.new("DeviceCMYK"))
    end

    it "converts CMYK to RGB with the standard formula" do
      # C=1, M=0, Y=0, K=0 -> R=0, G=1, B=1
      result = PDDeviceCMYK::INSTANCE.to_rgb([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32])
      result.should eq([0.0_f32, 1.0_f32, 1.0_f32])
    end
  end

  private class CustomDeviceCMYK < PDDeviceCMYK
  end
end

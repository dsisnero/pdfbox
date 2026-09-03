require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/DecodeResult.java
#
# The result of a filter decode operation: carries the (possibly repaired)
# stream parameters and an optional embedded JPX color space. The soft-mask
# (BufferedImage) accessors are AWT/JPX-specific and documented as out of
# scope.

module Pdfbox::Filter
  describe DecodeResult do
    it "createDefault returns a result with an empty parameters dictionary" do
      result = DecodeResult.create_default
      result.parameters.should eq(Pdfbox::Cos::Dictionary.new)
    end

    it "holds the stream parameters" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("Predictor")] = Pdfbox::Cos::Integer.new(15)
      result = DecodeResult.new(dict)
      result.parameters.should eq(dict)
      result.parameters[Pdfbox::Cos::Name.new("Predictor")].should eq(Pdfbox::Cos::Integer.new(15))
    end

    it "holds an optional JPX color space" do
      # The JPX color space type is not ported; the slot is a PDColorSpace
      # placeholder so the decode-result surface matches Java's shape.
      color_space = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
      dict = Pdfbox::Cos::Dictionary.new
      result = DecodeResult.new(dict, color_space)
      result.jpx_color_space.should eq(color_space)
    end

    it "returns nil JPX color space when none was set" do
      result = DecodeResult.new(Pdfbox::Cos::Dictionary.new)
      result.jpx_color_space.should be_nil
    end
  end
end

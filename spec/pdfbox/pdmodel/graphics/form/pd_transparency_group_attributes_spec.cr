require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/form/PDTransparencyGroupAttributes.java
#     getColorSpace (null when /CS is absent), isIsolated (/I), isKnockout (/K).
module Pdfbox::Pdmodel::Graphics::Form
  describe PDTransparencyGroupAttributes do
    it "reads the group color space (Java getColorSpace)" do
      PDTransparencyGroupAttributes.new.color_space.should be_nil

      dict = Cos::Dictionary.new
      dict[Cos::Name.new("CS")] = Cos::Name.new("DeviceRGB")
      attrs = PDTransparencyGroupAttributes.new(dict)
      attrs.color_space.should_not be_nil
      attrs.color_space.not_nil!.name.should eq("DeviceRGB")
    end

    it "reports isolated and knockout (Java isIsolated/isKnockout)" do
      attrs = PDTransparencyGroupAttributes.new
      attrs.isolated?.should be_false
      attrs.knockout?.should be_false

      dict = Cos::Dictionary.new
      dict.set_boolean(Cos::Name.new("I"), true)
      dict.set_boolean(Cos::Name.new("K"), true)
      attrs = PDTransparencyGroupAttributes.new(dict)
      attrs.isolated?.should be_true
      attrs.knockout?.should be_true
    end
  end
end

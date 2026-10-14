require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/*.java (getDefaultDecode)
#
# Characterization spec: upstream has no dedicated test for getDefaultDecode, so
# these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Color
  describe "PDColorSpace#default_decode" do
    it "returns 0/1 per component for CalGray / CalRGB / Separation" do
      PDCalGray.new.default_decode(8).should eq([0.0_f32, 1.0_f32])
      PDCalRGB.new.default_decode(8).should eq([0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32])
      PDSeparation.new.default_decode(8).should eq([0.0_f32, 1.0_f32])
    end

    it "returns 0/1 per DeviceN colorant" do
      tint = Cos::Dictionary.new
      tint.set_int("FunctionType", 2)
      tint[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Integer.new(0), Cos::Integer.new(1)])
      tint[Cos::Name.new("C0")] = Cos::Array.new([Cos::Integer.new(0), Cos::Integer.new(0), Cos::Integer.new(0)])
      tint[Cos::Name.new("C1")] = Cos::Array.new([Cos::Integer.new(1), Cos::Integer.new(1), Cos::Integer.new(1)])
      tint.set_int("N", 1)

      array = Cos::Array.new
      array.add(Cos::Name.new("DeviceN"))
      array.add(Cos::Array.new([Cos::Name.new("Cyan"), Cos::Name.new("Magenta")]))
      array.add(Cos::Name.new("DeviceRGB"))
      array.add(tint)

      PDDeviceN.new(array).default_decode(8).should eq([0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32])
    end

    it "uses the Lab a/b ranges" do
      lab = PDLab.new
      lab.default_decode(8).should eq([0.0_f32, 100.0_f32, -100.0_f32, 100.0_f32, -100.0_f32, 100.0_f32])

      a = Common::PDRange.new
      a.min = -1.0
      a.max = 2.0
      lab.a_range = a
      lab.default_decode(8).should eq([0.0_f32, 100.0_f32, -1.0_f32, 2.0_f32, -100.0_f32, 100.0_f32])
    end

    it "returns the Indexed lookup maximum" do
      indexed = Cos::Array.new([
        Cos::Name.new("Indexed"),
        Cos::Name.new("DeviceRGB"),
        Cos::Integer.new(255),
        Cos::String.new(Bytes.new(256 * 3)),
      ])
      PDIndexed.new(indexed).default_decode(8).should eq([0.0_f32, 255.0_f32])
    end

    it "falls back to the alternate color space for ICCBased" do
      stream = Cos::Stream.new
      stream.set_int(Cos::Name.new("N"), 3)
      array = Cos::Array.new([Cos::Name.new("ICCBased"), stream])
      PDICCBased.new(array).default_decode(8).should eq([0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32])
    end

    it "raises for Pattern" do
      expect_raises(Cos::UnsupportedOperationError) { PDPattern.new.default_decode(8) }
    end
  end
end

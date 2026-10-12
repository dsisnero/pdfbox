require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDSeparation.java
#
# Characterization spec: upstream has no dedicated PDSeparation test, so these
# assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Color
  private def self.separation_array(range_size : Int32) : Cos::Array
    tint = Cos::Dictionary.new
    tint[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
    tint[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
    tint[Cos::Name.new("C0")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(0.0), Cos::Float.new(0.0)])
    tint[Cos::Name.new("C1")] = Cos::Array.new([Cos::Float.new(1.0), Cos::Float.new(1.0), Cos::Float.new(1.0)])
    tint[Cos::Name.new("N")] = Cos::Float.new(1.0)
    if range_size > 0
      range = Cos::Array.new
      (range_size // 2).times do
        range.add(Cos::Float.new(0.0))
        range.add(Cos::Float.new(1.0))
      end
      tint[Cos::Name.new("Range")] = range
    end

    array = Cos::Array.new
    array.add(Cos::Name.new("Separation"))
    array.add(Cos::Name.new("SpotColor"))
    array.add(Cos::Name.new("DeviceRGB"))
    array.add(tint)
    array
  end

  describe PDSeparation do
    it "is dispatched by PDColorSpace.create" do
      PDColorSpace.create(separation_array(6)).should be_a(PDSeparation)
    end

    it "reports name, components, colorant, and initial colour" do
      separation = PDSeparation.new
      separation.name.should eq("Separation")
      separation.number_of_components.should eq(1)

      separation = PDSeparation.new(separation_array(6))
      separation.colorant_name.should eq("SpotColor")
      separation.alternate_color_space.should be_a(PDDeviceRGB)
      separation.tint_transform.should_not be_nil
      separation.initial_color.components.should eq([1.0_f32])
    end

    it "converts through the tint transform and alternate colour space" do
      separation = PDSeparation.new(separation_array(6))
      separation.to_rgb([0.0_f32]).should eq([0.0_f32, 0.0_f32, 0.0_f32])
      separation.to_rgb([1.0_f32]).should eq([1.0_f32, 1.0_f32, 1.0_f32])
      separation.to_rgb([0.5_f32]).should eq([0.5_f32, 0.5_f32, 0.5_f32])
    end

    it "rejects a tint transform with fewer outputs than the alternate colour space" do
      # /Range with 2 outputs, but DeviceRGB has 3 components.
      expect_raises(::IO::Error) { PDSeparation.new(separation_array(4)) }
    end

    it "round-trips the alternate colour space and tint transform" do
      separation = PDSeparation.new
      separation.alternate_color_space = PDDeviceRGB::INSTANCE
      separation.alternate_color_space.should be_a(PDDeviceRGB)

      tint = Pdfbox::Pdmodel::Common::Function::PDFunction.create(
        (separation_array(6)[3]).as(Cos::Dictionary))
      separation.tint_transform = tint
      separation.tint_transform.should_not be_nil

      separation.colorant_name = "Black"
      separation.colorant_name.should eq("Black")
    end
  end
end

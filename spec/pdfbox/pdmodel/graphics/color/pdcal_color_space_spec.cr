require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDCalGray.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDCalRGB.java
#
# Characterization spec: upstream has no dedicated CalGray/CalRGB test, so these
# assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Color
  private def self.cal_array(space_name : String, with_whitepoint : Bool) : Cos::Array
    dict = Cos::Dictionary.new
    if with_whitepoint
      wp = Cos::Array.new([Cos::Float.new(0.9505), Cos::Float.new(1.0), Cos::Float.new(1.089)])
      dict[Cos::Name.new("WhitePoint")] = wp
    end
    array = Cos::Array.new
    array.add(Cos::Name.new(space_name))
    array.add(dict)
    array
  end

  describe PDCalGray do
    it "is dispatched by PDColorSpace.create" do
      PDColorSpace.create(cal_array("CalGray", true)).should be_a(PDCalGray)
    end

    it "reports name/components and defaults" do
      cal = PDCalGray.new
      cal.name.should eq("CalGray")
      cal.number_of_components.should eq(1)
      cal.gamma.should eq(1.0_f32)
    end

    it "skips CIE calibration when the whitepoint is not (1,1,1)" do
      cal = PDCalGray.new(cal_array("CalGray", true))
      cal.to_rgb([0.5_f32]).should eq([0.5_f32, 0.5_f32, 0.5_f32])
    end

    it "applies the gamma and XYZ conversion with the default whitepoint" do
      cal = PDCalGray.new(cal_array("CalGray", false))
      cal.to_rgb([0.0_f32]).should eq([0.0_f32, 0.0_f32, 0.0_f32])

      result = cal.to_rgb([1.0_f32])
      result.size.should eq(3)
      result[0].should be_close(1.0_f32, 0.01_f32)
      result[1].should be_close(0.977_f32, 0.01_f32)
      result[2].should be_close(0.959_f32, 0.01_f32)
    end
  end

  describe PDCalRGB do
    it "is dispatched by PDColorSpace.create" do
      PDColorSpace.create(cal_array("CalRGB", true)).should be_a(PDCalRGB)
    end

    it "reports name/components and defaults" do
      cal = PDCalRGB.new
      cal.name.should eq("CalRGB")
      cal.number_of_components.should eq(3)
      cal.gamma.r.should eq(1.0_f32)
      cal.gamma.g.should eq(1.0_f32)
      cal.gamma.b.should eq(1.0_f32)
      cal.matrix.should eq([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32])
    end

    it "skips CIE calibration when the whitepoint is not (1,1,1)" do
      cal = PDCalRGB.new(cal_array("CalRGB", true))
      cal.to_rgb([0.25_f32, 0.5_f32, 0.75_f32]).should eq([0.25_f32, 0.5_f32, 0.75_f32])
    end

    it "round-trips gamma and matrix" do
      cal = PDCalRGB.new

      gamma = PDGamma.new
      gamma.r = 2.0_f32
      gamma.g = 2.2_f32
      gamma.b = 1.8_f32
      cal.gamma = gamma
      cal.gamma.r.should eq(2.0_f32)
      cal.gamma.b.should eq(1.8_f32)

      cal.matrix = [2.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 2.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 2.0_f32]
      cal.matrix[0].should eq(2.0_f32)
      cal.matrix[4].should eq(2.0_f32)

      cal.gamma = nil
      cal.gamma.r.should eq(1.0_f32)
      cal.matrix = nil
      cal.matrix.should eq([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32])
    end
  end
end

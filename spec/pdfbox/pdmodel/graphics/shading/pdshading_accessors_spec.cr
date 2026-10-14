require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/shading/PDShading.java
#
# Characterization spec: upstream has no dedicated test for the PDShading base
# accessors, so these assertions are inferred from the Java observable behavior.
private def type2_function(c0 : Float64, c1 : Float64) : Pdfbox::Cos::Dictionary
  fn = Pdfbox::Cos::Dictionary.new
  fn.set_int("FunctionType", 2)
  fn[Pdfbox::Cos::Name.new("Domain")] = Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Integer.new(1)])
  fn[Pdfbox::Cos::Name.new("C0")] = Pdfbox::Cos::Array.new([Pdfbox::Cos::Float.new(c0), Pdfbox::Cos::Float.new(c0), Pdfbox::Cos::Float.new(c0)])
  fn[Pdfbox::Cos::Name.new("C1")] = Pdfbox::Cos::Array.new([Pdfbox::Cos::Float.new(c1), Pdfbox::Cos::Float.new(c1), Pdfbox::Cos::Float.new(c1)])
  fn.set_int("N", 1)
  fn
end

module Pdfbox::Pdmodel::Graphics::Shading
  describe PDShading do
    it "returns the shading type name (Java getType)" do
      PDShading.new(Cos::Dictionary.new).type.should eq("Shading")
    end

    it "round-trips shading type, anti-alias, background and bbox" do
      dict = Cos::Dictionary.new
      shading = PDShading.new(dict)

      shading.shading_type = 2
      dict.get_int(Cos::Name.new("ShadingType"), 0_i64).should eq(2)

      shading.anti_alias?.should be_false
      shading.anti_alias = true
      shading.anti_alias?.should be_true

      shading.background.should be_nil
      background = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(0.0), Cos::Float.new(0.0)])
      shading.background = background
      shading.background.should be(background)

      shading.bbox.should be_nil
      bbox = Common::PDRectangle.new(Cos::Array.new([
        Cos::Integer.new(0), Cos::Integer.new(0), Cos::Integer.new(100), Cos::Integer.new(100),
      ]))
      shading.bbox = bbox
      stored = shading.bbox.not_nil!
      stored.lower_left_x.should eq(0.0_f32)
      stored.lower_left_y.should eq(0.0_f32)
      stored.upper_right_x.should eq(100.0_f32)
      stored.upper_right_y.should eq(100.0_f32)
    end

    it "round-trips the color space" do
      dict = Cos::Dictionary.new
      shading = PDShading.new(dict)
      shading.color_space = Color::PDDeviceRGB::INSTANCE
      shading.color_space.should be_a(Color::PDDeviceRGB)

      shading.color_space = nil
      shading.color_space.should be_nil
    end

    it "evaluates a single function and clamps out-of-range output" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("Function")] = type2_function(0.0, 1.0)
      shading = PDShading.new(dict)
      shading.eval_function(0.5_f32).should eq([0.5_f32, 0.5_f32, 0.5_f32])

      clamped = Cos::Dictionary.new
      clamped[Cos::Name.new("Function")] = type2_function(-1.0, 2.0)
      PDShading.new(clamped).eval_function(1.0_f32).should eq([1.0_f32, 1.0_f32, 1.0_f32])
      PDShading.new(clamped).eval_function(0.0_f32).should eq([0.0_f32, 0.0_f32, 0.0_f32])
    end

    it "evaluates an array of functions (one output per function)" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("Function")] = Cos::Array.new([
        type2_function(0.0, 1.0),
        type2_function(1.0, 0.0),
      ])
      # one output value per function, each clamped to [0,1]
      PDShading.new(dict).eval_function(0.25_f32).should eq([0.25_f32, 0.75_f32])
    end

    it "sets an array of functions (Java setFunction(COSArray))" do
      dict = Cos::Dictionary.new
      shading = PDShading.new(dict)
      functions = Cos::Array.new([type2_function(0.0, 1.0)])
      shading.function = functions
      dict.get_dictionary_object(Cos::Name.new("Function")).should be(functions)
    end
  end
end

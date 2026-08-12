# Port of org.apache.pdfbox.pdmodel.graphics.blend.BlendModeTest
require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Graphics::Blend::BlendMode do
  it "checks that BlendMode constants are not nil and getInstance works" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    n = Pdfbox::Cos::Name

    bm.get_instance(n.new("Normal")).should eq(bm.normal)
    bm.get_instance(n.new("Compatible")).should eq(bm.normal)
    bm.get_instance(n.new("Multiply")).should eq(bm.multiply)
    bm.get_instance(n.new("Screen")).should eq(bm.screen)
    bm.get_instance(n.new("Overlay")).should eq(bm.overlay)
    bm.get_instance(n.new("Darken")).should eq(bm.darken)
    bm.get_instance(n.new("Lighten")).should eq(bm.lighten)
    bm.get_instance(n.new("ColorDodge")).should eq(bm.color_dodge)
    bm.get_instance(n.new("ColorBurn")).should eq(bm.color_burn)
    bm.get_instance(n.new("HardLight")).should eq(bm.hard_light)
    bm.get_instance(n.new("SoftLight")).should eq(bm.soft_light)
    bm.get_instance(n.new("Difference")).should eq(bm.difference)
    bm.get_instance(n.new("Exclusion")).should eq(bm.exclusion)
    bm.get_instance(n.new("Hue")).should eq(bm.hue)
    bm.get_instance(n.new("Saturation")).should eq(bm.saturation)
    bm.get_instance(n.new("Luminosity")).should eq(bm.luminosity)
    bm.get_instance(n.new("Color")).should eq(bm.color)

    array = Pdfbox::Cos::Array.new
    array.add(n.new("Overlay"))
    bm.get_instance(array).should eq(bm.overlay)

    array = Pdfbox::Cos::Array.new
    array.add(Pdfbox::Cos::Integer.get(0))
    bm.get_instance(array).should eq(bm.normal)
  end

  it "checks normal blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.normal.separable_blend_mode?.should be_true
    bm.normal.blend_function.should be_nil
    bm.normal.blend_channel_function.should_not be_nil
    bm.normal.cos_name.should eq(Pdfbox::Cos::Name.new("Normal"))
    bm.normal.blend_channel_function.not_nil!.call(3.0_f32, 5.0_f32).should eq(3.0_f32)

    bm.compatible.cos_name.should eq(Pdfbox::Cos::Name.new("Normal"))
  end

  it "checks multiply blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.multiply.separable_blend_mode?.should be_true
    bm.multiply.blend_function.should be_nil
    bm.multiply.blend_channel_function.should_not be_nil
    bm.multiply.cos_name.should eq(Pdfbox::Cos::Name.new("Multiply"))
    bm.multiply.blend_channel_function.not_nil!.call(3.0_f32, 5.0_f32).should eq(15.0_f32)
  end

  it "checks screen blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.screen.separable_blend_mode?.should be_true
    bm.screen.blend_function.should be_nil
    bm.screen.blend_channel_function.should_not be_nil
    bm.screen.cos_name.should eq(Pdfbox::Cos::Name.new("Screen"))
    bm.screen.blend_channel_function.not_nil!.call(3.0_f32, 5.0_f32).should eq(-7.0_f32)
  end

  it "checks overlay blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.overlay.separable_blend_mode?.should be_true
    bm.overlay.blend_function.should be_nil
    bm.overlay.blend_channel_function.should_not be_nil
    bm.overlay.cos_name.should eq(Pdfbox::Cos::Name.new("Overlay"))
    bm.overlay.blend_channel_function.not_nil!.call(1.0_f32, 0.0_f32).should eq(0.0_f32)
    bm.overlay.blend_channel_function.not_nil!.call(0.5_f32, 0.3_f32).should eq(0.3_f32)
  end

  it "checks darken blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.darken.separable_blend_mode?.should be_true
    bm.darken.blend_function.should be_nil
    bm.darken.blend_channel_function.should_not be_nil
    bm.darken.cos_name.should eq(Pdfbox::Cos::Name.new("Darken"))
    bm.darken.blend_channel_function.not_nil!.call(3.0_f32, 5.0_f32).should eq(3.0_f32)
  end

  it "checks lighten blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.lighten.separable_blend_mode?.should be_true
    bm.lighten.blend_function.should be_nil
    bm.lighten.blend_channel_function.should_not be_nil
    bm.lighten.cos_name.should eq(Pdfbox::Cos::Name.new("Lighten"))
    bm.lighten.blend_channel_function.not_nil!.call(3.0_f32, 5.0_f32).should eq(5.0_f32)
  end

  it "checks color dodge blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.color_dodge.separable_blend_mode?.should be_true
    bm.color_dodge.blend_function.should be_nil
    bm.color_dodge.blend_channel_function.should_not be_nil
    bm.color_dodge.cos_name.should eq(Pdfbox::Cos::Name.new("ColorDodge"))
    bm.color_dodge.blend_channel_function.not_nil!.call(1.0_f32, 0.0_f32).should eq(0.0_f32)
    bm.color_dodge.blend_channel_function.not_nil!.call(0.3_f32, 0.7_f32).should eq(1.0_f32)
  end

  it "checks color burn blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.color_burn.separable_blend_mode?.should be_true
    bm.color_burn.blend_function.should be_nil
    bm.color_burn.blend_channel_function.should_not be_nil
    bm.color_burn.cos_name.should eq(Pdfbox::Cos::Name.new("ColorBurn"))
    bm.color_burn.blend_channel_function.not_nil!.call(0.0_f32, 1.0_f32).should eq(1.0_f32)
    bm.color_burn.blend_channel_function.not_nil!.call(0.7_f32, 0.3_f32).should eq(0.0_f32)
  end

  it "checks hard light blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.hard_light.separable_blend_mode?.should be_true
    bm.hard_light.blend_function.should be_nil
    bm.hard_light.blend_channel_function.should_not be_nil
    bm.hard_light.cos_name.should eq(Pdfbox::Cos::Name.new("HardLight"))
    bm.hard_light.blend_channel_function.not_nil!.call(0.0_f32, 0.5_f32).should eq(0.0_f32)
    bm.hard_light.blend_channel_function.not_nil!.call(0.2_f32, 0.5_f32).should eq(0.2_f32)
    bm.hard_light.blend_channel_function.not_nil!.call(0.6_f32, 0.4_f32).should eq(0.52_f32)
  end

  it "checks soft light blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.soft_light.separable_blend_mode?.should be_true
    bm.soft_light.blend_function.should be_nil
    bm.soft_light.blend_channel_function.should_not be_nil
    bm.soft_light.cos_name.should eq(Pdfbox::Cos::Name.new("SoftLight"))
    bm.soft_light.blend_channel_function.not_nil!.call(0.0_f32, 0.5_f32).should eq(0.25_f32)
    bm.soft_light.blend_channel_function.not_nil!.call(0.2_f32, 0.5_f32).should eq(0.35_f32)
    bm.soft_light.blend_channel_function.not_nil!.call(0.5_f32, 0.2_f32).should eq(0.2_f32)
  end

  it "checks difference blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.difference.separable_blend_mode?.should be_true
    bm.difference.blend_function.should be_nil
    bm.difference.blend_channel_function.should_not be_nil
    bm.difference.cos_name.should eq(Pdfbox::Cos::Name.new("Difference"))
    bm.difference.blend_channel_function.not_nil!.call(3.0_f32, 5.0_f32).should eq(2.0_f32)
  end

  it "checks exclusion blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.exclusion.separable_blend_mode?.should be_true
    bm.exclusion.blend_function.should be_nil
    bm.exclusion.blend_channel_function.should_not be_nil
    bm.exclusion.cos_name.should eq(Pdfbox::Cos::Name.new("Exclusion"))
  end

  it "checks hue blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.hue.separable_blend_mode?.should be_false
    bm.hue.blend_function.should_not be_nil
    bm.hue.blend_channel_function.should be_nil
    bm.hue.cos_name.should eq(Pdfbox::Cos::Name.new("Hue"))
  end

  it "checks saturation blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.saturation.separable_blend_mode?.should be_false
    bm.saturation.blend_function.should_not be_nil
    bm.saturation.blend_channel_function.should be_nil
    bm.saturation.cos_name.should eq(Pdfbox::Cos::Name.new("Saturation"))
  end

  it "checks luminosity blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.luminosity.separable_blend_mode?.should be_false
    bm.luminosity.blend_function.should_not be_nil
    bm.luminosity.blend_channel_function.should be_nil
    bm.luminosity.cos_name.should eq(Pdfbox::Cos::Name.new("Luminosity"))
  end

  it "checks color blend mode" do
    bm = Pdfbox::Pdmodel::Graphics::Blend::BlendMode
    bm.color.separable_blend_mode?.should be_false
    bm.color.blend_function.should_not be_nil
    bm.color.blend_channel_function.should be_nil
    bm.color.cos_name.should eq(Pdfbox::Cos::Name.new("Color"))
  end
end

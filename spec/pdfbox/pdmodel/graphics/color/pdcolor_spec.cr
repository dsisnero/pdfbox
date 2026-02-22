require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Graphics::Color::PDColor do
  it "creates color from component values" do
    color_space = Pdfbox::Pdmodel::Graphics::Color::PDPattern.new
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.5_f32, 0.5_f32, 0.5_f32], color_space)
    color.components.should eq([0.5_f32, 0.5_f32, 0.5_f32])
    color.pattern?.should be_false
  end

  it "creates color from pattern name" do
    color_space = Pdfbox::Pdmodel::Graphics::Color::PDPattern.new
    pattern_name = Pdfbox::Cos::Name.new("P1")
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(pattern_name, color_space)
    color.pattern?.should be_true
    color.pattern_name.should eq(pattern_name)
  end

  it "creates color from COSArray with components" do
    arr = Pdfbox::Cos::Array.new
    arr.add(Pdfbox::Cos::Float.new(0.5))
    arr.add(Pdfbox::Cos::Float.new(0.6))
    arr.add(Pdfbox::Cos::Float.new(0.7))

    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(arr, nil)
    color.components.size.should eq(3)
    color.components[0].should eq(0.5_f32)
    color.components[1].should eq(0.6_f32)
    color.components[2].should eq(0.7_f32)
    color.pattern?.should be_false
  end

  it "creates color from COSArray with pattern name" do
    arr = Pdfbox::Cos::Array.new
    arr.add(Pdfbox::Cos::Float.new(0.5))
    arr.add(Pdfbox::Cos::Float.new(0.6))
    arr.add(Pdfbox::Cos::Name.new("P1"))

    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(arr, nil)
    color.components.size.should eq(2)
    color.pattern?.should be_true
  end

  it "converts to COS array" do
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.5_f32, 0.5_f32, 0.5_f32], nil)
    arr = color.to_cos_array
    arr.size.should eq(3)
  end

  it "creates color with components and pattern" do
    color_space = Pdfbox::Pdmodel::Graphics::Color::PDPattern.new
    pattern_name = Pdfbox::Cos::Name.new("P1")
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.5_f32, 0.6_f32], pattern_name, color_space)
    color.components.should eq([0.5_f32, 0.6_f32])
    color.pattern?.should be_true
    color.pattern_name.should eq(pattern_name)
  end
end

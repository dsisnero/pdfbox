require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB do
  it "returns singleton instance" do
    instance = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
    instance.should be_a(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB)
  end

  it "returns correct name" do
    Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE.name.should eq("DeviceRGB")
  end

  it "returns 3 components" do
    Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE.number_of_components.should eq(3)
  end

  it "converts RGB to RGB" do
    rgb = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
    result = rgb.to_rgb([0.5_f32, 0.6_f32, 0.7_f32])
    result.should eq([0.5_f32, 0.6_f32, 0.7_f32])
  end

  it "provides initial color" do
    initial = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE.initial_color
    initial.components.should eq([0.0_f32, 0.0_f32, 0.0_f32])
  end
end

describe Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray do
  it "returns singleton instance" do
    instance = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
    instance.should be_a(Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray)
  end

  it "returns correct name" do
    Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE.name.should eq("DeviceGray")
  end

  it "returns 1 component" do
    Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE.number_of_components.should eq(1)
  end

  it "converts gray to RGB" do
    gray = Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
    result = gray.to_rgb([0.5_f32])
    result.should eq([0.5_f32, 0.5_f32, 0.5_f32])
  end
end

describe Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK do
  it "returns singleton instance" do
    instance = Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE
    instance.should be_a(Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK)
  end

  it "returns correct name" do
    Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE.name.should eq("DeviceCMYK")
  end

  it "returns 4 components" do
    Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE.number_of_components.should eq(4)
  end

  it "converts CMYK to RGB" do
    cmyk = Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE
    # Pure cyan should convert to some blue-ish color
    result = cmyk.to_rgb([1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32])
    result.size.should eq(3)
  end
end

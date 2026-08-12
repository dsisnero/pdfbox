# Port of org.apache.pdfbox.pdmodel.graphics.state.RenderingIntentTest
require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Graphics::State::RenderingIntent do
  it "fromString AbsoluteColorimetric" do
    value = "AbsoluteColorimetric"
    retval = Pdfbox::Pdmodel::Graphics::State::RenderingIntent.from_string(value)
    retval.should eq(Pdfbox::Pdmodel::Graphics::State::RenderingIntent::AbsoluteColorimetric)
  end

  it "fromString RelativeColorimetric" do
    value = "RelativeColorimetric"
    retval = Pdfbox::Pdmodel::Graphics::State::RenderingIntent.from_string(value)
    retval.should eq(Pdfbox::Pdmodel::Graphics::State::RenderingIntent::RelativeColorimetric)
  end

  it "fromString Perceptual" do
    value = "Perceptual"
    retval = Pdfbox::Pdmodel::Graphics::State::RenderingIntent.from_string(value)
    retval.should eq(Pdfbox::Pdmodel::Graphics::State::RenderingIntent::Perceptual)
  end

  it "fromString Saturation" do
    value = "Saturation"
    retval = Pdfbox::Pdmodel::Graphics::State::RenderingIntent.from_string(value)
    retval.should eq(Pdfbox::Pdmodel::Graphics::State::RenderingIntent::Saturation)
  end

  it "fromString empty string defaults to RelativeColorimetric" do
    value = ""
    retval = Pdfbox::Pdmodel::Graphics::State::RenderingIntent.from_string(value)
    retval.should eq(Pdfbox::Pdmodel::Graphics::State::RenderingIntent::RelativeColorimetric)
  end

  it "stringValue of AbsoluteColorimetric" do
    object = Pdfbox::Pdmodel::Graphics::State::RenderingIntent::AbsoluteColorimetric
    object.to_s_value.should eq("AbsoluteColorimetric")
  end
end

describe Pdfbox::Pdmodel::Graphics::State::RenderingMode do
  it "testIsFill" do
    object = Pdfbox::Pdmodel::Graphics::State::RenderingMode::Fill
    object.fills_text?.should be_true
  end
end

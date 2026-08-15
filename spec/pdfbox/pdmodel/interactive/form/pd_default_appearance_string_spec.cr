require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDDefaultAppearanceStringTest.java
describe Pdfbox::Pdmodel::Interactive::Form::PDDefaultAppearanceString do
  it "PDDefaultAppearanceStringTest#testParseDAString" do
    resources = Pdfbox::Pdmodel::PDResources.new
    helvetica = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
    font_resource_name = resources.add(helvetica)

    sample_string = Pdfbox::Cos::String.new("/#{font_resource_name.value} 12 Tf 0.019 0.305 0.627 rg")

    default_appearance_string = Pdfbox::Pdmodel::Interactive::Form::PDDefaultAppearanceString.new(sample_string, resources)

    default_appearance_string.font_size.should be_close(12, 0.001)
    default_appearance_string.font.should eq(helvetica)
    default_appearance_string.font_color.not_nil!.color_space.should be(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    default_appearance_string.font_color.not_nil!.components[0].should be_close(0.019, 0.0001)
    default_appearance_string.font_color.not_nil!.components[1].should be_close(0.305, 0.0001)
    default_appearance_string.font_color.not_nil!.components[2].should be_close(0.627, 0.0001)
  end

  it "PDDefaultAppearanceStringTest#testFontResourceUnavailable" do
    resources = Pdfbox::Pdmodel::PDResources.new
    sample_string = Pdfbox::Cos::String.new("/Helvetica 12 Tf 0.019 0.305 0.627 rg")

    expect_raises(::IO::Error, /Could not find font/) do
      Pdfbox::Pdmodel::Interactive::Form::PDDefaultAppearanceString.new(sample_string, resources)
    end
  end

  it "PDDefaultAppearanceStringTest#testWrongNumberOfColorArguments" do
    resources = Pdfbox::Pdmodel::PDResources.new
    sample_string = Pdfbox::Cos::String.new("/Helvetica 12 Tf 0.305 0.627 rg")

    expect_raises(::IO::Error) do
      Pdfbox::Pdmodel::Interactive::Form::PDDefaultAppearanceString.new(sample_string, resources)
    end
  end
end

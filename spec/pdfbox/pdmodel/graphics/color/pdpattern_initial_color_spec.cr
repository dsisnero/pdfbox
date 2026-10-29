require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDPattern.java
#     `private static final PDColor EMPTY_PATTERN = new PDColor(new float[] { }, null);`
#     and `getInitialColor()` returns exactly that: **no** colour components and
#     **no** colour space.
#
# The port inherited `PDColorSpace#initial_color`, which builds
# `number_of_components` zeros carrying the pattern as their colour space — so an
# uncoloured pattern space (`[/Pattern /DeviceRGB]`) started out with `[0, 0, 0]`
# instead of "no marks".
describe Pdfbox::Pdmodel::Graphics::Color::PDPattern do
  it "has an empty initial color" do
    pattern = Pdfbox::Pdmodel::Graphics::Color::PDPattern.new
    color = pattern.initial_color

    color.components.should be_empty
    color.color_space.should be_nil
    color.pattern_name.should be_nil
  end

  it "has an empty initial color in an uncoloured pattern space" do
    pattern = Pdfbox::Pdmodel::Graphics::Color::PDPattern.new(
      nil, Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
    )
    color = pattern.initial_color

    color.components.should be_empty
    color.color_space.should be_nil
  end
end

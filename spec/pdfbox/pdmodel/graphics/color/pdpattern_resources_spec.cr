require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDPattern.java
#     `PDPattern(PDResources)` and `PDPattern(PDResources, PDColorSpace)` keep the
#     resources of the page the colour space was created for. They are needed by
#     `getPattern(PDColor)`:
#       PDAbstractPattern pattern = resources.getPattern(color.getPatternName());
#       if (pattern == null) throw new IOException("pattern " + name + " was not found");
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDResources.java
#     `getColorSpace(COSName)` builds the space with
#     `PDColorSpace.create(object, this, wasDefault)`, so a `/Pattern` colour
#     space knows its resources (and is deliberately never cached, PDFBOX-2370).
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDColorSpace.java
#     `create(..., resources, ...)`: a `Pattern` name builds `new PDPattern(resources)`;
#     `[/Pattern]` builds the same, `[/Pattern cs]` builds
#     `new PDPattern(resources, create(cs))`.
private def pattern_color_space_cos : Pdfbox::Cos::Dictionary
  pattern_stream = Pdfbox::Cos::Stream.new
  pattern_stream[Pdfbox::Cos::Name.new("PatternType")] = Pdfbox::Cos::Integer.new(1)
  pattern_stream[Pdfbox::Cos::Name.new("PaintType")] = Pdfbox::Cos::Integer.new(1)
  pattern_stream[Pdfbox::Cos::Name.new("TilingType")] = Pdfbox::Cos::Integer.new(1)
  bbox = Pdfbox::Cos::Array.new
  [0, 0, 10, 10].each { |value| bbox.add(Pdfbox::Cos::Integer.new(value)) }
  pattern_stream[Pdfbox::Cos::Name.new("BBox")] = bbox
  pattern_stream[Pdfbox::Cos::Name.new("XStep")] = Pdfbox::Cos::Integer.new(10)
  pattern_stream[Pdfbox::Cos::Name.new("YStep")] = Pdfbox::Cos::Integer.new(10)
  pattern_stream[Pdfbox::Cos::Name.new("Resources")] = Pdfbox::Cos::Dictionary.new

  uncolored = Pdfbox::Cos::Array.new
  uncolored.add(Pdfbox::Cos::Name.new("Pattern"))
  uncolored.add(Pdfbox::Cos::Name.new("DeviceRGB"))

  color_spaces = Pdfbox::Cos::Dictionary.new
  color_spaces[Pdfbox::Cos::Name.new("Cs1")] = Pdfbox::Cos::Name.new("Pattern")
  color_spaces[Pdfbox::Cos::Name.new("Cs2")] = uncolored

  patterns = Pdfbox::Cos::Dictionary.new
  patterns[Pdfbox::Cos::Name.new("P1")] = pattern_stream

  resources = Pdfbox::Cos::Dictionary.new
  resources[Pdfbox::Cos::Name.new("ColorSpace")] = color_spaces
  resources[Pdfbox::Cos::Name.new("Pattern")] = patterns
  resources
end

describe "Pdfbox::Pdmodel::Graphics::Color::PDPattern resources" do
  it "builds a pattern colour space that knows the resources it came from" do
    resources = Pdfbox::Pdmodel::PDResources.new(pattern_color_space_cos)

    color_space = resources.color_space(Pdfbox::Cos::Name.new("Cs1"))

    color_space.should be_a(Pdfbox::Pdmodel::Graphics::Color::PDPattern)
    pattern_space = color_space.as(Pdfbox::Pdmodel::Graphics::Color::PDPattern)
    pattern_space.resources.should be(resources)
    pattern_space.underlying_color_space.should be_nil
  end

  it "keeps the underlying colour space of an uncoloured pattern" do
    resources = Pdfbox::Pdmodel::PDResources.new(pattern_color_space_cos)

    color_space = resources.color_space(Pdfbox::Cos::Name.new("Cs2"))

    pattern_space = color_space.as(Pdfbox::Pdmodel::Graphics::Color::PDPattern)
    pattern_space.resources.should be(resources)
    pattern_space.underlying_color_space.should be(
      Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
    )
  end

  it "returns the pattern a colour refers to" do
    resources = Pdfbox::Pdmodel::PDResources.new(pattern_color_space_cos)
    pattern_space = resources.color_space(Pdfbox::Cos::Name.new("Cs1"))
      .as(Pdfbox::Pdmodel::Graphics::Color::PDPattern)
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(
      Pdfbox::Cos::Name.new("P1"), pattern_space
    )

    pattern = pattern_space.get_pattern(color)

    pattern.should be_a(Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern)
    pattern.pattern_type.should eq(Pdfbox::Pdmodel::Graphics::Pattern::PDAbstractPattern::TYPE_TILING_PATTERN)
  end

  it "raises when the pattern name is not in the resources" do
    resources = Pdfbox::Pdmodel::PDResources.new(pattern_color_space_cos)
    pattern_space = resources.color_space(Pdfbox::Cos::Name.new("Cs1"))
      .as(Pdfbox::Pdmodel::Graphics::Color::PDPattern)
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(
      Pdfbox::Cos::Name.new("P2"), pattern_space
    )

    expect_raises(::IO::Error, /pattern P2 was not found/) do
      pattern_space.get_pattern(color)
    end
  end

  it "raises when a colour carries no pattern name" do
    resources = Pdfbox::Pdmodel::PDResources.new(pattern_color_space_cos)
    pattern_space = resources.color_space(Pdfbox::Cos::Name.new("Cs1"))
      .as(Pdfbox::Pdmodel::Graphics::Color::PDPattern)
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([] of Float32, pattern_space)

    expect_raises(::IO::Error) { pattern_space.get_pattern(color) }
  end

  it "has no resources when the colour space was not created from resources" do
    color_space = Pdfbox::Pdmodel::Graphics::Color::PDColorSpace.create(
      Pdfbox::Cos::Name.new("Pattern")
    )

    pattern_space = color_space.as(Pdfbox::Pdmodel::Graphics::Color::PDPattern)
    pattern_space.resources.should be_nil

    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(
      Pdfbox::Cos::Name.new("P1"), pattern_space
    )
    expect_raises(::IO::Error, /pattern P1 was not found/) do
      pattern_space.get_pattern(color)
    end
  end
end

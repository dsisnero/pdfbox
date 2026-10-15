require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDResources.java
#     add(PDColorSpace) -> "cs", add(PDExtendedGraphicsState) -> "gs",
#     add(PDImageXObject) -> "Im", the dedup + size-based naming in add(), and
#     the put(COSName, ...) overloads.
module Pdfbox::Pdmodel
  describe PDResources do
    it "adds a color space with the cs prefix (Java add(PDColorSpace))" do
      resources = PDResources.new
      name = resources.add(Graphics::Color::PDDeviceRGB::INSTANCE)
      name.value.should eq("cs1")
      resources.color_space(name).should_not be_nil
    end

    it "adds an extended graphics state with the gs prefix (Java add(PDExtendedGraphicsState))" do
      resources = PDResources.new
      state = Graphics::State::PDExtendedGraphicsState.new
      name = resources.add(state)
      name.value.should eq("gs1")
      resources.ext_g_state(name).should_not be_nil
    end

    it "returns the existing name for a resource added twice (Java add dedup)" do
      resources = PDResources.new
      shading = Graphics::Shading::PDShadingType1.new(Cos::Dictionary.new)

      first = resources.add(shading)
      second = resources.add(shading)

      second.should eq(first)
      resources.shading_names.size.should eq(1)
    end

    it "uses the resource count to derive the next name (Java createKey)" do
      resources = PDResources.new
      resources.put(Cos::Name.new("cs0"), Graphics::Color::PDDeviceGray::INSTANCE)
      # Existing keys = 1, so the next "cs" name is cs2 (Java size+1 naming).
      resources.add(Graphics::Color::PDDeviceRGB::INSTANCE).value.should eq("cs2")
    end

    it "puts a named color space resource (Java put(COSName, PDColorSpace))" do
      resources = PDResources.new
      name = Cos::Name.new("CS1")
      resources.put(name, Graphics::Color::PDDeviceRGB::INSTANCE)
      resources.color_space(name).should_not be_nil
    end
  end
end

require "../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/pattern/PDAbstractPattern.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/pattern/PDShadingPattern.java
#
# Characterization spec: upstream has no dedicated PDAbstractPattern test, so
# these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Pattern
  describe PDAbstractPattern do
    it "dispatches on /PatternType and rejects unknown types" do
      tiling = Cos::Stream.new
      tiling.set_int(Cos::Name.new("PatternType"), 1)
      PDAbstractPattern.create(tiling).should be_a(PDTilingPattern)

      shading = Cos::Dictionary.new
      shading.set_int(Cos::Name.new("PatternType"), 2)
      PDAbstractPattern.create(shading).should be_a(PDShadingPattern)

      expect_raises(::IO::Error) { PDAbstractPattern.create(Cos::Dictionary.new) }
    end

    it "exposes the paint type, type, and matrix through the tiling pattern" do
      pattern = PDTilingPattern.new
      pattern.should be_a(PDAbstractPattern)
      pattern.pattern_type.should eq(PDAbstractPattern::TYPE_TILING_PATTERN)
      pattern.type.should eq("Pattern")

      pattern.paint_type.should eq(0)
      pattern.paint_type = 2
      pattern.paint_type.should eq(2)

      pattern.matrix.should eq(Pdfbox::Util::Matrix.new)
      matrix = Pdfbox::Util::Matrix.new(1.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 5.0_f32, 7.0_f32)
      pattern.matrix = matrix
      pattern.matrix.should eq(matrix)
    end

    it "models the shading pattern (shading + extended graphics state)" do
      pattern = PDShadingPattern.new
      pattern.pattern_type.should eq(PDAbstractPattern::TYPE_SHADING_PATTERN)
      pattern.cos_object.as(Cos::Dictionary).get_int(Cos::Name.new("PatternType"), 0).should eq(2)

      pattern.shading.should be_nil
      shading_dict = Cos::Dictionary.new
      shading_dict.set_int(Cos::Name.new("ShadingType"), 2)
      pattern.shading = Pdfbox::Pdmodel::Graphics::Shading::PDShading.create(shading_dict)
      pattern.shading.should be_a(Pdfbox::Pdmodel::Graphics::Shading::PDShading)

      pattern.extended_graphics_state.should be_nil
      pattern.extended_graphics_state = Pdfbox::Pdmodel::Graphics::State::PDExtendedGraphicsState.new
      pattern.extended_graphics_state.should_not be_nil
    end

    it "PDResources#pattern returns the correct pattern type" do
      resources = Pdfbox::Pdmodel::PDResources.new

      shading_name = resources.add(PDShadingPattern.new)
      resources.pattern(shading_name).should be_a(PDShadingPattern)

      tiling_name = resources.add(PDTilingPattern.new)
      resources.pattern(tiling_name).should be_a(PDTilingPattern)
    end
  end
end

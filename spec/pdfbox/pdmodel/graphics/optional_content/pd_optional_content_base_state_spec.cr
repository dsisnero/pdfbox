require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/optionalcontent/PDOptionalContentProperties.java
#     BaseState.getName (returns the COSName) and BaseState.valueOf(COSName)
#     (nil -> ON, otherwise parsed by name). Upstream has no dedicated test; this
#     is a characterization spec.
module Pdfbox::Pdmodel::Graphics::OptionalContent
  alias BaseState = PDOptionalContentProperties::BaseState

  describe BaseState do
    it "returns the PDF name for each base state" do
      BaseState::On.name.should eq(Pdfbox::Cos::Name.new("ON"))
      BaseState::Off.name.should eq(Pdfbox::Cos::Name.new("OFF"))
      BaseState::Unchanged.name.should eq(Pdfbox::Cos::Name.new("UNCHANGED"))
    end

    it "parses a base state from a name, defaulting a nil name to ON" do
      BaseState.value_of(nil).should eq(BaseState::On)
      BaseState.value_of(Pdfbox::Cos::Name.new("ON")).should eq(BaseState::On)
      BaseState.value_of(Pdfbox::Cos::Name.new("OFF")).should eq(BaseState::Off)
      BaseState.value_of(Pdfbox::Cos::Name.new("UNCHANGED")).should eq(BaseState::Unchanged)
    end

    it "rejects an unknown base state name" do
      expect_raises(ArgumentError) do
        BaseState.value_of(Pdfbox::Cos::Name.new("BOGUS"))
      end
    end
  end
end

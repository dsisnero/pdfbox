require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDICCBased.java
#
# Characterization spec: upstream PDICCBasedTest only covers the constructor and
# getName/getPDStream, so these assertions are inferred from the Java observable
# behavior.
private def build_icc_based(
  n : Int32,
  alternate : Pdfbox::Cos::Base? = nil,
  range : Pdfbox::Cos::Array? = nil,
  metadata : Pdfbox::Cos::Stream? = nil,
) : Pdfbox::Pdmodel::Graphics::Color::PDICCBased
  stream = Pdfbox::Cos::Stream.new
  stream.set_int(Pdfbox::Cos::Name.new("N"), n)
  stream.set_item(Pdfbox::Cos::Name.new("Alternate"), alternate) if alternate
  stream.set_item(Pdfbox::Cos::Name::RANGE, range) if range
  stream.set_item(Pdfbox::Cos::Name::METADATA, metadata) if metadata
  array = Pdfbox::Cos::Array.new
  array.add(Pdfbox::Cos::Name.new("ICCBased"))
  array.add(stream)
  Pdfbox::Pdmodel::Graphics::Color::PDICCBased.new(array)
end

module Pdfbox::Pdmodel::Graphics::Color
  describe PDICCBased do
    it "derives the alternate color space from /N" do
      build_icc_based(1).alternate_color_space.should be_a(PDDeviceGray)
      build_icc_based(3).alternate_color_space.should be_a(PDDeviceRGB)
      build_icc_based(4).alternate_color_space.should be_a(PDDeviceCMYK)
    end

    it "uses the /Alternate entry when present" do
      build_icc_based(3, alternate: Cos::Name.new("DeviceCMYK")).alternate_color_space.should be_a(PDDeviceCMYK)
    end

    it "raises for an unknown component count" do
      expect_raises(::IO::Error) { build_icc_based(2).alternate_color_space }
    end

    it "returns a 0..1 range when /Range is absent and the entry range otherwise" do
      default = build_icc_based(3).range_for_component(1)
      default.min.should eq(0.0)
      default.max.should eq(1.0)

      range = Cos::Array.new([
        Cos::Float.new(0.2), Cos::Float.new(0.8),
        Cos::Float.new(0.1), Cos::Float.new(0.9),
        Cos::Float.new(0.0), Cos::Float.new(1.0),
      ])
      custom = build_icc_based(3, range: range).range_for_component(0)
      custom.min.should eq(0.2)
      custom.max.should eq(0.8)
    end

    it "reads the metadata stream (Java getMetadata)" do
      md = Cos::Stream.new
      build_icc_based(3, metadata: md).metadata.should be(md)
      build_icc_based(3).metadata.should be_nil
    end

    it "round-trips alternate color spaces and per-component range" do
      icc = build_icc_based(3)

      icc.alternate_color_spaces = [PDDeviceCMYK::INSTANCE]
      icc.alternate_color_space.should be_a(PDDeviceCMYK)

      # Java setRangeForComponent only extends the array up to component n, and
      # getRangeForComponent returns the 0..1 default until all N components are
      # present, so all three are set before reading one back.
      range = Common::PDRange.new
      range.min = 0.5
      range.max = 0.75
      icc.set_range_for_component(range, 0)
      icc.set_range_for_component(range, 1)
      icc.set_range_for_component(range, 2)
      icc.range_for_component(1).min.should eq(0.5)
      icc.range_for_component(1).max.should eq(0.75)
    end

    it "rejects a malformed ICCBased array (Java checkArray)" do
      expect_raises(::IO::Error) do
        PDICCBased.new(Cos::Array.new([Cos::Name.new("ICCBased")]))
      end
      expect_raises(::IO::Error) do
        PDICCBased.new(Cos::Array.new([Cos::Name.new("ICCBased"), Cos::Integer.new(3)]))
      end
    end
  end
end

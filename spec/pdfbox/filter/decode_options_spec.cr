require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/DecodeOptions.java
#
# DecodeOptions carries optional parameters to a Filter when decoding a stream:
# a source region to decode, x/y subsampling and offsets, and a filterSubsampled
# flag. The DEFAULT singleton is immutable (its setters throw
# UnsupportedOperationException).

module Pdfbox::Filter
  describe DecodeOptions do
    it "default constructor has no source region and subsampling 1" do
      options = DecodeOptions.new
      options.source_region.should be_nil
      options.subsampling_x.should eq(1)
      options.subsampling_y.should eq(1)
      options.subsampling_offset_x.should eq(0)
      options.subsampling_offset_y.should eq(0)
      options.filter_subsampled?.should be_false
    end

    it "constructs from a source region" do
      region = Pdfbox::Pdmodel::Rectangle.new(10.0, 20.0, 100.0, 200.0)
      options = DecodeOptions.new(region)
      options.source_region.should eq(region)
    end

    it "constructs from x/y/width/height" do
      options = DecodeOptions.new(10, 20, 30, 40)
      region = options.source_region
      region.should_not be_nil
      region.not_nil!.lower_left_x.should eq(10.0)
      region.not_nil!.lower_left_y.should eq(20.0)
      region.not_nil!.width.should eq(30.0)
      region.not_nil!.height.should eq(40.0)
    end

    it "constructs with uniform subsampling" do
      options = DecodeOptions.new(4)
      options.subsampling_x.should eq(4)
      options.subsampling_y.should eq(4)
    end

    it "sets and gets subsampling and offsets" do
      options = DecodeOptions.new
      options.subsampling_x = 2
      options.subsampling_y = 3
      options.subsampling_offset_x = 1
      options.subsampling_offset_y = 2
      options.subsampling_x.should eq(2)
      options.subsampling_y.should eq(3)
      options.subsampling_offset_x.should eq(1)
      options.subsampling_offset_y.should eq(2)
    end

    it "sets the source region" do
      options = DecodeOptions.new
      region = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 50.0, 60.0)
      options.source_region = region
      options.source_region.should eq(region)
      options.source_region = nil
      options.source_region.should be_nil
    end

    it "DEFAULT is immutable" do
      default = DecodeOptions::DEFAULT
      default.filter_subsampled?.should be_true
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
        default.source_region = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 10.0, 10.0)
      end
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
        default.subsampling_x = 2
      end
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
        default.subsampling_y = 2
      end
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
        default.subsampling_offset_x = 1
      end
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
        default.subsampling_offset_y = 1
      end
    end
  end
end

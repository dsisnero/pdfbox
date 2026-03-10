require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type3_font"

module Type3CharProcSpecHelpers
  def self.build_type3_font : Pdfbox::Pdmodel::Font::PDType3Font
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type3")
    dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name::STANDARD_ENCODING
    Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
  end

  def self.build_char_proc(stream_data : String) : Pdfbox::Pdmodel::Font::PDType3CharProc
    stream = Pdfbox::Cos::Stream.new(data: stream_data.to_slice)
    Pdfbox::Pdmodel::Font::PDType3CharProc.new(build_type3_font, stream)
  end
end

describe Pdfbox::Pdmodel::Font::PDType3CharProc do
  describe "#width" do
    it "returns first argument for d0 operator" do
      char_proc = Type3CharProcSpecHelpers.build_char_proc("500 0 d0")
      char_proc.width.should eq(500.0_f32)
    end

    it "returns first argument for d1 operator" do
      char_proc = Type3CharProcSpecHelpers.build_char_proc("600 0 1 2 3 4 d1")
      char_proc.width.should eq(600.0_f32)
    end

    it "raises if first operator is neither d0 nor d1" do
      char_proc = Type3CharProcSpecHelpers.build_char_proc("100 200 m")
      expect_raises(IO::Error, "First operator must be d0 or d1") do
        char_proc.width
      end
    end

    it "raises if first argument is not a number" do
      char_proc = Type3CharProcSpecHelpers.build_char_proc("/A 0 d0")
      expect_raises(IO::Error, "Unexpected argument type: Pdfbox::Cos::Name") do
        char_proc.width
      end
    end

    it "raises on unexpected end of stream" do
      char_proc = Type3CharProcSpecHelpers.build_char_proc("")
      expect_raises(IO::Error, "Unexpected end of stream") do
        char_proc.width
      end
    end
  end

  describe "#glyph_bounding_box" do
    it "returns a rectangle when first operator is d1 with six numeric args" do
      char_proc = Type3CharProcSpecHelpers.build_char_proc("600 0 10 20 30 50 d1")
      bbox = char_proc.glyph_bounding_box
      bbox.should_not be_nil
      bbox = bbox.not_nil!
      bbox.lower_left_x.should eq(10.0_f32)
      bbox.lower_left_y.should eq(20.0_f32)
      bbox.width.should eq(20.0_f32)
      bbox.height.should eq(30.0_f32)
    end

    it "returns nil when first operator is not d1" do
      char_proc = Type3CharProcSpecHelpers.build_char_proc("10 20 m")
      char_proc.glyph_bounding_box.should be_nil
    end

    it "returns nil when d1 args are not all numbers" do
      char_proc = Type3CharProcSpecHelpers.build_char_proc("/A 0 10 20 30 40 d1")
      char_proc.glyph_bounding_box.should be_nil
    end
  end
end

require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type3_font"

module Type3FontSpecHelpers
  def self.build_font_dict : Pdfbox::Cos::Dictionary
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type3")
    dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name::STANDARD_ENCODING
    dict
  end

  def self.float_array(values : Array(Float64)) : Pdfbox::Cos::Array
    Pdfbox::Cos::Array.new(values.map { |value| Pdfbox::Cos::Float.new(value) })
  end
end

class TestType3Font < Pdfbox::Pdmodel::Font::PDType3Font
  def encode_public(unicode : Int32) : Bytes
    encode(unicode)
  end
end

describe Pdfbox::Pdmodel::Font::PDType3Font do
  describe "#has_glyph?" do
    it "returns true when the char proc dictionary has a stream for the glyph name" do
      dict = Type3FontSpecHelpers.build_font_dict
      char_procs = Pdfbox::Cos::Dictionary.new
      char_procs[Pdfbox::Cos::Name.new("A")] = Pdfbox::Cos::Stream.new(data: "500 0 d0".to_slice)
      dict[Pdfbox::Cos::Name::CHAR_PROCS] = char_procs

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      font.has_glyph?("A").should be_true
      font.has_glyph?("B").should be_false
    end
  end

  describe "#width and #width_from_font" do
    it "uses WIDTHS when code is in range" do
      dict = Type3FontSpecHelpers.build_font_dict
      dict[Pdfbox::Cos::Name::FIRST_CHAR] = Pdfbox::Cos::Integer.new(65)
      dict[Pdfbox::Cos::Name::LAST_CHAR] = Pdfbox::Cos::Integer.new(67)
      dict[Pdfbox::Cos::Name::WIDTHS] = Type3FontSpecHelpers.float_array([500.0, 510.0, 520.0])

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      font.width(66).should eq(510.0_f32)
    end

    it "returns 0 when width index would be out of bounds" do
      dict = Type3FontSpecHelpers.build_font_dict
      dict[Pdfbox::Cos::Name::FIRST_CHAR] = Pdfbox::Cos::Integer.new(65)
      dict[Pdfbox::Cos::Name::LAST_CHAR] = Pdfbox::Cos::Integer.new(67)
      dict[Pdfbox::Cos::Name::WIDTHS] = Type3FontSpecHelpers.float_array([500.0])

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      font.width(67).should eq(0.0_f32)
    end

    it "falls back to font descriptor missing width when WIDTHS do not apply" do
      dict = Type3FontSpecHelpers.build_font_dict
      descriptor = Pdfbox::Cos::Dictionary.new
      descriptor[Pdfbox::Cos::Name::MISSING_WIDTH] = Pdfbox::Cos::Float.new(777.0)
      dict[Pdfbox::Cos::Name::FONT_DESC] = descriptor

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      font.width(65).should eq(777.0_f32)
    end

    it "returns width from char proc stream when no descriptor width is available" do
      dict = Type3FontSpecHelpers.build_font_dict
      char_procs = Pdfbox::Cos::Dictionary.new
      char_procs[Pdfbox::Cos::Name.new("A")] = Pdfbox::Cos::Stream.new(data: "650 0 d0".to_slice)
      dict[Pdfbox::Cos::Name::CHAR_PROCS] = char_procs

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      font.width_from_font(65).should eq(650.0_f32)
    end

    it "returns 0 for missing or empty char proc streams" do
      dict = Type3FontSpecHelpers.build_font_dict
      char_procs = Pdfbox::Cos::Dictionary.new
      char_procs[Pdfbox::Cos::Name.new("A")] = Pdfbox::Cos::Stream.new(data: Bytes.empty)
      dict[Pdfbox::Cos::Name::CHAR_PROCS] = char_procs

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      font.width_from_font(65).should eq(0.0_f32)
      font.width_from_font(66).should eq(0.0_f32)
    end
  end

  describe "#font_matrix" do
    it "reads a valid six-number FONT_MATRIX entry" do
      dict = Type3FontSpecHelpers.build_font_dict
      dict[Pdfbox::Cos::Name::FONT_MATRIX] = Type3FontSpecHelpers.float_array([0.002, 0.0, 0.0, 0.003, 1.0, 2.0])

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      matrix = font.font_matrix
      matrix.a.should eq(0.002_f32)
      matrix.d.should eq(0.003_f32)
      matrix.e.should eq(1.0_f32)
      matrix.f.should eq(2.0_f32)
    end
  end

  describe "Type3 dictionary encoding semantics" do
    it "treats Differences as complete encoding when BaseEncoding is absent" do
      dict = Type3FontSpecHelpers.build_font_dict
      encoding_dict = Pdfbox::Cos::Dictionary.new
      encoding_dict[Pdfbox::Cos::Name::DIFFERENCES] = Pdfbox::Cos::Array.new([
        Pdfbox::Cos::Integer.new(65),
        Pdfbox::Cos::Name.new("A"),
      ] of Pdfbox::Cos::Base)
      dict[Pdfbox::Cos::Name::ENCODING] = encoding_dict

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      font.encoding.get_name(65).should eq("A")
      font.encoding.get_name(66).should eq(".notdef")
    end
  end

  describe "#font_bounding_box" do
    it "returns rectangle from FONT_BBOX array" do
      dict = Type3FontSpecHelpers.build_font_dict
      dict[Pdfbox::Cos::Name::FONT_BBOX] = Type3FontSpecHelpers.float_array([1.0, 2.0, 31.0, 52.0])

      font = Pdfbox::Pdmodel::Font::PDType3Font.new(dict)
      bbox = font.font_bounding_box
      bbox.should_not be_nil
      bbox = bbox.not_nil!
      bbox.lower_left_x.should eq(1.0_f32)
      bbox.lower_left_y.should eq(2.0_f32)
      bbox.upper_right_x.should eq(31.0_f32)
      bbox.upper_right_y.should eq(52.0_f32)
    end
  end

  describe "basic flags and io methods" do
    it "matches type3 embedded/standard14/damaged invariants" do
      font = Pdfbox::Pdmodel::Font::PDType3Font.new(Type3FontSpecHelpers.build_font_dict)
      font.embedded?.should be_true
      font.standard14?.should be_false
      font.damaged?.should be_false
    end

    it "reads one-byte codes and returns -1 at EOF" do
      font = Pdfbox::Pdmodel::Font::PDType3Font.new(Type3FontSpecHelpers.build_font_dict)
      io = IO::Memory.new(Bytes[0x41_u8])
      font.read_code(io).should eq(65)
      font.read_code(io).should eq(-1)
    end

    it "raises NotImplementedError for unsupported Type3 vector/fontbox operations" do
      font = Pdfbox::Pdmodel::Font::PDType3Font.new(Type3FontSpecHelpers.build_font_dict)

      expect_raises(NotImplementedError, "not supported for Type 3 fonts") { font.get_path("A") }
      expect_raises(NotImplementedError, "not supported for Type 3 fonts") { font.font_box_font }
    end

    it "raises NotImplementedError for Type3 encode" do
      font = TestType3Font.new(Type3FontSpecHelpers.build_font_dict)
      expect_raises(NotImplementedError, "Not implemented: Type3") do
        font.encode_public('A'.ord)
      end
    end
  end
end

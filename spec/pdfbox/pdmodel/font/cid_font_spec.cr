require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/cid_font"

class MockPDCIDFont < Pdfbox::Pdmodel::Font::PDCIDFont
  def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    super(font_dictionary, nil)
  end

  def code_to_cid(code : Int32) : Int32
    code
  end

  def code_to_gid(code : Int32) : Int32
    code
  end

  def encode_glyph_id(glyph_id : Int32) : Bytes
    Bytes[glyph_id.to_u8]
  end

  protected def encode(unicode : Int32) : Bytes
    Bytes[unicode.to_u8]
  end

  def font_matrix : Pdfbox::Pdmodel::Font::PDFont::Matrix
    Pdfbox::Pdmodel::Font::PDFont::Matrix.default_font_matrix
  end

  def bounding_box : Pdfbox::Pdmodel::Font::PDFont::BoundingBox
    Pdfbox::Pdmodel::Font::PDFont::BoundingBox.new(0.0_f32, 0.0_f32, 1000.0_f32, 1000.0_f32)
  end

  def width_from_font(code : Int32) : Float32
    width(code)
  end

  def embedded? : Bool
    false
  end

  def damaged? : Bool
    false
  end

  def get_path(code : Int32)
    nil
  end

  def get_normalized_path(code : Int32)
    nil
  end

  def has_glyph(code : Int32) : Bool
    true
  end
end

describe Pdfbox::Pdmodel::Font::PDCIDFont do
  it "reads W entries and falls back to DW like Java" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name.new("W")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(1),
      Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(500), Pdfbox::Cos::Integer.new(600)] of Pdfbox::Cos::Base),
      Pdfbox::Cos::Integer.new(10),
      Pdfbox::Cos::Integer.new(12),
      Pdfbox::Cos::Integer.new(700),
    ] of Pdfbox::Cos::Base)
    dict[Pdfbox::Cos::Name.new("DW")] = Pdfbox::Cos::Integer.new(333)

    font = MockPDCIDFont.new(dict)

    font.width(1).should eq(500.0_f32)
    font.width(2).should eq(600.0_f32)
    font.width(10).should eq(700.0_f32)
    font.width(11).should eq(700.0_f32)
    font.width(99).should eq(333.0_f32)
    font.has_explicit_width?(2).should be_true
    font.has_explicit_width?(99).should be_false
  end

  it "reads DW2 and W2 vertical metrics and uses default vectors" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name.new("W")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(3),
      Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(400), Pdfbox::Cos::Integer.new(410)] of Pdfbox::Cos::Base),
    ] of Pdfbox::Cos::Base)
    dict[Pdfbox::Cos::Name.new("DW2")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(900),
      Pdfbox::Cos::Integer.new(-1200),
    ] of Pdfbox::Cos::Base)
    dict[Pdfbox::Cos::Name.new("W2")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(3),
      Pdfbox::Cos::Array.new([
        Pdfbox::Cos::Integer.new(-500),
        Pdfbox::Cos::Integer.new(250),
        Pdfbox::Cos::Integer.new(880),
        Pdfbox::Cos::Integer.new(-600),
        Pdfbox::Cos::Integer.new(260),
        Pdfbox::Cos::Integer.new(870),
      ] of Pdfbox::Cos::Base),
      Pdfbox::Cos::Integer.new(10),
      Pdfbox::Cos::Integer.new(11),
      Pdfbox::Cos::Integer.new(-700),
      Pdfbox::Cos::Integer.new(300),
      Pdfbox::Cos::Integer.new(910),
    ] of Pdfbox::Cos::Base)

    font = MockPDCIDFont.new(dict)

    font.vertical_displacement_vector_y(3).should eq(-500.0_f32)
    font.position_vector(3).x.should eq(250.0_f32)
    font.position_vector(3).y.should eq(880.0_f32)

    font.vertical_displacement_vector_y(11).should eq(-700.0_f32)
    font.position_vector(11).x.should eq(300.0_f32)
    font.position_vector(11).y.should eq(910.0_f32)

    font.vertical_displacement_vector_y(99).should eq(-1200.0_f32)
    font.position_vector(99).x.should eq(500.0_f32)
    font.position_vector(99).y.should eq(900.0_f32)
  end

  it "computes average width like Java and falls back to DW when no positive widths exist" do
    dict1 = Pdfbox::Cos::Dictionary.new
    dict1[Pdfbox::Cos::Name.new("W")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(1),
      Pdfbox::Cos::Array.new([
        Pdfbox::Cos::Integer.new(100),
        Pdfbox::Cos::Integer.new(200),
        Pdfbox::Cos::Integer.new(-50),
      ] of Pdfbox::Cos::Base),
    ] of Pdfbox::Cos::Base)
    font1 = MockPDCIDFont.new(dict1)
    font1.average_font_width.should eq(150.0_f32)

    dict2 = Pdfbox::Cos::Dictionary.new
    dict2[Pdfbox::Cos::Name.new("W")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(1),
      Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(0)] of Pdfbox::Cos::Base),
    ] of Pdfbox::Cos::Base)
    dict2[Pdfbox::Cos::Name.new("DW")] = Pdfbox::Cos::Integer.new(777)
    font2 = MockPDCIDFont.new(dict2)
    font2.average_font_width.should eq(777.0_f32)
  end
end

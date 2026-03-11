require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type0_font"
require "../../../../src/fontbox/ttf/ttf_parser"

module CIDFontTypeSpecHelpers
  def self.build_type0_dict(cid_subtype : String, cid_to_gid_bytes : Bytes? = nil) : Pdfbox::Cos::Dictionary
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new(cid_subtype)
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")
    if cid_to_gid_bytes
      descendant[Pdfbox::Cos::Name.new("CIDToGIDMap")] = Pdfbox::Cos::Stream.new({} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, cid_to_gid_bytes)
    end

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)
    dict
  end
end

describe "CID descendant font parity slices" do
  it "uses CIDToGID map bounds and two-byte glyph-id encoding for CIDFontType2" do
    dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2", Bytes[0x00_u8, 0x02_u8, 0x00_u8, 0x03_u8])
    font = Pdfbox::Pdmodel::Font::PDType0Font.new(dict).descendant_font.as(Pdfbox::Pdmodel::Font::PDCIDFontType2)

    font.code_to_cid(7).should eq(7)
    font.code_to_gid(1).should eq(3)
    font.code_to_gid(9).should eq(0)
    font.encode_glyph_id(0x1234).should eq(Bytes[0x12_u8, 0x34_u8])
  end

  it "keeps code-to-cid fallback and unsupported glyph-id encoding for CIDFontType0" do
    dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType0")
    font = Pdfbox::Pdmodel::Font::PDType0Font.new(dict).descendant_font.as(Pdfbox::Pdmodel::Font::PDCIDFontType0)

    font.code_to_cid(7).should eq(7)
    expect_raises(NotImplementedError) do
      font.encode_glyph_id(1)
    end
  end

  it "uses gid!=0 for has_glyph in CIDFontType0 and CIDFontType2" do
    type2_dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2", Bytes[0x00_u8, 0x00_u8, 0x00_u8, 0x01_u8])
    type2_font = Pdfbox::Pdmodel::Font::PDType0Font.new(type2_dict).descendant_font
    type2_font.has_glyph(0).should be_false
    type2_font.has_glyph(1).should be_true

    type0_dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType0")
    type0_font = Pdfbox::Pdmodel::Font::PDType0Font.new(type0_dict).descendant_font
    type0_font.has_glyph(0).should be_false
    type0_font.has_glyph(1).should be_true
  end

  it "uses TrueType hhea metrics for CIDFontType2 height and scales widths" do
    type0_dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2")
    parent = Pdfbox::Pdmodel::Font::PDType0Font.new(type0_dict)
    descendant_dict = type0_dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS).not_nil![0].as(Pdfbox::Cos::Dictionary)
    ttf_path = SpecPaths.resolve("vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")

    ttf = Fontbox::TTF::TTFParser.new.parse_embedded(File.open(ttf_path))
    begin
      font = Pdfbox::Pdmodel::Font::PDCIDFontType2.new(descendant_dict, parent, ttf)
      font.height(10).should be > 0.0_f32
      font.width_from_font(10).should be >= 0.0_f32
    ensure
      ttf.close
    end
  end
end

require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type0_font"

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
end

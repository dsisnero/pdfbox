require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type0_font"

module Type0FontSpecHelpers
  def self.build_valid_type0_dict(cid_subtype : String = "CIDFontType2") : Pdfbox::Cos::Dictionary
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new(cid_subtype)
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)
    dict
  end
end

describe Pdfbox::Pdmodel::Font::PDType0Font do
  it "builds with a valid descendant font dictionary" do
    font = Pdfbox::Pdmodel::Font::PDType0Font.new(Type0FontSpecHelpers.build_valid_type0_dict)
    font.name.should eq("DummyType0")
    font.descendant_font.should be_a(Pdfbox::Pdmodel::Font::PDCIDFontType2)
  end

  it "raises when descendant font array is missing" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0

    expect_raises(IO::Error, "Missing descendant font array") do
      Pdfbox::Pdmodel::Font::PDType0Font.new(dict)
    end
  end

  it "raises when descendant font array is empty" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new

    expect_raises(IO::Error, "Descendant font array is empty") do
      Pdfbox::Pdmodel::Font::PDType0Font.new(dict)
    end
  end

  it "raises when descendant font dictionary entry is missing" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([Pdfbox::Cos::Name::FONT] of Pdfbox::Cos::Base)

    expect_raises(IO::Error, "Missing descendant font dictionary") do
      Pdfbox::Pdmodel::Font::PDType0Font.new(dict)
    end
  end

  it "raises when descendant font dictionary type is not Font" do
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name.new("NotFont")
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType2")

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)

    expect_raises(IO::Error, "Missing or wrong type in descendant font dictionary") do
      Pdfbox::Pdmodel::Font::PDType0Font.new(dict)
    end
  end
end

require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/font_factory"

module FontFactorySpecHelpers
  def self.build_type3_dict : Pdfbox::Cos::Dictionary
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE3
    dict[Pdfbox::Cos::Name::NAME] = Pdfbox::Cos::Name.new("F3")
    dict[Pdfbox::Cos::Name::FIRST_CHAR] = Pdfbox::Cos::Integer.new(0)
    dict[Pdfbox::Cos::Name::LAST_CHAR] = Pdfbox::Cos::Integer.new(0)
    dict[Pdfbox::Cos::Name::WIDTHS] = Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(500)] of Pdfbox::Cos::Base)
    dict[Pdfbox::Cos::Name::FONT_BBOX] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(0),
      Pdfbox::Cos::Integer.new(0),
      Pdfbox::Cos::Integer.new(1000),
      Pdfbox::Cos::Integer.new(1000),
    ] of Pdfbox::Cos::Base)
    dict[Pdfbox::Cos::Name::FONT_MATRIX] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Float.new(0.001_f32),
      Pdfbox::Cos::Float.new(0.0_f32),
      Pdfbox::Cos::Float.new(0.0_f32),
      Pdfbox::Cos::Float.new(0.001_f32),
      Pdfbox::Cos::Float.new(0.0_f32),
      Pdfbox::Cos::Float.new(0.0_f32),
    ] of Pdfbox::Cos::Base)
    dict[Pdfbox::Cos::Name::CHAR_PROCS] = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name::WIN_ANSI_ENCODING
    dict[Pdfbox::Cos::Name::RESOURCES] = Pdfbox::Cos::Dictionary.new
    dict
  end

  def self.build_type0_dict(cid_subtype : String) : Pdfbox::Cos::Dictionary
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new(cid_subtype)
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)
    dict
  end

  def self.build_type1_like_dict(subtype : String, with_font_file3 : Bool) : Pdfbox::Cos::Dictionary
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new(subtype)

    return dict unless with_font_file3

    font_descriptor = Pdfbox::Cos::Dictionary.new
    font_descriptor[Pdfbox::Cos::Name::FONT_FILE3] = Pdfbox::Cos::Stream.new(data: Bytes[1_u8, 0_u8, 4_u8, 1_u8])
    dict[Pdfbox::Cos::Name::FONT_DESC] = font_descriptor
    dict
  end
end

describe Pdfbox::Pdmodel::Font::PDFontFactory do
  it "creates a PDType3Font for Type3 subtype" do
    font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(FontFactorySpecHelpers.build_type3_dict)
    font.should be_a(Pdfbox::Pdmodel::Font::PDType3Font)
  end

  it "creates a PDType3Font with explicit resource cache overload" do
    dict = FontFactorySpecHelpers.build_type3_dict
    cache = Pdfbox::Pdmodel::Font::ResourceCache.new
    font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dict, cache)
    font.should be_a(Pdfbox::Pdmodel::Font::PDType3Font)
  end

  it "creates a PDType0Font with CIDFontType2 descendant for Type0 subtype" do
    font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(FontFactorySpecHelpers.build_type0_dict("CIDFontType2"))
    type0 = font.as(Pdfbox::Pdmodel::Font::PDType0Font)
    type0.descendant_font.should be_a(Pdfbox::Pdmodel::Font::PDCIDFontType2)
  end

  it "fixes mismatched Type0 descendant subtype based on embedded font header" do
    dict = FontFactorySpecHelpers.build_type0_dict("CIDFontType2")
    descendant = dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS).not_nil![0].as(Pdfbox::Cos::Dictionary)

    font_descriptor = Pdfbox::Cos::Dictionary.new
    # Type1 header '%!' should map Type0 descendants to CIDFontType0.
    font_descriptor[Pdfbox::Cos::Name::FONT_FILE2] = Pdfbox::Cos::Stream.new(data: Bytes[0x25_u8, 0x21_u8, 0_u8, 0_u8])
    descendant[Pdfbox::Cos::Name::FONT_DESC] = font_descriptor

    font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dict)
    type0 = font.as(Pdfbox::Pdmodel::Font::PDType0Font)

    type0.descendant_font.should be_a(Pdfbox::Pdmodel::Font::PDCIDFontType0)
    font_descriptor.get_stream(Pdfbox::Cos::Name::FONT_FILE3).should_not be_nil
    font_descriptor.get_stream(Pdfbox::Cos::Name::FONT_FILE2).should be_nil
  end

  it "raises for direct CIDFontType0 subtype at top level" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType0")

    expect_raises(::IO::Error, "Type 0 descendant font not allowed") do
      Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dict)
    end
  end

  it "raises for direct CIDFontType2 subtype at top level" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType2")

    expect_raises(::IO::Error, "Type 2 descendant font not allowed") do
      Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dict)
    end
  end

  it "falls back to PDType1Font path for unknown subtype" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("UnknownSubtype")

    expect_raises(Exception, "Not implemented") do
      Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dict)
    end
  end

  it "raises in create_descendant_font when dictionary type is not Font" do
    type0_parent = Pdfbox::Pdmodel::Font::PDType0Font.new(FontFactorySpecHelpers.build_type0_dict("CIDFontType2"))
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name.new("NotFont")
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType2")

    expect_raises(::IO::Error, "Expected 'Font' dictionary but found 'NotFont'") do
      Pdfbox::Pdmodel::Font::PDFontFactory.create_descendant_font(descendant, type0_parent)
    end
  end

  it "raises in create_descendant_font for invalid descendant subtype" do
    type0_parent = Pdfbox::Pdmodel::Font::PDType0Font.new(FontFactorySpecHelpers.build_type0_dict("CIDFontType2"))
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("InvalidCIDSubtype")

    expect_raises(::IO::Error, "Invalid font type: Font") do
      Pdfbox::Pdmodel::Font::PDFontFactory.create_descendant_font(descendant, type0_parent)
    end
  end

  it "routes Type1 with FontFile3 to PDType1CFont path" do
    dict = FontFactorySpecHelpers.build_type1_like_dict("Type1", with_font_file3: true)

    expect_raises(Exception, "Not implemented: PDType1CFont") do
      Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dict)
    end
  end

  it "routes MMType1 with FontFile3 to PDType1CFont path" do
    dict = FontFactorySpecHelpers.build_type1_like_dict("MMType1", with_font_file3: true)

    expect_raises(Exception, "Not implemented: PDType1CFont") do
      Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dict)
    end
  end

  it "routes MMType1 without FontFile3 to PDMMType1Font path" do
    dict = FontFactorySpecHelpers.build_type1_like_dict("MMType1", with_font_file3: false)

    expect_raises(Exception, "Not implemented: PDMMType1Font") do
      Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dict)
    end
  end
end

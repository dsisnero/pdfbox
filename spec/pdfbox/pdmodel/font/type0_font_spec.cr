require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type0_font"
require "../../../../src/fontbox/ttf/ttf_parser"

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

class TestableType0Font < Pdfbox::Pdmodel::Font::PDType0Font
  def force_descendant_font(font : Pdfbox::Pdmodel::Font::PDCIDFont) : Nil
    @descendant_font = font
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

  it "uses TrueType cmap fallback for to_unicode when ToUnicode/predefined maps are unavailable" do
    dict = Type0FontSpecHelpers.build_valid_type0_dict("CIDFontType2")
    font = TestableType0Font.new(dict)
    descendant_dict = dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS).not_nil![0].as(Pdfbox::Cos::Dictionary)
    ttf_path = SpecPaths.resolve("vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")
    ttf = Fontbox::TTF::TTFParser.new.parse_embedded(File.open(ttf_path))
    begin
      descendant = Pdfbox::Pdmodel::Font::PDCIDFontType2.new(descendant_dict, font, ttf)
      font.force_descendant_font(descendant)
      cmap = ttf.unicode_cmap_lookup(false)

      test_gid = -1
      expected_unicode = nil
      max_gid = {ttf.number_of_glyphs, 2048}.min
      (1...max_gid).each do |gid|
        codes = cmap.char_codes(gid)
        next if codes.nil? || codes.empty?
        cp = codes[0]
        begin
          expected_unicode = cp.chr.to_s
          test_gid = gid
          break
        rescue ArgumentError
          next
        end
      end

      test_gid.should be > 0
      expected_unicode.should_not be_nil
      font.to_unicode(test_gid).should eq(expected_unicode)
    ensure
      ttf.close
    end
  end

  it "scales descendant position vectors by -1/1000 for Type0 semantics" do
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType2")
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")
    descendant[Pdfbox::Cos::Name.new("W")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(5),
      Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(700)] of Pdfbox::Cos::Base),
    ] of Pdfbox::Cos::Base)
    descendant[Pdfbox::Cos::Name.new("W2")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(5),
      Pdfbox::Cos::Array.new([
        Pdfbox::Cos::Integer.new(-600),
        Pdfbox::Cos::Integer.new(300),
        Pdfbox::Cos::Integer.new(900),
      ] of Pdfbox::Cos::Base),
    ] of Pdfbox::Cos::Base)

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)

    font = Pdfbox::Pdmodel::Font::PDType0Font.new(dict)
    vector = font.position_vector(5)
    vector.x.should be_close(-0.3_f32, 0.00001_f32)
    vector.y.should be_close(-0.9_f32, 0.00001_f32)
  end

  it "matches Java-style to_s shape with descendant type and base name" do
    font = Pdfbox::Pdmodel::Font::PDType0Font.new(Type0FontSpecHelpers.build_valid_type0_dict)
    font.to_s.should eq("PDType0Font/PDCIDFontType2, PostScript name: DummyType0")
  end

  it "reports composite_font? true for Type0" do
    font = Pdfbox::Pdmodel::Font::PDType0Font.new(Type0FontSpecHelpers.build_valid_type0_dict)
    font.composite_font?.should be_true
  end

  it "reports standard14? false for Type0" do
    font = Pdfbox::Pdmodel::Font::PDType0Font.new(Type0FontSpecHelpers.build_valid_type0_dict)
    font.standard14?.should be_false
  end

  it "exposes base_font separately from name for Java API parity" do
    font = Pdfbox::Pdmodel::Font::PDType0Font.new(Type0FontSpecHelpers.build_valid_type0_dict)
    font.base_font.should eq("DummyType0")
    font.name.should eq(font.base_font)
  end

  it "delegates font_descriptor lookup to the descendant font dictionary" do
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType2")
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")

    descendant_descriptor = Pdfbox::Cos::Dictionary.new
    descendant_descriptor[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name.new("FontDescriptor")
    descendant_descriptor[Pdfbox::Cos::Name::FONT_NAME] = Pdfbox::Cos::Name.new("DescendantFont")
    descendant[Pdfbox::Cos::Name::FONT_DESC] = descendant_descriptor

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)

    top_level_descriptor = Pdfbox::Cos::Dictionary.new
    top_level_descriptor[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name.new("FontDescriptor")
    top_level_descriptor[Pdfbox::Cos::Name::FONT_NAME] = Pdfbox::Cos::Name.new("TopLevelFont")
    dict[Pdfbox::Cos::Name::FONT_DESC] = top_level_descriptor

    font = Pdfbox::Pdmodel::Font::PDType0Font.new(dict)
    font.font_descriptor.not_nil!.font_name.should eq("DescendantFont")
  end
end

require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type0_font"
require "../../../../src/fontbox/ttf/ttf_parser"

class TestableCIDFontType2 < Pdfbox::Pdmodel::Font::PDCIDFontType2
  def force_embedded(value : Bool) : Nil
    @is_embedded = value
  end

  def encode_unicode(unicode : Int32) : Bytes
    encode(unicode)
  end
end

module CIDFontTypeSpecHelpers
  def self.build_type0_dict(cid_subtype : String, cid_to_gid_bytes : Bytes? = nil, embedded : Bool = false) : Pdfbox::Cos::Dictionary
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new(cid_subtype)
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")
    if embedded
      fd = Pdfbox::Cos::Dictionary.new
      embedded_stream = Pdfbox::Cos::Stream.new
      embedded_stream.data = Bytes[0x00_u8]
      fd[Pdfbox::Cos::Name::FONT_FILE2] = embedded_stream
      descendant[Pdfbox::Cos::Name::FONT_DESC] = fd
    end
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
    dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2", Bytes[0x00_u8, 0x02_u8, 0x00_u8, 0x03_u8], embedded: true)
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

  it "returns empty non-nil paths and dictionary width fallback for CIDFontType0" do
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType0")
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")
    descendant[Pdfbox::Cos::Name.new("W")] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(5),
      Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(700)] of Pdfbox::Cos::Base),
    ] of Pdfbox::Cos::Base)

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)

    font = Pdfbox::Pdmodel::Font::PDType0Font.new(dict).descendant_font.as(Pdfbox::Pdmodel::Font::PDCIDFontType0)
    path = font.get_path(5)
    path.should_not be_nil
    path.empty?.should be_true
    font.get_normalized_path(5).empty?.should be_true
    font.width_from_font(5).should eq(700.0_f32)
  end

  it "prefers non-zero FontDescriptor FontBBox for CIDFontType0 bounding_box" do
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType0")
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")

    fd = Pdfbox::Cos::Dictionary.new
    fd[Pdfbox::Cos::Name::FONT_BBOX] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Float.new(-12.0_f32),
      Pdfbox::Cos::Float.new(-34.0_f32),
      Pdfbox::Cos::Float.new(456.0_f32),
      Pdfbox::Cos::Float.new(789.0_f32),
    ] of Pdfbox::Cos::Base)
    descendant[Pdfbox::Cos::Name::FONT_DESC] = fd

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)

    font = Pdfbox::Pdmodel::Font::PDType0Font.new(dict).descendant_font.as(Pdfbox::Pdmodel::Font::PDCIDFontType0)
    bbox = font.bounding_box
    bbox.lower_left_x.should eq(-12.0_f32)
    bbox.lower_left_y.should eq(-34.0_f32)
    bbox.upper_right_x.should eq(456.0_f32)
    bbox.upper_right_y.should eq(789.0_f32)
  end

  it "parses embedded FontFile3 CFF data for CIDFontType0" do
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType0")
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")

    cff_path = SpecPaths.resolve("spec/resources/fontbox/cff/FoglihtenNo07.otf")
    cff_bytes = File.read(cff_path).to_slice
    embedded_stream = Pdfbox::Cos::Stream.new
    embedded_stream.data = cff_bytes
    fd = Pdfbox::Cos::Dictionary.new
    fd[Pdfbox::Cos::Name::FONT_FILE3] = embedded_stream
    descendant[Pdfbox::Cos::Name::FONT_DESC] = fd

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)

    font = Pdfbox::Pdmodel::Font::PDType0Font.new(dict).descendant_font.as(Pdfbox::Pdmodel::Font::PDCIDFontType0)
    font.embedded?.should be_true
    font.damaged?.should be_false
    font.cff_font.should_not be_nil
    font.font_box_font.should_not be_nil
    font.type2_char_string(1).should_not be_nil
    font.has_glyph(0).should be_false
    font.bounding_box.width.should be >= 0.0_f32
    font.bounding_box.height.should be >= 0.0_f32
    font.average_font_width.should eq(1000.0_f32) # Parent CIDFont computes from default_width
    font.height(1).should be >= 0.0_f32
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

  it "prefers non-zero FontDescriptor FontBBox for CIDFontType2 bounding_box" do
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType2")
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")

    fd = Pdfbox::Cos::Dictionary.new
    fd[Pdfbox::Cos::Name::FONT_BBOX] = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Float.new(-10.0_f32),
      Pdfbox::Cos::Float.new(-20.0_f32),
      Pdfbox::Cos::Float.new(300.0_f32),
      Pdfbox::Cos::Float.new(700.0_f32),
    ] of Pdfbox::Cos::Base)
    descendant[Pdfbox::Cos::Name::FONT_DESC] = fd

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)

    font = Pdfbox::Pdmodel::Font::PDType0Font.new(dict).descendant_font.as(Pdfbox::Pdmodel::Font::PDCIDFontType2)
    bbox = font.bounding_box
    bbox.lower_left_x.should eq(-10.0_f32)
    bbox.lower_left_y.should eq(-20.0_f32)
    bbox.upper_right_x.should eq(300.0_f32)
    bbox.upper_right_y.should eq(700.0_f32)
  end

  it "extracts and normalizes Type2 glyph paths using units-per-em scaling" do
    type0_dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2")
    parent = Pdfbox::Pdmodel::Font::PDType0Font.new(type0_dict)
    descendant_dict = type0_dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS).not_nil![0].as(Pdfbox::Cos::Dictionary)
    ttf_path = SpecPaths.resolve("vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")
    ttf = Fontbox::TTF::TTFParser.new.parse_embedded(File.open(ttf_path))
    begin
      font = Pdfbox::Pdmodel::Font::PDCIDFontType2.new(descendant_dict, parent, ttf)
      units_per_em = ttf.units_per_em
      units_per_em.should be > 1000

      glyph_code = -1
      raw_bounds = nil
      normalized_bounds = nil
      max_gid = {ttf.number_of_glyphs, 2048}.min
      (1...max_gid).each do |gid|
        raw_path = font.get_path(gid)
        norm_path = font.get_normalized_path(gid)
        next if raw_path.empty? || norm_path.empty?
        rb = raw_path.bounds
        nb = norm_path.bounds
        next if rb.width <= 0 || rb.height <= 0
        glyph_code = gid
        raw_bounds = rb
        normalized_bounds = nb
        break
      end

      glyph_code.should be > 0
      raw_bounds.should_not be_nil
      normalized_bounds.should_not be_nil

      scale = 1000.0 / units_per_em.to_f64
      raw_w = raw_bounds.not_nil!.width
      raw_h = raw_bounds.not_nil!.height
      norm_w = normalized_bounds.not_nil!.width
      norm_h = normalized_bounds.not_nil!.height
      norm_w.should be_close(raw_w * scale, 0.01)
      norm_h.should be_close(raw_h * scale, 0.01)
    ensure
      ttf.close
    end
  end

  it "uses Java non-embedded code_to_gid fallback when CIDToGID should not be trusted" do
    descendant = Pdfbox::Cos::Dictionary.new
    descendant[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    descendant[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("CIDFontType2")
    descendant[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyCID")
    cid_to_gid_bytes = Bytes[0x00_u8, 0x02_u8, 0x00_u8, 0x03_u8]
    descendant[Pdfbox::Cos::Name.new("CIDToGIDMap")] = Pdfbox::Cos::Stream.new({} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, cid_to_gid_bytes)

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE0
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("DummyType0")
    dict[Pdfbox::Cos::Name::DESCENDANT_FONTS] = Pdfbox::Cos::Array.new([descendant] of Pdfbox::Cos::Base)

    parent = Pdfbox::Pdmodel::Font::PDType0Font.new(dict)
    ttf_path = SpecPaths.resolve("vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")
    ttf = Fontbox::TTF::TTFParser.new.parse_embedded(File.open(ttf_path))
    begin
      font = TestableCIDFontType2.new(descendant, parent, ttf)
      font.force_embedded(false)
      # Java behavior: with non-embedded font and mismatched names, ignore CIDToGID map.
      font.code_to_gid(1).should eq(1)
    ensure
      ttf.close
    end
  end

  it "encodes non-embedded CIDFontType2 Unicode values via TrueType cmap lookup" do
    type0_dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2")
    parent = Pdfbox::Pdmodel::Font::PDType0Font.new(type0_dict)
    descendant_dict = type0_dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS).not_nil![0].as(Pdfbox::Cos::Dictionary)
    ttf_path = SpecPaths.resolve("vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")
    ttf = Fontbox::TTF::TTFParser.new.parse_embedded(File.open(ttf_path))
    begin
      font = TestableCIDFontType2.new(descendant_dict, parent, ttf)
      font.force_embedded(false)
      expected_gid = ttf.unicode_cmap_lookup(false).glyph_id('A'.ord)
      expected_gid.should be > 0
      font.encode_unicode('A'.ord).should eq(font.encode_glyph_id(expected_gid))
    ensure
      ttf.close
    end
  end

  it "matches Java encode error message shape when glyph is missing" do
    type0_dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2")
    parent = Pdfbox::Pdmodel::Font::PDType0Font.new(type0_dict)
    descendant_dict = type0_dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS).not_nil![0].as(Pdfbox::Cos::Dictionary)
    font = TestableCIDFontType2.new(descendant_dict, parent)
    font.force_embedded(false)

    expect_raises(ArgumentError, /No glyph for U\+0041 \(A\) in font DummyCID/) do
      font.encode_unicode('A'.ord)
    end
  end

  it "uses identity CID->GID for embedded OpenType CFF fonts when no CIDToGID map exists" do
    type0_dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2")
    parent = Pdfbox::Pdmodel::Font::PDType0Font.new(type0_dict)
    descendant_dict = type0_dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS).not_nil![0].as(Pdfbox::Cos::Dictionary)
    otf_path = SpecPaths.resolve("spec/resources/fontbox/cff/FoglihtenNo07.otf")
    otf = Fontbox::TTF::TTFParser.new.parse_embedded(File.open(otf_path))
    begin
      font = TestableCIDFontType2.new(descendant_dict, parent, otf)
      cid = 50_000
      font.code_to_gid(cid).should eq(cid)
    ensure
      otf.close
    end
  end

  it "extracts glyph paths from embedded OpenType CFF outlines in CIDFontType2" do
    type0_dict = CIDFontTypeSpecHelpers.build_type0_dict("CIDFontType2")
    parent = Pdfbox::Pdmodel::Font::PDType0Font.new(type0_dict)
    descendant_dict = type0_dict.get_array(Pdfbox::Cos::Name::DESCENDANT_FONTS).not_nil![0].as(Pdfbox::Cos::Dictionary)
    otf_path = SpecPaths.resolve("spec/resources/fontbox/cff/FoglihtenNo07.otf")
    otf = Fontbox::TTF::TTFParser.new.parse_embedded(File.open(otf_path))
    begin
      font = TestableCIDFontType2.new(descendant_dict, parent, otf)

      found_non_empty = false
      (1..256).each do |code|
        path = font.get_path(code)
        normalized = font.get_normalized_path(code)
        next if path.empty? || normalized.empty?
        found_non_empty = true
        break
      end

      found_non_empty.should be_true
    ensure
      otf.close
    end
  end
end

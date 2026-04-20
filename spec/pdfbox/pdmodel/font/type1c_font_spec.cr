require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/type1c_font"

describe Pdfbox::Pdmodel::Font::PDType1CFont do
  it "uses embedded CFF data for paths, widths, height, and string widths" do
    otf_path = "vendor/pdfbox/fontbox/src/test/resources/otf/FoglihtenNo07.otf"
    pending("Font fixture not found: #{otf_path}") unless File.exists?(otf_path)

    bytes = File.read(otf_path).to_slice
    font_descriptor = Pdfbox::Cos::Dictionary.new
    font_descriptor[Pdfbox::Cos::Name::FONT_FILE3] = Pdfbox::Cos::Stream.new(data: bytes)

    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name.new("Type1")
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new("FoglihtenNo07")
    dict[Pdfbox::Cos::Name::FONT_DESC] = font_descriptor
    dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name::WIN_ANSI_ENCODING

    font = Pdfbox::Pdmodel::Font::PDType1CFont.new(dict)

    font.embedded?.should be_true
    font.damaged?.should be_false
    font.cff_type1_font.should_not be_nil
    font.font_box_font.should eq(font.cff_type1_font)
    font.width_from_font(0x41).should be > 0.0_f32
    font.height(0x41).should be > 0.0_f32
    font.has_glyph?(font.encoding.get_name(0x41)).should be_true
    font.get_path(0x41).empty?.should be_false
    font.get_normalized_path(0x41).empty?.should be_false
    font.get_string_width("A").should be > 0.0_f32
    font.average_font_width.should eq(500.0_f32)
    font.base_font.should eq("FoglihtenNo07")
    font.name.should eq("FoglihtenNo07")
    font.read_code(IO::Memory.new(Bytes[0x41_u8])).should eq(0x41)
  end
end

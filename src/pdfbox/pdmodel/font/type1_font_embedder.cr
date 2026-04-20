require "./encoding/type1_encoding"
require "./encoding/glyph_list"
require "../../../fontbox/pfb/pfb_parser"
require "../../../fontbox/type1/type1_font"
require "../common/pdstream"
require "../common/pdrectangle"

class Pdfbox::Pdmodel::Font::PDType1FontEmbedder
  getter font_encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding
  getter type1_font : Fontbox::Type1::Type1Font

  def initialize(doc : Pdfbox::Pdmodel::PDDocument, dict : Pdfbox::Cos::Dictionary, pfb_stream : ::IO,
                 encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding?)
    dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE1

    pfb_bytes = pfb_stream.getb_to_end
    pfb_parser = Fontbox::Pfb::PfbParser.new(pfb_bytes)
    @type1_font = Fontbox::Type1::Type1Font.create_with_pfb(pfb_bytes)
    @font_encoding = encoding || Pdfbox::Pdmodel::Font::Encoding::Type1Encoding.new

    descriptor = self.class.build_font_descriptor(@type1_font)
    font_stream = Pdfbox::Pdmodel::Common::PDStream.new(doc.document)
    output = font_stream.create_output_stream(Pdfbox::Cos::Name::FLATE_DECODE)
    output.write(pfb_bytes)
    output.close
    font_stream.cos_object[Pdfbox::Cos::Name::LENGTH] = Pdfbox::Cos::Integer.new(pfb_bytes.size)
    pfb_parser.lengths.each_with_index do |length, index|
      font_stream.cos_object[Pdfbox::Cos::Name.new("Length#{index + 1}")] = Pdfbox::Cos::Integer.new(length)
    end
    descriptor.font_file = font_stream

    dict[Pdfbox::Cos::Name::FONT_DESC] = descriptor.cos_object
    dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new(@type1_font.name)
    dict[Pdfbox::Cos::Name::FIRST_CHAR] = Pdfbox::Cos::Integer.new(0)
    dict[Pdfbox::Cos::Name::LAST_CHAR] = Pdfbox::Cos::Integer.new(255)
    dict[Pdfbox::Cos::Name::WIDTHS] = Pdfbox::Cos::Array.new(
      (0..255).map do |code|
        Pdfbox::Cos::Integer.new(@type1_font.width(@font_encoding.get_name(code)).round.to_i)
      end
    )
    unless @font_encoding.is_a?(Pdfbox::Pdmodel::Font::Encoding::Type1Encoding)
      dict[Pdfbox::Cos::Name::ENCODING] = @font_encoding.cos_object
    end
  end

  def glyph_list : Pdfbox::Pdmodel::Font::GlyphList
    Pdfbox::Pdmodel::Font::GlyphList.adobe_glyph_list
  end

  def self.build_font_descriptor(type1 : Fontbox::Type1::Type1Font) : Pdfbox::Pdmodel::Font::PDFontDescriptor
    descriptor = Pdfbox::Pdmodel::Font::PDFontDescriptor.new
    descriptor.font_name = type1.name
    descriptor.font_family = type1.family_name unless type1.family_name.empty?
    descriptor.non_symbolic = true
    descriptor.symbolic = false
    descriptor.fixed_pitch = type1.fixed_pitch?
    descriptor.italic = type1.italic_angle != 0.0_f32
    descriptor.force_bold = type1.force_bold?
    descriptor.font_bounding_box = Pdfbox::Pdmodel::Common::PDRectangle.new(
      type1.font_bbox.lower_left_x.to_f32,
      type1.font_bbox.lower_left_y.to_f32,
      (type1.font_bbox.upper_right_x - type1.font_bbox.lower_left_x).to_f32,
      (type1.font_bbox.upper_right_y - type1.font_bbox.lower_left_y).to_f32
    )
    descriptor.italic_angle = type1.italic_angle
    descriptor.ascent = type1.font_bbox.upper_right_y.to_f32
    descriptor.descent = type1.font_bbox.lower_left_y.to_f32
    descriptor.cap_height = (type1.blue_values[2]? || type1.font_bbox.upper_right_y).to_f32
    descriptor.stem_v = 0.0_f32
    descriptor
  end

  def self.build_font_descriptor(afm : Pdfbox::Pdmodel::Font::PDFont::FontMetrics) : Pdfbox::Pdmodel::Font::PDFontDescriptor
    descriptor = Pdfbox::Pdmodel::Font::PDFontDescriptor.new
    descriptor.average_width = afm.average_character_width
    descriptor.stem_v = 0.0_f32
    descriptor
  end
end

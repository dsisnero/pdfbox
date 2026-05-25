# Type 1 font implementation
# Corresponds to PDType1Font in Apache PDFBox
require "./encoding"
require "./encoding/glyph_list"
require "./encoding/win_ansi_encoding"
require "./encoding/symbol_encoding"
require "./encoding/zapf_dingbats_encoding"
require "./standard14_fonts"
require "./font_mapper"
require "./type1_font_embedder"
require "./encoding/type1_encoding"
require "../../../fontbox/type1/type1_font"
require "../../../fontbox/pfb/pfb_parser"
require "../common/pdstream"
require "../common/pdrectangle"

class Pdfbox::Pdmodel::Font::PDType1Font < Pdfbox::Pdmodel::Font::PDSimpleFont
  include PDVectorFont

  Log = ::Log.for(self)
  Cos = Pdfbox::Cos

  alias PDDocument = Pdfbox::Pdmodel::PDDocument

  class AffineTransform
    getter a : Float32
    getter b : Float32
    getter c : Float32
    getter d : Float32
    getter e : Float32
    getter f : Float32

    def initialize(@a : Float32, @b : Float32, @c : Float32, @d : Float32, @e : Float32, @f : Float32)
    end

    def self.from_font_matrix(matrix : Matrix) : AffineTransform
      # Create affine transform from matrix and scale by 1000 as in Java PDFBox
      transform = new(matrix.a, matrix.b, matrix.c, matrix.d, matrix.e, matrix.f)
      transform.scale(1000.0_f32, 1000.0_f32)
      transform
    end

    def scale(sx : Float32, sy : Float32) : Nil
      @a *= sx
      @b *= sy
      @c *= sx
      @d *= sy
      @e *= sx
      @f *= sy
    end

    def transform(x : Float32, y : Float32) : Tuple(Float32, Float32)
      # x' = a*x + c*y + e
      # y' = b*x + d*y + f
      new_x = @a * x + @c * y + @e
      new_y = @b * x + @d * y + @f
      {new_x, new_y}
    end
  end

  # Constants
  # alternative names for glyphs which are commonly encountered
  ALT_NAMES = {
    "ff"       => "f_f",
    "ffi"      => "f_f_i",
    "ffl"      => "f_f_l",
    "fi"       => "f_i",
    "fl"       => "f_l",
    "st"       => "s_t",
    "IJ"       => "I_J",
    "ij"       => "i_j",
    "ellipsis" => "elipsis", # misspelled in ArialMT
  }

  PFB_START_MARKER = 0x80

  # Instance variables
  @type1font : Fontbox::Type1::Type1Font?
  @generic_font : Fontbox::FontBoxFont?
  @is_embedded : Bool
  @is_damaged : Bool
  @font_matrix_transform : AffineTransform?
  @code_to_bytes_map : Hash(Int32, Bytes)
  @font_matrix : Matrix?
  @font_bbox : BoundingBox?
  @standard14 : Bool = false
  @afm_standard14 : PDFont::FontMetrics?

  # FontBBox values from AFM files for Standard 14 fonts.
  # Extracted from vendor/pdfbox/pdfbox/target/classes/org/apache/pdfbox/resources/afm/
  STANDARD14_FONT_BBOX = {
    "Helvetica"             => {-166_f32, -225_f32, 1000_f32, 931_f32},
    "Helvetica-Bold"        => {-170_f32, -228_f32, 1003_f32, 962_f32},
    "Helvetica-Oblique"     => {-170_f32, -225_f32, 1116_f32, 931_f32},
    "Helvetica-BoldOblique" => {-174_f32, -228_f32, 1114_f32, 962_f32},
    "Courier"               => {-23_f32, -250_f32, 715_f32, 805_f32},
    "Courier-Bold"          => {-113_f32, -250_f32, 749_f32, 801_f32},
    "Courier-Oblique"       => {-27_f32, -250_f32, 849_f32, 805_f32},
    "Courier-BoldOblique"   => {-57_f32, -250_f32, 869_f32, 801_f32},
    "Times-Roman"           => {-168_f32, -218_f32, 1000_f32, 898_f32},
    "Times-Bold"            => {-168_f32, -218_f32, 1000_f32, 935_f32},
    "Times-Italic"          => {-169_f32, -217_f32, 1010_f32, 883_f32},
    "Times-BoldItalic"      => {-200_f32, -218_f32, 996_f32, 921_f32},
    "Symbol"                => {-180_f32, -293_f32, 1090_f32, 1010_f32},
    "ZapfDingbats"          => {-1_f32, -143_f32, 981_f32, 820_f32},
  } of String => {Float32, Float32, Float32, Float32}

  # Constructor for Standard 14 fonts
  def initialize(base_font : Standard14Fonts::FontName)
    super(base_font)
    @standard14 = true
    @afm_standard14 = Standard14Fonts.get_afm(base_font.to_s)

    @dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE1
    @dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new(base_font.to_s)
    @dict[Pdfbox::Cos::Name::FONT_DESC] = build_standard14_font_descriptor(base_font).cos_object

    case base_font
    when Standard14Fonts::FontName::ZAPF_DINGBATS
      @encoding = Pdfbox::Pdmodel::Font::Encoding::ZapfDingbatsEncoding::INSTANCE
      @dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name.new("ZapfDingbatsEncoding")
    when Standard14Fonts::FontName::SYMBOL
      @encoding = Pdfbox::Pdmodel::Font::Encoding::SymbolEncoding::INSTANCE
      @dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name.new("SymbolEncoding")
    else
      @encoding = Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding::INSTANCE
      @dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name::WIN_ANSI_ENCODING
    end

    # Load FontBBox from AFM data for Standard 14 fonts
    if bbox = STANDARD14_FONT_BBOX[base_font.to_s]?
      @font_bbox = BoundingBox.new(bbox[0], bbox[1], bbox[2], bbox[3])
    end

    # todo: could load the PFB font here if we wanted to support Standard 14 embedding
    @type1font = nil
    mapping = FontMappers.instance.get_font_box_font(get_base_font, font_descriptor)
    @generic_font = mapping.font

    if mapping.fallback?
      font_name = begin
        @generic_font.try(&.name) || "?"
      rescue
        Log.debug { "Couldn't get font name - setting to '?'" }
        "?"
      end
      Log.warn { "Using fallback font #{font_name} for base font #{get_base_font}" }
    end

    @is_embedded = false
    @is_damaged = false
    @font_matrix_transform = AffineTransform.from_font_matrix(font_matrix)
    @code_to_bytes_map = Hash(Int32, Bytes).new
  end

  # Constructor for embedding (placeholder)
  def initialize(doc : PDDocument, pfb_in : ::IO)
    initialize(doc, pfb_in, nil)
  end

  # Constructor with encoding (placeholder)
  def initialize(doc : PDDocument, pfb_in : ::IO, encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding?)
    super() # embedding constructor
    @standard14 = false
    embedder = Pdfbox::Pdmodel::Font::PDType1FontEmbedder.new(doc, @dict, pfb_in, encoding)
    type1 = embedder.type1_font
    @type1font = type1
    @generic_font = type1
    @is_embedded = true
    @is_damaged = false
    @font_matrix = matrix_from_type1(type1)
    @font_bbox = bounding_box_from_type1(type1)
    @font_matrix_transform = AffineTransform.from_font_matrix(font_matrix)
    @code_to_bytes_map = Hash(Int32, Bytes).new
    @encoding = embedder.font_encoding
    assign_glyph_list(Standard14Fonts.get_mapped_font_name(type1.name))
  end

  # Constructor from font dictionary
  def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    super(font_dictionary)
    @standard14 = false
    @type1font = nil
    @generic_font = nil
    @is_embedded = false
    @is_damaged = false
    @font_matrix_transform = nil
    @code_to_bytes_map = Hash(Int32, Bytes).new
    @font_matrix = nil
    @font_bbox = nil

    # Try to determine if this is a Standard 14 font
    base_font = get_base_font
    standard14_name = Standard14Fonts.get_mapped_font_name(base_font)
    if standard14_name.is_a?(Standard14Fonts::FontName)
      @standard14 = true
      @afm_standard14 = Standard14Fonts.get_afm(standard14_name.to_s)
    else
      @standard14 = false
    end

    parse_embedded_type1

    # Set up encoding
    if base_font.includes?("ZapfDingbats")
      @encoding = Encoding::ZapfDingbatsEncoding::INSTANCE
    elsif base_font == "Symbol"
      @encoding = Encoding::SymbolEncoding::INSTANCE
    else
      @encoding = Encoding::WinAnsiEncoding::INSTANCE
    end

    # Assign glyph list
    assign_glyph_list(standard14_name)

    # Create font matrix transform
    @font_matrix_transform = AffineTransform.from_font_matrix(font_matrix)
  end

  # Abstract method implementations

  def standard14? : Bool
    @standard14
  end

  protected def get_standard14_width(code : Int32) : Float32
    afm = get_standard14_afm
    if afm
      name_in_afm = encoding.get_name(code)

      if name_in_afm == ".notdef"
        return 250.0_f32
      end

      if name_in_afm == "nbspace"
        name_in_afm = "space"
      elsif name_in_afm == "sfthyphen"
        name_in_afm = "hyphen"
      end

      return afm.character_width(name_in_afm)
    end
    raise "No AFM"
  end

  protected def read_encoding_from_font : Pdfbox::Pdmodel::Font::Encoding::Encoding
    return Encoding::Type1Encoding.new if @type1font
    Encoding::StandardEncoding::INSTANCE
  end

  private def build_standard14_font_descriptor(base_font : Standard14Fonts::FontName) : PDFontDescriptor
    descriptor = PDFontDescriptor.new(Pdfbox::Cos::Dictionary.new)
    name = base_font.to_s
    descriptor.font_name = name
    descriptor.italic = name.includes?("Italic") || name.includes?("Oblique")
    descriptor.force_bold = name.includes?("Bold")
    descriptor
  end

  def get_path(name : String)
    return Fontbox::Util::Path.new if name == ".notdef" && !embedded?

    if standard14?
      mapped_name = Standard14Fonts.get_mapped_font_name(self.name) || Standard14Fonts::FontName.new(self.name)
      return Standard14Fonts.get_glyph_path(mapped_name, name)
    end

    if type1font = @type1font
      return type1font.path(name)
    end

    if generic_font = @generic_font
      return generic_font.path(name)
    end

    Fontbox::Util::Path.new
  end

  def has_glyph?(name : String) : Bool
    return !get_path(name).empty? if standard14?
    if type1font = @type1font
      return type1font.has_glyph?(name)
    end
    if generic_font = @generic_font
      return generic_font.has_glyph?(name)
    end
    false
  end

  def font_box_font
    @generic_font
  end

  # PDFont abstract method implementations

  def name : String
    base_font = get_base_font
    base_font.empty? ? "Unknown" : base_font
  end

  def font_matrix : Matrix
    if @font_matrix.nil?
      @font_matrix = matrix_from_font_box_font || DEFAULT_FONT_MATRIX
    end
    @font_matrix.not_nil! # ameba:disable Lint/NotNil
  end

  def bounding_box : BoundingBox
    @font_bbox ||= bounding_box_from_font_box_font || BoundingBox.new
  end

  def position_vector(code : Int32) : Vector
    Vector.new(0.0_f32, 0.0_f32)
  end

  def width(code : Int32) : Float32
    if has_explicit_width?(code)
      first_char = @dict[Pdfbox::Cos::Name::FIRST_CHAR]?.try(&.as_i) || 0
      idx = code - first_char
      if idx >= 0 && idx < widths.size
        return widths[idx]
      end
    end

    if standard14?
      return get_standard14_width(code)
    end

    if type1font = @type1font
      glyph_name = encoding.get_name(code)
      return type1font.width(glyph_name)
    end

    0.0_f32
  end

  def height(code : Int32) : Float32
    return 0.0_f32 if damaged?
    bbox = bounding_box
    return 0.0_f32 if bbox.height == 0.0_f32
    bbox.height / 1000.0_f32
  end

  private def transform_width(width : Float32) : Float32
    if transform = @font_matrix_transform
      x, _ = transform.transform(width, 0.0_f32)
      x
    else
      width
    end
  end

  def width_from_font(code : Int32) : Float32
    name = encoding.get_name(code)

    # width of .notdef is ignored for substitutes, see PDFBOX-1900
    if !embedded? && name == ".notdef"
      return 250.0_f32
    end

    width = if standard14?
              get_standard14_width(code)
            elsif type1font = @type1font
              type1font.width(name)
            else
              0.0_f32
            end

    transform_width(width)
  end

  def embedded? : Bool
    @is_embedded
  end

  def damaged? : Bool
    @is_damaged
  end

  def average_font_width : Float32
    if afm = get_standard14_afm
      return afm.average_character_width
    end
    # Use WIDTHS array from dict if available, matching Java PDSimpleFont
    if widths = @dict[Pdfbox::Cos::Name::WIDTHS]?.try(&.as?(Pdfbox::Cos::Array))
      total = 0.0_f64; count = 0
      widths.items.each do |base|
        if base.is_a?(Pdfbox::Cos::Number) && base.value.to_f64 > 0
          total += base.value.to_f64; count += 1
        end
      end
      return (total / count).to_f32 if count > 0 && total > 0
    end
    500.0_f32
  end

  def encode(unicode : Int32) : Bytes
    if cached = @code_to_bytes_map[unicode]?
      return cached
    end

    glyph_list = if standard14? && get_base_font.includes?("ZapfDingbats")
                   GlyphList.zapf_dingbats
                 else
                   GlyphList.adobe_glyph_list
                 end

    name = glyph_list.code_point_to_name(unicode)
    name = ALT_NAMES[name]? || name

    if standard14?
      unless encoding.contains(name)
        raise ArgumentError.new(
          "U+#{unicode.to_s(16).upcase.rjust(4, '0')} ('#{name}') is not available in the font #{name()}, encoding: #{encoding.encoding_name}"
        )
      end
      if name == ".notdef"
        raise ArgumentError.new(
          "No glyph for U+#{unicode.to_s(16).upcase.rjust(4, '0')} in the font #{name()}"
        )
      end
    else
      # Port of Java PDType1Font non-standard14 encode validation
      unless encoding.contains(name)
        raise ArgumentError.new(
          "U+#{unicode.to_s(16).upcase.rjust(4, '0')} ('#{name}') is not available in the font #{name()}, encoding: #{encoding.encoding_name}"
        )
      end

      # Port of Java getNameInFont: find the actual font name for this glyph
      name_in_font = name
      unless embedded? || has_glyph?(name)
        # Try ALT_NAMES
        alt = ALT_NAMES[name]?
        if alt && alt != ".notdef" && has_glyph?(alt)
          name_in_font = alt
        else
          # Try "uniXXXX" name from Unicode codepoint
          unicode_str = glyph_list.to_unicode(name)
          if unicode_str && unicode_str.size == 1
            cp = unicode_str[0].ord
            uni_name = "uni#{cp.to_s(16).upcase.rjust(4, '0')}"
            name_in_font = uni_name if has_glyph?(uni_name)
          end
        end
      end

      if name_in_font == ".notdef" || !has_glyph?(name_in_font)
        raise ArgumentError.new(
          "No glyph for U+#{unicode.to_s(16).upcase.rjust(4, '0')} in the font #{name()}"
        )
      end
    end

    code = encoding.get_code(name)
    if code == -1
      generic_name = begin
        @generic_font.try(&.name) || "?"
      rescue
        "?"
      end
      raise ArgumentError.new(
        "U+#{unicode.to_s(16).upcase.rjust(4, '0')} ('#{name}') is not available in the font #{name()} (generic: #{generic_name}), encoding: #{encoding.encoding_name}"
      )
    end

    bytes = Bytes.new(1)
    bytes[0] = code.to_u8
    @code_to_bytes_map[unicode] = bytes
    bytes
  end

  def read_code(input : ::IO) : Int32
    # Simple fonts use 1-byte codes
    byte = input.read_byte
    byte ? byte.to_i32 : -1
  end

  # PDVectorFont interface implementation

  def get_path(code : Int32)
    get_path(encoding.get_name(code))
  end

  def get_normalized_path(code : Int32)
    path = get_path(code)
    path.empty? ? get_path(".notdef") : path
  end

  def has_glyph(code : Int32) : Bool
    encoding.get_name(code) != ".notdef"
  end

  # Helper methods

  private def get_base_font : String
    base_font_obj = @dict[Pdfbox::Cos::Name::BASE_FONT]?
    if base_font_obj.is_a?(Pdfbox::Cos::Name)
      base_font_obj.value
    else
      ""
    end
  end

  private def parse_embedded_type1 : Nil
    fd = font_descriptor

    if fd
      if font_file = fd.font_file
        begin
          bytes = font_file.to_byte_array
          if bytes.size >= 2 && bytes[0] == PFB_START_MARKER.to_u8
            @type1font = Fontbox::Type1::Type1Font.create_with_pfb(bytes)
          end
        rescue ex
          Log.warn { "Can't read embedded Type1 font #{fd.font_name}: #{ex.message}" }
          @is_damaged = true
        end
      elsif fd.font_file3
        Log.warn { "/FontFile3 for Type1 font not supported" }
      end
    end

    if @type1font
      @generic_font = @type1font
      @is_embedded = true
      if type1font = @type1font
        @font_matrix = matrix_from_type1(type1font)
        @font_bbox = bounding_box_from_type1(type1font)
      end
    else
      mapping = FontMappers.instance.get_font_box_font(get_base_font, fd)
      @generic_font = mapping.font
    end
  end

  private def matrix_from_font_box_font : Matrix?
    if type1font = @type1font
      return matrix_from_type1(type1font)
    end
    nil
  end

  private def bounding_box_from_font_box_font : BoundingBox?
    if type1font = @type1font
      return bounding_box_from_type1(type1font)
    end
    if generic_font = @generic_font
      bbox = generic_font.font_bbox
      return BoundingBox.new(
        bbox.lower_left_x.to_f32,
        bbox.lower_left_y.to_f32,
        bbox.upper_right_x.to_f32,
        bbox.upper_right_y.to_f32
      )
    end
    nil
  end

  private def matrix_from_type1(type1 : Fontbox::Type1::Type1Font) : Matrix
    values = type1.font_matrix
    if values.size >= 6
      Matrix.new(values[0], values[1], values[2], values[3], values[4], values[5])
    else
      DEFAULT_FONT_MATRIX
    end
  end

  private def bounding_box_from_type1(type1 : Fontbox::Type1::Type1Font) : BoundingBox
    bbox = type1.font_bbox
    BoundingBox.new(
      bbox.lower_left_x.to_f32,
      bbox.lower_left_y.to_f32,
      bbox.upper_right_x.to_f32,
      bbox.upper_right_y.to_f32
    )
  end

  private def build_embedded_font_descriptor(type1 : Fontbox::Type1::Type1Font) : PDFontDescriptor
    descriptor = PDFontDescriptor.new(Pdfbox::Cos::Dictionary.new)
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

  private def build_pfb_stream(doc : PDDocument, pfb_parser : Fontbox::Pfb::PfbParser, pfb_bytes : Bytes) : Pdfbox::Pdmodel::Common::PDStream
    stream = Pdfbox::Pdmodel::Common::PDStream.new(doc.document)
    output = stream.create_output_stream(Pdfbox::Cos::Name::FLATE_DECODE)
    output.write(pfb_bytes)
    output.close
    stream.cos_object[Pdfbox::Cos::Name::LENGTH] = Pdfbox::Cos::Integer.new(pfb_bytes.size)
    pfb_parser.lengths.each_with_index do |length, index|
      stream.cos_object[Pdfbox::Cos::Name.new("Length#{index + 1}")] = Pdfbox::Cos::Integer.new(length)
    end
    stream
  end

  private def build_embedded_widths(type1 : Fontbox::Type1::Type1Font, encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding) : Pdfbox::Cos::Array
    widths = Pdfbox::Cos::Array.new
    (0..255).each do |code|
      widths.add(Pdfbox::Cos::Integer.new(type1.width(encoding.get_name(code)).round.to_i))
    end
    widths
  end

  # TODO: Add remaining methods from Java PDType1Font
end

# Type 1 font implementation
# Corresponds to PDType1Font in Apache PDFBox
require "./encoding"
require "./encoding/glyph_list"
require "./encoding/win_ansi_encoding"
require "./encoding/symbol_encoding"
require "./encoding/zapf_dingbats_encoding"
require "./standard14_fonts"

class Pdfbox::Pdmodel::Font::PDType1Font < Pdfbox::Pdmodel::Font::PDSimpleFont
  include PDVectorFont

  Log = ::Log.for(self)
  Cos = Pdfbox::Cos

  # Placeholder types for missing dependencies
  class Type1Font
  end

  class PDDocument
    # Placeholder for PDDocument
  end

  class FontBoxFont
    def name : String
      "?"
    end

    def has_glyph?(name : String) : Bool
      false
    end

    def get_width(name : String) : Float32
      0.0_f32
    end

    def get_path(name : String)
      # Returns GeneralPath placeholder
      nil
    end
  end

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

  class FontMapping(T)
    getter font : T
    @fallback : Bool

    def initialize(@font : T, @fallback : Bool)
    end

    def fallback? : Bool
      @fallback
    end
  end

  class FontMappers
    def self.instance
      FontMappers.new
    end

    def get_font_box_font(base_font : String, font_descriptor)
      FontMapping(FontBoxFont).new(FontBoxFont.new, false)
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
  @type1font : Type1Font?
  @generic_font : FontBoxFont?
  @is_embedded : Bool
  @is_damaged : Bool
  @font_matrix_transform : AffineTransform?
  @code_to_bytes_map : Hash(Int32, Bytes)
  @font_matrix : Matrix?
  @font_bbox : BoundingBox?
  @standard14 : Bool = false

  # Constructor for Standard 14 fonts
  def initialize(base_font : Standard14Fonts::FontName)
    super(base_font)
    @standard14 = true
    @afm_standard14 = Standard14Fonts.get_afm(base_font.to_s)

    @dict[Pdfbox::Cos::Name::SUBTYPE] = Pdfbox::Cos::Name::TYPE1
    @dict[Pdfbox::Cos::Name::BASE_FONT] = Pdfbox::Cos::Name.new(base_font.to_s)

    case base_font
    when Standard14Fonts::FontName::ZAPF_DINGBATS
      @encoding = Encoding::ZapfDingbatsEncoding::INSTANCE
    when Standard14Fonts::FontName::SYMBOL
      @encoding = Encoding::SymbolEncoding::INSTANCE
    else
      @encoding = WinAnsiEncoding::INSTANCE
      @dict[Pdfbox::Cos::Name::ENCODING] = Pdfbox::Cos::Name::WIN_ANSI_ENCODING
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
  protected def initialize(doc : PDDocument, pfb_in : IO)
    super() # embedding constructor
    @standard14 = false
    @type1font = nil
    @generic_font = nil
    @is_embedded = true
    @is_damaged = false
    @font_matrix_transform = nil
    @code_to_bytes_map = Hash(Int32, Bytes).new
    @font_matrix = nil
    @font_bbox = nil
    raise "Not implemented"
  end

  # Constructor with encoding (placeholder)
  protected def initialize(doc : PDDocument, pfb_in : IO, encoding : Encoding)
    super() # embedding constructor
    @standard14 = false
    @type1font = nil
    @generic_font = nil
    @is_embedded = true
    @is_damaged = false
    @font_matrix_transform = nil
    @code_to_bytes_map = Hash(Int32, Bytes).new
    @font_matrix = nil
    @font_bbox = nil
    raise "Not implemented"
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
    # TODO: Implement font loading from dictionary
    raise "Not implemented"
  end

  # Abstract method implementations

  def standard14? : Bool
    @standard14
  end

  protected def read_encoding_from_font : Encoding
    # TODO: Implement encoding extraction from font file
    Encoding::StandardEncoding::INSTANCE
  end

  def get_path(name : String)
    # TODO: Return GeneralPath type
    nil
  end

  def has_glyph?(name : String) : Bool
    @generic_font.try(&.has_glyph?(name)) || false
  end

  def font_box_font
    @generic_font
  end

  # PDFont abstract method implementations

  def name : String
    @dict[Pdfbox::Cos::Name::BASE_FONT]?.try(&.to_s) || "Unknown"
  end

  def font_matrix : Matrix
    if @font_matrix.nil?
      # TODO: Try to get from generic_font
      @font_matrix = DEFAULT_FONT_MATRIX
    end
    @font_matrix.not_nil! # ameba:disable Lint/NotNil
  end

  def bounding_box : BoundingBox
    @font_bbox ||= BoundingBox.new # TODO: Generate bounding box
  end

  def position_vector(code : Int32) : Vector
    Vector.new # TODO: Implement
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

    # TODO: Get width from font
    0.0_f32
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

    width = if generic_font = @generic_font
              generic_font.get_width(name)
            else
              get_standard14_width(code)
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
      afm.average_character_width
    else
      0.0_f32
    end
  end

  protected def encode(unicode : Int32) : Bytes
    # Check cache
    if cached = @code_to_bytes_map[unicode]?
      return cached
    end

    # Get glyph list based on font type
    glyph_list = if standard14? && get_base_font.includes?("ZapfDingbats")
                   GlyphList.zapf_dingbats
                 else
                   GlyphList.adobe_glyph_list
                 end

    # Get glyph name from Unicode
    name = glyph_list.to_glyph_name(unicode)
    if name == ".notdef"
      # Try to get from Adobe Glyph List as fallback
      name = GlyphList.adobe_glyph_list.to_glyph_name(unicode)
    end

    # Apply alternative name mapping
    name = ALT_NAMES[name]? || name

    # Get code from encoding
    code = encoding.get_code(name)
    if code == -1
      # Fallback to .notdef
      code = encoding.get_code(".notdef")
      if code == -1
        code = 0
      end
    end

    # Create bytes (simple fonts use 1-byte codes)
    bytes = Bytes.new(1)
    bytes[0] = code.to_u8
    @code_to_bytes_map[unicode] = bytes
    bytes
  end

  def read_code(input : ::IO) : Int32
    # Simple fonts use 1-byte codes
    input.read_byte || -1
  end

  # PDVectorFont interface implementation

  def get_path(code : Int32)
    # TODO: Implement glyph path for code
    nil
  end

  def get_normalized_path(code : Int32)
    # TODO: Implement normalized path
    nil
  end

  def has_glyph(code : Int32) : Bool
    # TODO: Implement
    false
  end

  # Helper methods

  private def get_base_font : String
    @dict[Pdfbox::Cos::Name::BASE_FONT]?.try(&.to_s) || ""
  end

  # TODO: Add remaining methods from Java PDType1Font
end

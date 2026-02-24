# TrueType font implementation
# Corresponds to PDTrueTypeFont in Apache PDFBox
require "./encoding"
require "./encoding/glyph_list"
require "./encoding/win_ansi_encoding"
require "./encoding/symbol_encoding"
require "./encoding/zapf_dingbats_encoding"
require "./standard14_fonts"
require "../../../fontbox/ttf/true_type_font"
require "../../../fontbox/ttf/ttf_tables"
require "../../../fontbox/ttf/ttf_parser"

class Pdfbox::Pdmodel::Font::PDTrueTypeFont < Pdfbox::Pdmodel::Font::PDSimpleFont
  include PDVectorFont

  Log = ::Log.for(self)
  Cos = Pdfbox::Cos

  # Placeholder types for missing dependencies
  class OpenTypeFont
  end

  class PDDocument
    # Placeholder for PDDocument
  end

  class PDStream
    def initialize(dict : Cos::Dictionary); end

    def cos_object : Cos::Dictionary
      Cos::Dictionary.new
    end

    def create_view
      RandomAccessRead.new
    end
  end

  class RandomAccessRead
    def read(bytes : Bytes, offset : Int32, length : Int32) : Int32
      0
    end

    def seek(pos : Int64) : Nil; end

    def close : Nil; end
  end

  class RandomAccessReadBuffer
    def self.create_buffer_from_stream(io : IO) : RandomAccessRead
      RandomAccessRead.new
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

    def get_true_type_font(base_font : String, font_descriptor)
      FontMapping(Fontbox::TTF::TrueTypeFont).new(Fontbox::TTF::TrueTypeFont.new(nil), false)
    end
  end

  class PDTrueTypeFontEmbedder
    def initialize(doc : PDDocument, dict : Cos::Dictionary, ttf : Fontbox::TTF::TrueTypeFont, encoding : Encoding)
    end

    def font_descriptor : PDFontDescriptor
      PDFontDescriptor.new(Cos::Dictionary.new)
    end
  end

  # Constants
  START_RANGE_F000 = 0xF000
  START_RANGE_F100 = 0xF100
  START_RANGE_F200 = 0xF200

  # Instance variables
  @ttf : Fontbox::TTF::TrueTypeFont?
  @otf : OpenTypeFont?
  @is_embedded : Bool
  @is_damaged : Bool
  @cmap_win_unicode : Fontbox::TTF::CmapSubtable?
  @cmap_win_symbol : Fontbox::TTF::CmapSubtable?
  @cmap_mac_roman : Fontbox::TTF::CmapSubtable?
  @cmap_initialized : Bool = false
  @gid_to_code : Hash(Int32, Int32) = Hash(Int32, Int32).new
  @font_bbox : Util::BoundingBox?
  @inverted_macos_roman : Hash(String, Int32) = Hash(String, Int32).new

  # Constructor for Standard 14 fonts
  def initialize(base_font : Standard14Fonts::FontName)
    super(base_font)
    # Standard 14 fonts are Type 1, not TrueType
    # So this constructor likely shouldn't be used
    @ttf = nil
    @otf = nil
    @is_embedded = false
    @is_damaged = false
    read_encoding
  end

  # Constructor from font dictionary
  def initialize(font_dictionary : Cos::Dictionary)
    super(font_dictionary)

    ttf_font = nil
    font_is_damaged = false

    # Check for embedded font in font descriptor
    fd = font_descriptor
    if fd
      # TODO: Implement embedded font loading from FontFile2 stream
      # For now, just set as not embedded
    end

    @is_embedded = !ttf_font.nil?
    @is_damaged = font_is_damaged

    # Substitute with system font if not embedded
    if ttf_font.nil?
      mapping = FontMappers.instance.get_true_type_font(get_base_font, fd)
      ttf_font = mapping.font

      if mapping.fallback?
        font_name = begin
          ttf_font.try(&.name) || "?"
        rescue
          "?"
        end
        Log.warn { "Using fallback font #{font_name} for base font #{get_base_font}" }
      end
    end

    @ttf = ttf_font
    @otf = ttf_font.is_a?(OpenTypeFont) && ttf_font.is_supported_otf? ? ttf_font : nil

    read_encoding
  end

  # Constructor for embedding (placeholder)
  protected def initialize(doc : PDDocument, ttf : Fontbox::TTF::TrueTypeFont, encoding : Encoding, close_ttf : Bool)
    super() # embedding constructor
    @ttf = ttf
    @otf = ttf.is_a?(OpenTypeFont) && ttf.is_supported_otf? ? ttf : nil
    @is_embedded = true
    @is_damaged = false
    @encoding = encoding
    # TODO: Implement PDTrueTypeFontEmbedder
    embedder = PDTrueTypeFontEmbedder.new(doc, @dict, ttf, encoding)
    # set_font_descriptor(embedder.font_descriptor)
    if close_ttf
      ttf.close
    end
    read_encoding
  end

  # Abstract method implementations

  protected def read_encoding_from_font : Encoding
    if !embedded? && (afm = get_standard14_afm)
      # read from AFM
      return Type1Encoding.new(afm)
    else
      # non-symbolic fonts don't have a built-in encoding per se, but their encoding is
      # assumed to be StandardEncoding by the PDF spec unless an explicit Encoding is present
      # which will override this anyway
      if symbolic_flag == false
        return StandardEncoding::INSTANCE
      end

      # normalise the standard 14 name, e.g "Symbol,Italic" -> "Symbol"
      standard14_name = Standard14Fonts.get_mapped_font_name(name)

      # likewise, if the font is standard 14 then we know it's Standard Encoding
      if standard14? && standard14_name != FontName::SYMBOL && standard14_name != FontName::ZAPF_DINGBATS
        return StandardEncoding::INSTANCE
      end

      # synthesize an encoding, so that getEncoding() is always usable
      post = @ttf.try(&.postscript)
      code_to_name = Hash(Int32, String).new

      (0..256).each do |code|
        gid = code_to_gid(code)
        if gid > 0
          name = nil
          if post
            name = post.get_name(gid)
          end
          if name.nil?
            # GID pseudo-name
            name = gid.to_s
          end
          code_to_name[code] = name
        end
      end

      return BuiltInEncoding.new(code_to_name)
    end
  end

  def get_path(name : String)
    # TODO: Return GeneralPath type
    nil
  end

  def has_glyph?(name : String) : Bool
    ttf = @ttf
    return false if ttf.nil?

    gid = ttf.name_to_gid(name)
    !(gid == 0 || gid >= ttf.number_of_glyphs)
  end

  def font_box_font
    @ttf
  end

  # PDFont abstract method implementations

  def name : String
    @dict[Cos::Name::BASE_FONT]?.try(&.to_s) || "Unknown"
  end

  def font_matrix : Matrix
    # TODO: Try to get from ttf
    DEFAULT_FONT_MATRIX
  end

  def bounding_box : Util::BoundingBox
    @font_bbox ||= Util::BoundingBox.new # TODO: Generate bounding box
  end

  def position_vector(code : Int32) : Vector
    Vector.new # TODO: Implement
  end

  def width(code : Int32) : Float32
    if has_explicit_width?(code)
      first_char = @dict[Cos::Name::FIRST_CHAR]?.try(&.as_i) || 0
      idx = code - first_char
      if idx >= 0 && idx < widths.size
        return widths[idx]
      end
    end

    # TODO: Get width from font
    0.0_f32
  end

  def width_from_font(code : Int32) : Float32
    gid = code_to_gid(code)
    return 0.0_f32 if gid == 0

    if ttf = @ttf
      width = if hm = ttf.horizontal_metrics
                hm.advance_width(gid).to_f32
              else
                0.0_f32
              end
      units_per_em = ttf.units_per_em
      if units_per_em != 1000
        width *= 1000.0_f32 / units_per_em.to_f32
      end
      return width
    end

    0.0_f32
  end

  def embedded? : Bool
    @is_embedded
  end

  def damaged? : Bool
    @is_damaged
  end

  def average_font_width : Float32
    # TODO: Implement
    0.0_f32
  end

  protected def get_standard14_width(code : Int32) : Float32
    # TODO: Implement for Standard 14 TrueType fonts (unlikely)
    0.0_f32
  end

  protected def encode(unicode : Int32) : Bytes
    # TODO: Implement encoding logic
    Bytes.new(1, 0_u8)
  end

  def read_code(input : IO) : Int32
    # Simple fonts use 1-byte codes
    input.read_byte || -1
  end

  def vertical? : Bool
    false
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
    code_to_gid(code) != 0
  end

  # Helper methods

  private def extract_cmap_table : Nil
    return if @cmap_initialized

    ttf = @ttf
    return if ttf.nil?

    cmap_table = ttf.cmap
    return if cmap_table.nil?

    # get all relevant "cmap" subtables
    cmaps = cmap_table.cmaps
    cmaps.each do |cmap|
      platform_id = cmap.platform_id
      platform_encoding_id = cmap.platform_encoding_id

      if platform_id == CmapTable::PLATFORM_WINDOWS
        if platform_encoding_id == CmapTable::ENCODING_WIN_UNICODE_BMP
          @cmap_win_unicode = cmap
        elsif platform_encoding_id == CmapTable::ENCODING_WIN_SYMBOL
          @cmap_win_symbol = cmap
        end
      elsif platform_id == CmapTable::PLATFORM_MACINTOSH && platform_encoding_id == CmapTable::ENCODING_MAC_ROMAN
        @cmap_mac_roman = cmap
      elsif platform_id == CmapTable::PLATFORM_UNICODE
        if platform_encoding_id == CmapTable::ENCODING_UNICODE_1_0
          # PDFBOX-4755 / PDF.js #5501
          @cmap_win_unicode = cmap
        elsif platform_encoding_id == CmapTable::ENCODING_UNICODE_2_0_BMP
          # PDFBOX-5484
          @cmap_win_unicode = cmap
        end
      end
    end

    @cmap_initialized = true
  end

  private def code_to_gid(code : Int32) : Int32
    extract_cmap_table

    ttf = @ttf
    return 0 if ttf.nil?

    gid = 0

    if !symbolic? # non-symbolic
      name = encoding.get_name(code)
      if name == ".notdef"
        return 0
      else
        # (3, 1) - (Windows, Unicode)
        if cmap = @cmap_win_unicode
          unicode = GlyphList.adobe_glyph_list.to_unicode(name)
          if unicode
            uni = unicode.codepoints.first?
            if uni
              gid = cmap.glyph_id(uni)
            end
          end
        end

        # (1, 0) - (Macintosh, Roman)
        if gid == 0 && (cmap = @cmap_mac_roman)
          mac_code = @inverted_macos_roman[name]?
          if mac_code
            gid = cmap.glyph_id(mac_code)
          end
        end

        # 'post' table
        if gid == 0
          gid = ttf.name_to_gid(name)
        end
      end
    else # symbolic
      # PDFBOX-4755 / PDF.js #5501
      # PDFBOX-3965: fallback for font that has the symbol flag but isn't
      if cmap = @cmap_win_unicode
        if encoding.is_a?(WinAnsiEncoding) || encoding.is_a?(MacRomanEncoding)
          name = encoding.get_name(code)
          if name == ".notdef"
            return 0
          end
          unicode = GlyphList.adobe_glyph_list.to_unicode(name)
          if unicode
            uni = unicode.codepoints.first?
            if uni
              gid = cmap.glyph_id(uni)
            end
          end
        else
          gid = cmap.glyph_id(code)
        end
      end

      # (3, 0) - (Windows, Symbol)
      if gid == 0 && (cmap = @cmap_win_symbol)
        gid = cmap.glyph_id(code)
        if code >= 0 && code <= 0xFF
          # the CMap may use one of the following code ranges,
          # so that we have to add the high byte to get the mapped value
          if gid == 0
            # F000 - F0FF
            gid = cmap.glyph_id(code + START_RANGE_F000)
          end
          if gid == 0
            # F100 - F1FF
            gid = cmap.glyph_id(code + START_RANGE_F100)
          end
          if gid == 0
            # F200 - F2FF
            gid = cmap.glyph_id(code + START_RANGE_F200)
          end
        end
      end

      # (1, 0) - (Mac, Roman)
      if gid == 0 && (cmap = @cmap_mac_roman)
        gid = cmap.glyph_id(code)
      end
    end

    gid
  end
end

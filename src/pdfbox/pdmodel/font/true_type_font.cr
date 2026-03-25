# TrueType font implementation
# Corresponds to PDTrueTypeFont in Apache PDFBox
require "./encoding"
require "./encoding/glyph_list"
require "./encoding/built_in_encoding"
require "./encoding/type1_encoding"
require "./encoding/win_ansi_encoding"
require "./encoding/symbol_encoding"
require "./encoding/zapf_dingbats_encoding"
require "./encoding/mac_roman_encoding"
require "./encoding/macos_roman_encoding"
require "./standard14_fonts"
require "../document"
require "../../../fontbox/ttf/true_type_font"
require "../../../fontbox/ttf/ttf_tables"
require "../../../fontbox/ttf/ttf_parser"
require "../../../fontbox/util/path"

class Pdfbox::Pdmodel::Font::PDTrueTypeFont < Pdfbox::Pdmodel::Font::PDSimpleFont
  include PDVectorFont

  Log = ::Log.for(self)
  Cos = Pdfbox::Cos

  # Placeholder types for missing dependencies
  class OpenTypeFont
    def postscript? : Bool
      false
    end
  end

  class PDStream
    def initialize(dict : Pdfbox::Cos::Dictionary); end

    def cos_object : Pdfbox::Cos::Dictionary
      Pdfbox::Cos::Dictionary.new
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
      raise NotImplementedError.new("FontMappers#get_true_type_font(#{base_font}) not implemented")
    end
  end

  class PDTrueTypeFontEmbedder
    getter font_descriptor : PDFontDescriptor
    @font_descriptor : PDFontDescriptor

    def initialize(doc : PDDocument, dict : Pdfbox::Cos::Dictionary, ttf : Fontbox::TTF::TrueTypeFont, encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding, pd_font : PDTrueTypeFont)
      # Set font subtype
      dict[Pdfbox::Cos::Name.new("Subtype")] = Pdfbox::Cos::Name.new("TrueType")

      # Set encoding
      dict[Pdfbox::Cos::Name.new("Encoding")] = encoding.cos_object

      # Create font descriptor
      @font_descriptor = PDFontDescriptor.new(Pdfbox::Cos::Dictionary.new)

      # Set symbolic/non-symbolic flags
      if encoding.is_a?(Pdfbox::Pdmodel::Font::Encoding::SymbolEncoding) || encoding.is_a?(Pdfbox::Pdmodel::Font::Encoding::ZapfDingbatsEncoding)
        @font_descriptor.symbolic = true
        @font_descriptor.non_symbolic = false
      else
        @font_descriptor.symbolic = false
        @font_descriptor.non_symbolic = true
      end

      # Calculate and set widths
      set_widths(dict, ttf, encoding, pd_font)

      # Set font descriptor
      dict[Pdfbox::Cos::Name.new("FontDescriptor")] = @font_descriptor.cos_object
    end

    def font_descriptor : PDFontDescriptor
      @font_descriptor
    end

    private def set_widths(dict : Pdfbox::Cos::Dictionary, ttf : Fontbox::TTF::TrueTypeFont, encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding, pd_font : PDTrueTypeFont) : Nil
      # Get horizontal metrics
      hmtx = ttf.horizontal_metrics
      return unless hmtx

      # Get units per em
      units_per_em = ttf.units_per_em.to_f32
      scaling = 1000.0_f32 / units_per_em

      # Get first and last character codes
      # For WinAnsiEncoding, this is typically 32-255
      first_char = 32
      last_char = 255

      # Calculate widths array
      widths = [] of Int32
      (first_char..last_char).each do |code|
        # Get glyph ID from encoding
        gid = pd_font.code_to_gid(code)

        # Get advance width
        advance_width = hmtx.advance_width(gid).to_f32
        # Scale to 1000 units and round
        scaled_width = (advance_width * scaling).round.to_i32
        widths << scaled_width
      end

      # Set widths in dictionary
      dict[Pdfbox::Cos::Name.new("FirstChar")] = Pdfbox::Cos::Integer.new(first_char)
      dict[Pdfbox::Cos::Name.new("LastChar")] = Pdfbox::Cos::Integer.new(last_char)
      dict[Pdfbox::Cos::Name.new("Widths")] = Pdfbox::Cos::Array.new(widths.map { |width| Pdfbox::Cos::Integer.new(width) })
    end
  end

  # Constants
  START_RANGE_F000 = 0xF000
  START_RANGE_F100 = 0xF100
  START_RANGE_F200 = 0xF200

  # Static inverted MacOS Roman mapping
  private INVERTED_MACOS_ROMAN = begin
    inverted = Hash(String, Int32).new
    # We need to check if MacOSRomanEncoding exists
    begin
      macos_roman = Pdfbox::Pdmodel::Font::Encoding::MacOSRomanEncoding::INSTANCE
      macos_roman.code_to_name_map.each do |code, name|
        inverted[name] = code unless inverted.has_key?(name)
      end
    rescue
      # If MacOSRomanEncoding doesn't exist, use MacRomanEncoding
      mac_roman = Pdfbox::Pdmodel::Font::Encoding::MacRomanEncoding::INSTANCE
      mac_roman.code_to_name_map.each do |code, name|
        inverted[name] = code unless inverted.has_key?(name)
      end
    end
    inverted
  end

  # Class methods for loading fonts
  def self.load(doc : PDDocument, input : ::IO, encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding) : PDTrueTypeFont
    # Read the font data into a RandomAccessReadBuffer
    random_access_read = Pdfbox::IO::RandomAccessReadBuffer.new(input)

    # Parse the TrueType font
    parser = Fontbox::TTF::TTFParser.new
    ttf = parser.parse(random_access_read)

    # Create the PDTrueTypeFont
    load(doc, ttf, encoding)
  end

  def self.load(doc : PDDocument, ttf : Fontbox::TTF::TrueTypeFont, encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding) : PDTrueTypeFont
    new(doc, ttf, encoding, false)
  end

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
  @font_bbox : PDFont::BoundingBox?

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
  def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
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
      mapping = FontMappers.instance.get_true_type_font(name, fd)
      ttf_font = mapping.font

      if mapping.fallback?
        font_name = begin
          ttf_font.try(&.name) || "?"
        rescue
          "?"
        end
        Log.warn { "Using fallback font #{font_name} for base font #{name}" }
      end
    end

    @ttf = ttf_font
    @otf = ttf_font.is_a?(OpenTypeFont) && ttf_font.is_supported_otf? ? ttf_font : nil

    read_encoding
  end

  # Constructor for embedding (placeholder)
  protected def initialize(doc : PDDocument, ttf : Fontbox::TTF::TrueTypeFont, encoding : Pdfbox::Pdmodel::Font::Encoding::Encoding, close_ttf : Bool)
    super() # embedding constructor
    @ttf = ttf
    @otf = ttf.is_a?(OpenTypeFont) && ttf.is_supported_otf? ? ttf : nil
    @is_embedded = true
    @is_damaged = false
    @encoding = encoding
    # TODO: Implement PDTrueTypeFontEmbedder
    _embedder = PDTrueTypeFontEmbedder.new(doc, @dict, ttf, encoding, self)
    # set_font_descriptor(embedder.font_descriptor)
    if close_ttf
      ttf.close
    end
    read_encoding
  end

  # Abstract method implementations

  protected def read_encoding_from_font : Pdfbox::Pdmodel::Font::Encoding::Encoding
    if !embedded? && (afm = get_standard14_afm)
      # read from AFM
      Pdfbox::Pdmodel::Font::Encoding::Type1Encoding.new(afm)
    else
      # non-symbolic fonts don't have a built-in encoding per se, but their encoding is
      # assumed to be StandardEncoding by the PDF spec unless an explicit Encoding is present
      # which will override this anyway
      if symbolic_flag == false
        return Pdfbox::Pdmodel::Font::Encoding::StandardEncoding::INSTANCE
      end

      # normalise the standard 14 name, e.g "Symbol,Italic" -> "Symbol"
      standard14_name = Standard14Fonts.get_mapped_font_name(name)

      # likewise, if the font is standard 14 then we know it's Standard Encoding
      if standard14? &&
         standard14_name != Standard14Fonts::FontName::SYMBOL &&
         standard14_name != Standard14Fonts::FontName::ZAPF_DINGBATS
        return Pdfbox::Pdmodel::Font::Encoding::StandardEncoding::INSTANCE
      end

      # synthesize an encoding, so that getEncoding() is always usable
      post = @ttf.try(&.postscript)
      code_to_name = Hash(Int32, String).new

      (0..256).each do |code|
        gid = code_to_gid(code)
        if gid > 0
          name = nil
          if post
            name = post.name(gid)
          end
          if name.nil?
            # GID pseudo-name
            name = gid.to_s
          end
          code_to_name[code] = name
        end
      end

      Pdfbox::Pdmodel::Font::Encoding::BuiltInEncoding.new(code_to_name)
    end
  end

  def get_path(name : String) : Fontbox::Util::Path
    ttf = @ttf
    return Fontbox::Util::Path.new if ttf.nil?

    # handle glyph names and uniXXXX names
    gid = ttf.name_to_gid(name)
    if gid == 0
      begin
        # handle GID pseudo-names
        gid = name.to_i
        if gid > ttf.number_of_glyphs
          gid = 0
        end
      rescue ArgumentError
        gid = 0
      end
    end
    # I'm assuming .notdef paths are not drawn, as in PDFBOX-2421
    if gid == 0
      return Fontbox::Util::Path.new
    end

    glyph_table = ttf.glyph
    if glyph_table.nil?
      raise ::IO::Error.new("glyf table is missing in font #{name}, please report this file")
    end
    glyph = glyph_table.glyph(gid)
    if glyph.nil?
      Fontbox::Util::Path.new
    else
      glyph.path
    end
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
    @dict[Pdfbox::Cos::Name::BASE_FONT]?.try(&.to_s) || "Unknown"
  end

  def font_matrix : Matrix
    # TODO: Try to get from ttf
    DEFAULT_FONT_MATRIX
  end

  def bounding_box : PDFont::BoundingBox
    @font_bbox ||= PDFont::BoundingBox.new # TODO: Generate bounding box
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

    # Get width from font
    width_from_font(code)
  end

  def width_from_font(code : Int32) : Float32
    gid = code_to_gid(code)
    return 0.0_f32 if gid == 0

    if ttf = @ttf
      width = if hm = ttf.horizontal_metrics
                hm.advance_width(gid).to_f64
              else
                0.0_f64
              end
      units_per_em = ttf.units_per_em.to_f64
      if units_per_em != 1000
        width *= 1000.0_f64 / units_per_em
      end
      return width.to_f32
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

  def encode(unicode : Int32) : Bytes
    if encoding = @encoding
      # Check if encoding contains the glyph name
      glyph_name = glyph_list.code_point_to_name(unicode)
      unless encoding.contains(glyph_name)
        raise ArgumentError.new("U+%04X is not available in font %s encoding: %s" % [unicode, name, encoding.encoding_name])
      end

      inverted = encoding.name_to_code_map

      unless has_glyph?(glyph_name)
        # try unicode name
        uni_name = uni_name_of_code_point(unicode)
        unless has_glyph?(uni_name)
          raise ArgumentError.new("No glyph for U+%04X in font %s" % [unicode, name])
        end
      end

      code = inverted[glyph_name]
      Bytes.new(1, code.to_u8)
    else
      # use TTF font's built-in encoding
      ttf = @ttf
      raise "No TrueType font loaded" if ttf.nil?

      glyph_name = glyph_list.code_point_to_name(unicode)

      unless has_glyph?(glyph_name)
        raise ArgumentError.new("No glyph for U+%04X in font %s" % [unicode, name])
      end

      gid = ttf.name_to_gid(glyph_name)
      code = gid_to_code[gid]?
      if code.nil?
        raise ArgumentError.new("U+%04X is not available in font %s encoding" % [unicode, name])
      end

      Bytes.new(1, code.to_u8)
    end
  end

  private def uni_name_of_code_point(code_point : Int32) : String
    hex = code_point.to_s(16).upcase
    case hex.size
    when 1
      "uni000#{hex}"
    when 2
      "uni00#{hex}"
    when 3
      "uni0#{hex}"
    else
      "uni#{hex}"
    end
  end

  private def gid_to_code : Hash(Int32, Int32)
    unless @gid_to_code.empty?
      return @gid_to_code
    end

    (0..255).each do |code|
      gid = code_to_gid(code)
      @gid_to_code[gid] = code unless @gid_to_code.has_key?(gid)
    end
    @gid_to_code
  end

  def read_code(input : ::IO) : Int32
    # Simple fonts use 1-byte codes
    byte = input.read_byte
    byte.nil? ? -1 : byte.to_i32
  end

  def vertical? : Bool
    false
  end

  # PDVectorFont interface implementation

  def get_path(code : Int32) : Fontbox::Util::Path
    ttf = @ttf
    return Fontbox::Util::Path.new if ttf.nil?

    if otf = @otf
      if otf.postscript?
        path = get_path_from_outlines(code)
        return path || Fontbox::Util::Path.new
      end
    end

    gid = code_to_gid(code)
    glyph_table = ttf.glyph
    if glyph_table.nil?
      # needs to be caught earlier, see PDFBOX-5587 and PDFBOX-3488
      raise ::IO::Error.new("glyf table is missing in font #{name}, please report this file")
    end
    glyph = glyph_table.glyph(gid)
    if glyph.nil?
      # some glyphs have no outlines (e.g. space, table, newline)
      Fontbox::Util::Path.new
    else
      glyph.path
    end
  end

  def get_normalized_path(code : Int32) : Fontbox::Util::Path
    ttf = @ttf
    return Fontbox::Util::Path.new if ttf.nil?

    path = nil
    if (otf = @otf) && otf.postscript?
      path = get_path_from_outlines(code)
    else
      gid = code_to_gid(code)
      path = get_path(code)
      # Acrobat only draws GID 0 for embedded or "Standard 14" fonts, see PDFBOX-2372
      if gid == 0 && !embedded? && !standard14?
        path = nil
      end
    end
    if path.nil?
      return Fontbox::Util::Path.new
    end
    if ttf.units_per_em != 1000
      scale = 1000.0_f64 / ttf.units_per_em.to_f64
      path.scale!(scale, scale)
    end
    path
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

      if platform_id == Fontbox::TTF::CmapTable::PLATFORM_WINDOWS
        if platform_encoding_id == Fontbox::TTF::CmapTable::ENCODING_WIN_UNICODE_BMP
          @cmap_win_unicode = cmap
        elsif platform_encoding_id == Fontbox::TTF::CmapTable::ENCODING_WIN_SYMBOL
          @cmap_win_symbol = cmap
        end
      elsif platform_id == Fontbox::TTF::CmapTable::PLATFORM_MACINTOSH && platform_encoding_id == Fontbox::TTF::CmapTable::ENCODING_MAC_ROMAN
        @cmap_mac_roman = cmap
      elsif platform_id == Fontbox::TTF::CmapTable::PLATFORM_UNICODE
        if platform_encoding_id == Fontbox::TTF::CmapTable::ENCODING_UNICODE_1_0
          # PDFBOX-4755 / PDF.js #5501
          @cmap_win_unicode = cmap
        elsif platform_encoding_id == Fontbox::TTF::CmapTable::ENCODING_UNICODE_2_0_BMP
          # PDFBOX-5484
          @cmap_win_unicode = cmap
        end
      end
    end

    @cmap_initialized = true
  end

  private def get_path_from_outlines(code : Int32) : Fontbox::Util::Path?
    # TODO: Implement OpenType CFF outlines
    nil
  end

  # ameba:disable Metrics/CyclomaticComplexity
  protected def code_to_gid(code : Int32) : Int32
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
          mac_code = INVERTED_MACOS_ROMAN[name]?
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
        if encoding.is_a?(Pdfbox::Pdmodel::Font::Encoding::WinAnsiEncoding) || encoding.is_a?(Pdfbox::Pdmodel::Font::Encoding::MacRomanEncoding)
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

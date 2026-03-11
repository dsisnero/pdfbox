# Type 2 CIDFont (TrueType)
# Corresponds to PDCIDFontType2 in Apache PDFBox
require "./cid_font"
require "../../../fontbox/ttf/true_type_font"

module Pdfbox::Pdmodel::Font
  class PDCIDFontType2 < PDCIDFont
    Log = ::Log.for(self)
    Cos = Pdfbox::Cos

    @parent : PDType0Font
    @ttf : Fontbox::TTF::TrueTypeFont?
    @is_embedded : Bool = false
    @is_damaged : Bool = false
    @font_matrix : PDFont::Matrix = PDFont::Matrix.default_font_matrix
    @font_bbox : PDFont::BoundingBox = PDFont::BoundingBox.new
    @cid2gid : Array(Int32)?

    # Constructor.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary, parent : PDType0Font)
      super(font_dictionary, parent)
      @parent = parent
      fd = font_descriptor
      @is_embedded = !fd.nil? && (!fd.try(&.font_file2).nil? || !fd.try(&.font_file3).nil? || !fd.try(&.font_file).nil?)
      @is_damaged = false
      @cid2gid = read_cid_to_gid_map
    end

    # Constructor with pre-loaded TrueType font.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary, parent : PDType0Font, true_type_font : Fontbox::TTF::TrueTypeFont)
      super(font_dictionary, parent)
      @parent = parent
      @ttf = true_type_font
      @is_embedded = true
      @is_damaged = false
      @cid2gid = read_cid_to_gid_map
    end

    # Abstract method implementations

    def code_to_cid(code : Int32) : Int32
      c_map = @parent.cmap
      return code if c_map.nil?

      # Acrobat allows Unicode CMaps in this position, see PDFBOX-1283.
      if !c_map.has_cid_mappings? && c_map.has_unicode_mappings?
        unicode = c_map.to_unicode(code)
        if unicode && !unicode.empty?
          return unicode.char_at(0).ord.to_i32
        end
      end

      c_map.to_cid(code)
    end

    def code_to_gid(code : Int32) : Int32
      cid = code_to_cid(code)
      if cid2gid = @cid2gid
        return cid < cid2gid.size ? cid2gid[cid] : 0
      end

      if ttf = @ttf
        return cid < ttf.number_of_glyphs ? cid : 0
      end

      cid
    end

    def encode_glyph_id(glyph_id : Int32) : Bytes
      # CID is always 2-bytes (16-bit) for TrueType CIDFonts.
      Bytes[((glyph_id >> 8) & 0xff).to_u8, (glyph_id & 0xff).to_u8]
    end

    protected def encode(unicode : Int32) : Bytes
      glyph_id = 0
      if ttf = @ttf
        begin
          glyph_id = ttf.unicode_cmap_lookup(false).glyph_id(unicode)
        rescue ex : IO::Error
          Log.warn { "Failed to map Unicode U+#{unicode.to_s(16).upcase.rjust(4, '0')} in #{name}: #{ex.message}" }
        end
      end
      if glyph_id == 0
        raise ArgumentError.new("No glyph for U+#{unicode.to_s(16).upcase.rjust(4, '0')} in font #{name}")
      end
      encode_glyph_id(glyph_id)
    end

    def font_matrix : PDFont::Matrix
      @font_matrix
    end

    def bounding_box : PDFont::BoundingBox
      @font_bbox
    end

    def width_from_font(code : Int32) : Float32
      ttf = @ttf
      return 0.0_f32 if ttf.nil?

      gid = code_to_gid(code)
      width = ttf.horizontal_metrics.try(&.advance_width(gid).to_f32) || 0.0_f32
      units_per_em = ttf.units_per_em
      if units_per_em > 0 && units_per_em != 1000
        width *= 1000.0_f32 / units_per_em.to_f32
      end
      width
    end

    def height(code : Int32) : Float32
      ttf = @ttf
      return 0.0_f32 if ttf.nil?
      hhea = ttf.horizontal_header
      return 0.0_f32 if hhea.nil?
      units_per_em = ttf.units_per_em
      return 0.0_f32 if units_per_em <= 0
      (hhea.ascender + -hhea.descender).to_f32 / units_per_em.to_f32
    end

    def embedded? : Bool
      @is_embedded
    end

    def damaged? : Bool
      @is_damaged
    end

    # PDVectorFont abstract methods
    def get_path(code : Int32)
      # TODO: Implement TrueType glyph path extraction
      nil
    end

    def get_normalized_path(code : Int32)
      nil
    end

    def has_glyph(code : Int32) : Bool
      code_to_gid(code) != 0
    end

    # Additional methods used by PDType0Font
    def cid_font_type2? : Bool
      true
    end

    def true_type_font
      @ttf
    end
  end
end

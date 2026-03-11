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
    @font_bbox : PDFont::BoundingBox?
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

      unless embedded?
        return non_embedded_gid(code, cid)
      end

      if cid2gid = @cid2gid
        return cid < cid2gid.size ? cid2gid[cid] : 0
      end

      if ttf = @ttf
        return cid < ttf.number_of_glyphs ? cid : 0
      end

      cid
    end

    private def non_embedded_gid(code : Int32, cid : Int32) : Int32
      if mapped_gid = gid_from_non_embedded_cid_to_gid_map(cid)
        return mapped_gid
      end

      unicode = @parent.to_unicode(code)
      return cid if unicode.nil?

      gid = gid_from_unicode(unicode)
      gid.nil? ? cid : gid
    end

    private def gid_from_non_embedded_cid_to_gid_map(cid : Int32) : Int32?
      return nil unless cid2gid = @cid2gid
      return nil if damaged?
      return nil unless ttf = @ttf
      return nil unless name == ttf.name
      cid < cid2gid.size ? cid2gid[cid] : 0
    end

    private def gid_from_unicode(unicode : String) : Int32?
      return nil unless ttf = @ttf
      begin
        cmap = ttf.unicode_cmap_lookup(false)
        cmap.glyph_id(unicode.char_at(0).ord.to_i32)
      rescue ex : ::IO::Error
        Log.warn { "Failed to map non-embedded Unicode in #{name}: #{ex.message}" }
        nil
      end
    end

    def encode_glyph_id(glyph_id : Int32) : Bytes
      # CID is always 2-bytes (16-bit) for TrueType CIDFonts.
      Bytes[((glyph_id >> 8) & 0xff).to_u8, (glyph_id & 0xff).to_u8]
    end

    protected def encode(unicode : Int32) : Bytes
      cid = -1
      if embedded?
        cmap_name = @parent.cmap.try(&.name)
        if cmap_name && cmap_name.starts_with?("Identity-")
          if cmap = unicode_cmap_lookup
            cid = cmap.glyph_id(unicode)
          end
        else
          if cmap_ucs2 = @parent.cmap_ucs2
            cid = cmap_ucs2.to_cid(unicode)
          end
        end

        if cid == -1
          if to_unicode_cmap = @parent.to_unicode_cmap
            if codes = to_unicode_cmap.codes_from_unicode(unicode_char(unicode))
              return codes
            end
          end
          cid = 0
        end
      else
        cid = unicode_cmap_lookup.try(&.glyph_id(unicode)) || 0
      end

      if cid == 0
        raise ArgumentError.new("No glyph for U+#{unicode.to_s(16).upcase.rjust(4, '0')} (#{unicode_char(unicode)}) in font #{name}")
      end
      encode_glyph_id(cid)
    end

    private def unicode_cmap_lookup : Fontbox::TTF::CmapLookup?
      return nil unless ttf = @ttf
      ttf.unicode_cmap_lookup(false)
    rescue ex : ::IO::Error
      Log.warn { "Failed to get cmap lookup for #{name}: #{ex.message}" }
      nil
    end

    private def unicode_char(unicode : Int32) : String
      ((unicode & 0xFFFF).chr).to_s
    rescue ArgumentError
      "\uFFFD"
    end

    def font_matrix : PDFont::Matrix
      @font_matrix
    end

    def bounding_box : PDFont::BoundingBox
      @font_bbox ||= generate_bounding_box
    end

    private def generate_bounding_box : PDFont::BoundingBox
      if descriptor = font_descriptor
        if bbox = descriptor.font_bounding_box
          if bbox.lower_left_x != 0.0_f32 || bbox.lower_left_y != 0.0_f32 ||
             bbox.upper_right_x != 0.0_f32 || bbox.upper_right_y != 0.0_f32
            return PDFont::BoundingBox.new(
              bbox.lower_left_x,
              bbox.lower_left_y,
              bbox.upper_right_x,
              bbox.upper_right_y
            )
          end
        end
      end

      if ttf = @ttf
        if header = ttf.header
          return PDFont::BoundingBox.new(
            header.x_min.to_f32,
            header.y_min.to_f32,
            header.x_max.to_f32,
            header.y_max.to_f32
          )
        end
      end

      PDFont::BoundingBox.new
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
      ttf = @ttf
      return Fontbox::Util::Path.new if ttf.nil?

      gid = code_to_gid(code)
      glyph_table = ttf.glyph
      return Fontbox::Util::Path.new if glyph_table.nil?

      glyph = glyph_table.glyph(gid)
      glyph ? glyph.path : Fontbox::Util::Path.new
    end

    def get_normalized_path(code : Int32)
      gid = code_to_gid(code)
      path = get_path(code)
      return Fontbox::Util::Path.new if gid == 0 && !embedded?
      return path if path.empty?

      ttf = @ttf
      return path if ttf.nil?

      units_per_em = ttf.units_per_em
      return path if units_per_em <= 0 || units_per_em == 1000

      normalized = Fontbox::Util::Path.new
      normalized.append(path)
      scale = 1000.0 / units_per_em.to_f64
      normalized.scale!(scale, scale)
      normalized
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

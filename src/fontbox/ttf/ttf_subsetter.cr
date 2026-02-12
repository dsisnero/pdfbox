module Fontbox::TTF
  class TTFSubsetter
    @ttf : TrueTypeFont
    @unicode_cmap : CmapLookup
    @uni_to_gid : Hash(Int32, Int32)
    @keep_tables : Array(String)?
    @glyph_ids : Set(Int32)
    @invisible_glyph_ids : Set(Int32)
    @prefix : String?
    @has_added_compound_references : Bool

    def initialize(font : TrueTypeFont, tables : Array(String)? = nil)
      @ttf = font
      @keep_tables = tables
      @uni_to_gid = Hash(Int32, Int32).new
      @glyph_ids = Set(Int32).new
      @invisible_glyph_ids = Set(Int32).new
      @prefix = nil
      @has_added_compound_references = false

      # Find Unicode cmap
      @unicode_cmap = font.unicode_cmap_lookup

      # Always include glyph 0 (.notdef)
      @glyph_ids.add(0)
    end

    def add(char : Char)
      code_point = char.ord
      add(code_point)
    end

    def add(code_point : Int32)
      gid = @unicode_cmap.glyph_id(code_point)
      if gid > 0
        @glyph_ids.add(gid)
        @uni_to_gid[code_point] = gid
      end
    end

    def write_to_stream(io : IO)
    end
  end
end

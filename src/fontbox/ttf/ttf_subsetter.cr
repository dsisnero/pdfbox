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
    @gid_map : Hash(Int32, Int32)?

    def initialize(font : TrueTypeFont, tables : Array(String)? = nil)
      @ttf = font
      @keep_tables = tables
      @uni_to_gid = Hash(Int32, Int32).new
      @glyph_ids = Set(Int32).new
      @invisible_glyph_ids = Set(Int32).new
      @prefix = nil
      @has_added_compound_references = false
      @gid_map = nil

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
      # Build glyph set
      build_glyph_set

      # Build GID map
      build_gid_map

      # Write font header
      write_font_header(io)

      # Write tables
      table_offsets = write_tables(io)

      # Write directory
      write_table_directory(io, table_offsets)
    end

    private def build_glyph_set
      # Already have @glyph_ids with glyph 0
      # Add compound glyph references if needed
      add_compound_references unless @has_added_compound_references
    end

    private def build_gid_map
      # Map old GIDs to new sequential GIDs
      map = Hash(Int32, Int32).new
      @glyph_ids.each_with_index do |old_gid, index|
        map[old_gid] = index
      end
      @gid_map = map
    end

    private def add_compound_references
      # TODO: implement
      @has_added_compound_references = true
    end

    private def write_font_header(io : IO)
      # TODO: implement
    end

    private def write_tables(io : IO)
      # TODO: implement
      {} of String => Int64
    end

    private def write_table_directory(io : IO, table_offsets : Hash(String, Int64))
      # TODO: implement
    end

    # Table building stubs
    private def build_head_table : Bytes
      Bytes.empty
    end

    private def build_hhea_table : Bytes
      Bytes.empty
    end

    private def build_maxp_table : Bytes
      Bytes.empty
    end

    private def build_name_table : Bytes?
      nil
    end

    private def build_os2_table : Bytes?
      nil
    end

    private def build_glyf_table(new_loca : Array(Int64)) : Bytes
      Bytes.empty
    end

    private def build_loca_table(new_loca : Array(Int64)) : Bytes
      Bytes.empty
    end

    private def build_cmap_table : Bytes?
      nil
    end

    private def build_hmtx_table : Bytes
      Bytes.empty
    end

    private def build_post_table : Bytes?
      nil
    end

    private def write_file_header(io : IO, n_tables : Int32) : Int64
      0_i64
    end

    private def write_table_header(io : IO, tag : String, offset : Int64, bytes : Bytes) : Int64
      0_i64
    end

    private def write_table_body(io : IO, bytes : Bytes)
    end
  end
end

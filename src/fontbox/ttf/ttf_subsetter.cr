module Fontbox::TTF
  class TTFSubsetter
    PAD_BUF = Bytes[0, 0, 0, 0]

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
      add_compound_references unless @has_added_compound_references

      new_loca = Array(Int64).new(@glyph_ids.size + 1, 0_i64)

      # generate tables in dependency order
      head = build_head_table
      hhea = build_hhea_table
      maxp = build_maxp_table
      name = build_name_table
      os2 = build_os2_table
      glyf = build_glyf_table(new_loca)
      loca = build_loca_table(new_loca)
      cmap = build_cmap_table
      hmtx = build_hmtx_table
      post = build_post_table

      # save to TTF in optimized order
      tables = {} of String => Bytes
      if os2
        tables["OS/2"] = os2
      end
      if cmap
        tables["cmap"] = cmap
      end
      tables["glyf"] = glyf
      tables["head"] = head
      tables["hhea"] = hhea
      tables["hmtx"] = hmtx
      tables["loca"] = loca
      tables["maxp"] = maxp
      if name
        tables["name"] = name
      end
      if post
        tables["post"] = post
      end

      # copy all other tables (TODO: implement when needed)
      # if keep_tables = @keep_tables
      #   @ttf.tables.each do |table|
      #     tag = table.tag
      #     if !tables.has_key?(tag) && keep_tables.includes?(tag)
      #       # TODO: get table bytes
      #       # tables[tag] = @ttf.get_table_bytes(table)
      #     end
      #   end
      # end

      # calculate checksum
      checksum = write_file_header(io, tables.size)
      offset = 12_i64 + 16_i64 * tables.size.to_i64
      table_offsets = {} of String => Int64
      tables.each do |tag, bytes|
        table_offsets[tag] = offset.to_i64
        checksum += write_table_header(io, tag, offset, bytes)
        offset += ((bytes.size + 3) // 4 * 4).to_i64
      end
      sum32 = (checksum & 0xffffffff_u64).to_u32
      # compute checksum adjustment: 0xB1B0AFBA - sum32 (mod 2^32)
      adjustment = 0xB1B0AFBA_u32 &- sum32
      checksum = adjustment.to_u64

      # update checksumAdjustment in 'head' table
      adj = checksum.to_u32
      head[8] = ((adj >> 24) & 0xFF).to_u8
      head[9] = ((adj >> 16) & 0xFF).to_u8
      head[10] = ((adj >> 8) & 0xFF).to_u8
      head[11] = (adj & 0xFF).to_u8
      tables.each do |_, bytes|
        write_table_body(io, bytes)
      end
    end

    private def build_glyph_set
      # Already have @glyph_ids with glyph 0
      # Add compound glyph references if needed
      add_compound_references unless @has_added_compound_references
    end

    private def sorted_glyph_ids : Array(Int32)
      @glyph_ids.to_a.sort
    end

    private def build_gid_map
      # Map old GIDs to new sequential GIDs
      map = Hash(Int32, Int32).new
      sorted_glyph_ids.each_with_index do |old_gid, index|
        map[old_gid] = index
      end
      @gid_map = map
    end

    private def add_compound_references
      # TODO: implement
      @has_added_compound_references = true
    end

    private def write_fixed(io : IO, f : Float64)
      ip = f.floor.to_i
      fp = ((f - ip) * 65536.0).round.to_i
      io.write_bytes(ip.to_u16, IO::ByteFormat::BigEndian)
      io.write_bytes(fp.to_u16, IO::ByteFormat::BigEndian)
    end

    private def write_uint32(io : IO, value : UInt64)
      io.write_bytes(value.to_u32, IO::ByteFormat::BigEndian)
    end

    private def write_uint16(io : IO, value : UInt32)
      io.write_bytes(value.to_u16, IO::ByteFormat::BigEndian)
    end

    private def write_sint16(io : IO, value : Int32)
      io.write_bytes(value.to_i16, IO::ByteFormat::BigEndian)
    end

    private def write_uint8(io : IO, value : UInt32)
      io.write_byte(value.to_u8)
    end

    private def write_long_date_time(io : IO, time : Time)
      # inverse operation of TTFDataStream.read_international_date
      epoch_1904 = Time.utc(1904, 1, 1, 0, 0, 0)
      seconds_since_1904 = (time - epoch_1904).total_seconds.to_i64
      io.write_bytes(seconds_since_1904, IO::ByteFormat::BigEndian)
    end

    private def to_uint32(high : Int32, low : Int32) : UInt64
      (high & 0xffff).to_u64 << 16 | (low & 0xffff).to_u64
    end

    private def to_uint32(bytes : Bytes) : UInt64
      (bytes[0] & 0xff).to_u64 << 24 |
        (bytes[1] & 0xff).to_u64 << 16 |
        (bytes[2] & 0xff).to_u64 << 8 |
        (bytes[3] & 0xff).to_u64
    end

    private def log2(num : Int32) : Int32
      Math.log2(num).floor.to_i
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
      io = IO::Memory.new(54)
      h = @ttf.header.not_nil!
      write_fixed(io, h.@version.to_f64)
      write_fixed(io, h.@font_revision.to_f64)
      write_uint32(io, 0_u64) # checksum adjustment, filled later
      write_uint32(io, h.@magic_number)
      write_uint16(io, h.@flags.to_u32)
      write_uint16(io, h.@units_per_em.to_u32)
      write_long_date_time(io, h.@created)
      write_long_date_time(io, h.@modified)
      write_sint16(io, h.@x_min.to_i32)
      write_sint16(io, h.@y_min.to_i32)
      write_sint16(io, h.@x_max.to_i32)
      write_sint16(io, h.@y_max.to_i32)
      write_uint16(io, h.@mac_style.to_u32)
      write_uint16(io, h.@lowest_rec_ppem.to_u32)
      write_sint16(io, h.@font_direction_hint.to_i32)
      # force long format of 'loca' table
      write_sint16(io, 1_i32) # index_to_loc_format
      write_sint16(io, h.@glyph_data_format.to_i32)
      io.to_slice
    end

    private def build_hhea_table : Bytes
      io = IO::Memory.new(36)
      h = @ttf.horizontal_header.not_nil!
      write_fixed(io, h.@version.to_f64)
      write_sint16(io, h.@ascender.to_i32)
      write_sint16(io, h.@descender.to_i32)
      write_sint16(io, h.@line_gap.to_i32)
      write_uint16(io, h.@advance_width_max.to_u32)
      write_sint16(io, h.@min_left_side_bearing.to_i32)
      write_sint16(io, h.@min_right_side_bearing.to_i32)
      write_sint16(io, h.@x_max_extent.to_i32)
      write_sint16(io, h.@caret_slope_rise.to_i32)
      write_sint16(io, h.@caret_slope_run.to_i32)
      write_sint16(io, h.@caret_offset.to_i32)
      write_sint16(io, h.@reserved1.to_i32)
      write_sint16(io, h.@reserved2.to_i32)
      write_sint16(io, h.@reserved3.to_i32)
      write_sint16(io, h.@reserved4.to_i32)
      write_sint16(io, h.@metric_data_format.to_i32)

      # is there a GID >= numberOfHMetrics ? Then keep the last entry of original hmtx table,
      # (add if it isn't in our set of GIDs), see also in buildHmtxTable()
      sorted = sorted_glyph_ids
      hmetrics = sorted.count { |gid| gid < h.@number_of_h_metrics }
      if !sorted.empty? && sorted.last >= h.@number_of_h_metrics && !sorted.includes?(h.@number_of_h_metrics - 1)
        hmetrics += 1
      end
      write_uint16(io, hmetrics.to_u32)
      io.to_slice
    end

    private def build_maxp_table : Bytes
      io = IO::Memory.new(32)
      p = @ttf.maximum_profile.not_nil!
      write_fixed(io, p.@version.to_f64)
      write_uint16(io, sorted_glyph_ids.size.to_u32)
      if p.@version >= 1.0
        write_uint16(io, p.@max_points.to_u32)
        write_uint16(io, p.@max_contours.to_u32)
        write_uint16(io, p.@max_composite_points.to_u32)
        write_uint16(io, p.@max_composite_contours.to_u32)
        write_uint16(io, p.@max_zones.to_u32)
        write_uint16(io, p.@max_twilight_points.to_u32)
        write_uint16(io, p.@max_storage.to_u32)
        write_uint16(io, p.@max_function_defs.to_u32)
        write_uint16(io, p.@max_instruction_defs.to_u32)
        write_uint16(io, p.@max_stack_elements.to_u32)
        write_uint16(io, p.@max_size_of_instructions.to_u32)
        write_uint16(io, p.@max_component_elements.to_u32)
        write_uint16(io, p.@max_component_depth.to_u32)
      end
      io.to_slice
    end

    private def build_name_table : Bytes?
      nil
    end

    private def build_os2_table : Bytes?
      nil
    end

    private def build_glyf_table(new_loca : Array(Int64)) : Bytes
      # Simple .notdef glyph with zero contours
      io = IO::Memory.new(10)
      write_sint16(io, 0_i32) # numberOfContours = 0 (simple glyph)
      # Bounds (xMin, yMin, xMax, yMax) - use zeros for now
      write_sint16(io, 0_i32) # xMin
      write_sint16(io, 0_i32) # yMin
      write_sint16(io, 0_i32) # xMax
      write_sint16(io, 0_i32) # yMax
      # No instruction length, no instructions
      bytes = io.to_slice
      new_loca[0] = 0_i64
      new_loca[1] = bytes.size.to_i64
      bytes
    end

    private def build_loca_table(new_loca : Array(Int64)) : Bytes
      io = IO::Memory.new(new_loca.size * 4)
      new_loca.each do |offset|
        write_uint32(io, offset.to_u64)
      end
      io.to_slice
    end

    private def build_cmap_table : Bytes?
      nil
    end

    private def build_hmtx_table : Bytes
      # For empty subset: single glyph 0
      io = IO::Memory.new(4)
      # Use original metrics for glyph 0 if available
      hm = @ttf.horizontal_metrics.not_nil!
      write_uint16(io, hm.advance_width(0).to_u32)
      write_sint16(io, hm.left_side_bearing(0).to_i32)
      io.to_slice
    end

    private def build_post_table : Bytes?
      # Return minimal post table version 2.0 with .notdef glyph name
      io = IO::Memory.new(32)
      write_fixed(io, 2.0)    # version
      write_fixed(io, 0.0)    # italic angle
      write_sint16(io, 0_i32) # underline position
      write_sint16(io, 0_i32) # underline thickness
      write_uint32(io, 0_u64) # is fixed pitch
      write_uint32(io, 0_u64) # min mem type 42
      write_uint32(io, 0_u64) # max mem type 42
      write_uint32(io, 0_u64) # min mem type 1
      write_uint32(io, 0_u64) # max mem type 1
      write_uint16(io, 1_u32) # number of glyphs
      write_uint16(io, 0_u32) # glyphNameIndex[0] = 0 (.notdef)
      io.to_slice
    end

    private def write_file_header(io : IO, n_tables : Int32) : UInt64
      io.write_bytes(0x00010000_u32, IO::ByteFormat::BigEndian) # version
      io.write_bytes(n_tables.to_u16, IO::ByteFormat::BigEndian)

      mask = 1 << Math.log2(n_tables).floor.to_i
      search_range = mask * 16
      io.write_bytes(search_range.to_u16, IO::ByteFormat::BigEndian)

      entry_selector = log2(mask)
      io.write_bytes(entry_selector.to_u16, IO::ByteFormat::BigEndian)

      # numTables * 16 - searchRange
      last = 16 * n_tables - search_range
      io.write_bytes(last.to_u16, IO::ByteFormat::BigEndian)

      # Return checksum of this header
      0x00010000_u64 + to_uint32(n_tables, search_range) + to_uint32(entry_selector, last)
    end

    private def compute_checksum(bytes : Bytes) : UInt64
      checksum = 0_u64
      bytes.each_with_index do |byte, i|
        checksum += (byte & 0xff).to_u64 << (24 - i % 4 * 8)
      end
      checksum & 0xffffffff_u64
    end

    private def write_table_header(io : IO, tag : String, offset : Int64, bytes : Bytes) : UInt64
      checksum = compute_checksum(bytes)

      # Write tag (4 bytes ASCII)
      if tag.bytesize != 4
        raise "Table tag must be 4 bytes: #{tag}"
      end
      io.write(tag.to_slice)

      io.write_bytes(checksum.to_u32, IO::ByteFormat::BigEndian)
      io.write_bytes(offset.to_u32, IO::ByteFormat::BigEndian)
      io.write_bytes(bytes.size.to_u32, IO::ByteFormat::BigEndian)

      # account for the checksum twice, once for the header field, once for the content itself
      tag_sum = to_uint32(tag.to_slice)
      tag_sum.to_u64 + checksum + checksum + offset.to_u64 + bytes.size.to_u64
    end

    private def write_table_body(io : IO, bytes : Bytes)
      io.write(bytes)
      padding = bytes.size % 4
      if padding != 0
        io.write(PAD_BUF[0, 4 - padding])
      end
    end
  end
end

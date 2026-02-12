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

    # Forces the glyph for the specified character code to be zero-width and contour-free,
    # regardless of what the glyph looks like in the original font. Note that the specified
    # character code is not added to the subset unless it is also added separately.
    def force_invisible(code_point : Int32)
      gid = @unicode_cmap.glyph_id(code_point)
      if gid > 0
        @invisible_glyph_ids.add(gid)
      end
    end

    # Returns a map of new GID to old GID.
    def gid_map : Hash(Int32, Int32)
      add_compound_references unless @has_added_compound_references
      build_gid_map if @gid_map.nil?
      map = @gid_map.not_nil! # ameba:disable Lint/NotNil
      # invert old->new to new->old
      result = Hash(Int32, Int32).new
      map.each do |old_gid, new_gid|
        result[new_gid] = old_gid
      end
      result
    end

    def write_to_stream(io : IO)
      add_compound_references unless @has_added_compound_references
      build_gid_map

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

      # copy all other tables
      if keep_tables = @keep_tables
        @ttf.table_map.each do |tag, table|
          if !tables.has_key?(tag) && keep_tables.includes?(tag)
            tables[tag] = @ttf.table_bytes(table)
          end
        end
      end

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
      return if @has_added_compound_references
      @has_added_compound_references = true

      glyph_table = @ttf.table("glyf")
      loca = @ttf.index_to_location
      return if glyph_table.nil? || loca.nil?

      offsets = loca.offsets
      glyph_table_bytes = @ttf.table_bytes(glyph_table)

      loop do
        glyph_ids_to_add = nil

        sorted = sorted_glyph_ids
        sorted.each do |old_gid|
          start_offset = offsets[old_gid]
          end_offset = offsets[old_gid + 1]
          length = (end_offset - start_offset).to_i32
          next if length <= 0

          # Get glyph data
          bytes = glyph_table_bytes[start_offset.to_i32, length]
          # Check if compound glyph (first two bytes are -1, -1)
          if bytes.size >= 2 && bytes[0] == 0xFF_u8 && bytes[1] == 0xFF_u8
            # Parse composite glyph components
            offset = 10 # 2*5: skip numberOfContours (2), xMin, yMin, xMax, yMax (2 each)
            while offset < bytes.size
              flags = (bytes[offset].to_i32 << 8) | bytes[offset + 1].to_i32
              offset += 2
              component_gid = (bytes[offset].to_i32 << 8) | bytes[offset + 1].to_i32
              offset += 2

              # Check if component is already in our set
              if !@glyph_ids.includes?(component_gid) && !@invisible_glyph_ids.includes?(component_gid)
                glyph_ids_to_add ||= Set(Int32).new
                glyph_ids_to_add.add(component_gid)
              end

              # Skip remaining fields based on flags
              if (flags & GlyfCompositeComp::ARG_1_AND_2_ARE_WORDS) != 0
                offset += 4 # two 16-bit words
              else
                offset += 2 # two 8-bit bytes
              end

              if (flags & GlyfCompositeComp::WE_HAVE_A_TWO_BY_TWO) != 0
                offset += 8 # four 16-bit words
              elsif (flags & GlyfCompositeComp::WE_HAVE_AN_X_AND_Y_SCALE) != 0
                offset += 4 # two 16-bit words
              elsif (flags & GlyfCompositeComp::WE_HAVE_A_SCALE) != 0
                offset += 2 # one 16-bit word
              end

              break if (flags & GlyfCompositeComp::MORE_COMPONENTS) == 0
            end
          end
        end

        break if glyph_ids_to_add.nil?
        glyph_ids_to_add.each do |gid|
          @glyph_ids.add(gid)
        end
      end
    end

    private def rewrite_component_gids(bytes : Bytes, gid_map : Hash(Int32, Int32)) : Bytes
      # Return a copy with component GIDs rewritten
      return bytes if bytes.size < 2 || bytes[0] != 0xFF_u8 || bytes[1] != 0xFF_u8

      # Create mutable copy
      result = bytes.dup
      offset = 10 # skip numberOfContours, bounding box
      while offset < result.size
        flags = (result[offset].to_i32 << 8) | result[offset + 1].to_i32
        offset += 2

        component_gid = (result[offset].to_i32 << 8) | result[offset + 1].to_i32
        new_gid = gid_map[component_gid]? || component_gid
        # Write back new GID
        result[offset] = (new_gid >> 8).to_u8
        result[offset + 1] = (new_gid & 0xFF).to_u8
        offset += 2

        # Skip remaining fields based on flags
        if (flags & GlyfCompositeComp::ARG_1_AND_2_ARE_WORDS) != 0
          offset += 4 # two 16-bit words
        else
          offset += 2 # two 8-bit bytes
        end

        if (flags & GlyfCompositeComp::WE_HAVE_A_TWO_BY_TWO) != 0
          offset += 8 # four 16-bit words
        elsif (flags & GlyfCompositeComp::WE_HAVE_AN_X_AND_Y_SCALE) != 0
          offset += 4 # two 16-bit words
        elsif (flags & GlyfCompositeComp::WE_HAVE_A_SCALE) != 0
          offset += 2 # one 16-bit word
        end

        break if (flags & GlyfCompositeComp::MORE_COMPONENTS) == 0
      end
      result
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
      h = @ttf.header.not_nil! # ameba:disable Lint/NotNil
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
      h = @ttf.horizontal_header.not_nil! # ameba:disable Lint/NotNil
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
      p = @ttf.maximum_profile.not_nil! # ameba:disable Lint/NotNil
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
      naming = @ttf.table("name")
      if naming.nil?
        return
      end
      if keep = @keep_tables
        if !keep.includes?("name")
          return
        end
      end
      # TODO: implement proper naming table
      nil
    end

    private def build_os2_table : Bytes?
      os2 = @ttf.table("OS/2")
      if os2.nil? || @uni_to_gid.empty?
        return
      end
      if keep = @keep_tables
        if !keep.includes?("OS/2")
          return
        end
      end
      # TODO: implement OS/2 table
      nil
    end

    private def build_glyf_table(new_loca : Array(Int64)) : Bytes
      glyph_table = @ttf.table("glyf").not_nil! # ameba:disable Lint/NotNil
      loca = @ttf.index_to_location.not_nil!    # ameba:disable Lint/NotNil
      offsets = loca.offsets
      glyph_table_bytes = @ttf.table_bytes(glyph_table)
      gid_map = @gid_map.not_nil! # ameba:disable Lint/NotNil

      io = IO::Memory.new
      new_offset = 0_i64
      sorted = sorted_glyph_ids

      sorted.each_with_index do |old_gid, idx|
        new_loca[idx] = new_offset
        if @invisible_glyph_ids.includes?(old_gid)
          # skip copying, leave zero length
          next
        end
        start = offsets[old_gid].to_i32
        length = (offsets[old_gid + 1] - offsets[old_gid]).to_i32
        if length > 0
          glyph_data = glyph_table_bytes[start, length]
          # Rewrite component GIDs for compound glyphs
          if glyph_data.size >= 2 && glyph_data[0] == 0xFF_u8 && glyph_data[1] == 0xFF_u8
            glyph_data = rewrite_component_gids(glyph_data, gid_map)
          end
          io.write(glyph_data)
          new_offset += length
          # align to 4-byte boundary? (handled later in write_table_body)
        end
      end
      # final loca entry
      new_loca[sorted.size] = new_offset
      io.to_slice
    end

    private def build_loca_table(new_loca : Array(Int64)) : Bytes
      io = IO::Memory.new(new_loca.size * 4)
      new_loca.each do |offset|
        write_uint32(io, offset.to_u64)
      end
      io.to_slice
    end

    private def build_cmap_table : Bytes?
      if @ttf.cmap.nil? || @uni_to_gid.empty?
        return
      end
      if keep = @keep_tables
        if !keep.includes?("cmap")
          return
        end
      end

      entries = @uni_to_gid.to_a.sort_by { |code_point, _| code_point }
      # map old GID to new GID
      gid_map = @gid_map.not_nil! # ameba:disable Lint/NotNil

      # Build segments similar to Java algorithm
      start_code = [] of Int32
      end_code = [] of Int32
      id_delta = [] of Int32

      last_char_entry = entries[0]
      prev_char_entry = last_char_entry
      last_gid = gid_map[last_char_entry[1]]

      i = 1
      while i < entries.size
        cur_char_entry = entries[i]
        cur_gid = gid_map[cur_char_entry[1]]

        # non-BMP not supported
        if cur_char_entry[0] > 0xFFFF
          raise "Non-BMP Unicode character not supported"
        end

        if cur_char_entry[0] != prev_char_entry[0] + 1 ||
           cur_gid - last_gid != cur_char_entry[0] - last_char_entry[0]
          # emit segment
          if last_gid != 0
            start_code << last_char_entry[0]
            end_code << prev_char_entry[0]
            id_delta << last_gid - last_char_entry[0]
          elsif last_char_entry[0] != prev_char_entry[0]
            # shorten ranges which start with GID 0 by one
            start_code << last_char_entry[0] + 1
            end_code << prev_char_entry[0]
            id_delta << last_gid - last_char_entry[0]
          end
          last_gid = cur_gid
          last_char_entry = cur_char_entry
        end
        prev_char_entry = cur_char_entry
        i += 1
      end

      # trailing segment
      start_code << last_char_entry[0]
      end_code << prev_char_entry[0]
      id_delta << last_gid - last_char_entry[0]

      # GID 0 segment
      start_code << 0xFFFF
      end_code << 0xFFFF
      id_delta << 1

      seg_count = start_code.size

      io = IO::Memory.new(64)
      # cmap header
      write_uint16(io, 0_u32) # version
      write_uint16(io, 1_u32) # numberSubtables
      # encoding record
      write_uint16(io, 3_u32)  # platformID Windows
      write_uint16(io, 1_u32)  # platformSpecificID Unicode BMP
      write_uint32(io, 12_u64) # offset 4 * 2 + 4

      # format 4 subtable
      search_range = 2 * (1 << log2(seg_count))
      write_uint16(io, 4_u32)                                 # format
      write_uint16(io, (8 * 2 + seg_count * 4 * 2).to_u32)    # length
      write_uint16(io, 0_u32)                                 # language
      write_uint16(io, (seg_count * 2).to_u32)                # segCountX2
      write_uint16(io, search_range.to_u32)                   # searchRange
      write_uint16(io, log2(search_range // 2).to_u32)        # entrySelector
      write_uint16(io, (2 * seg_count - search_range).to_u32) # rangeShift

      # endCode
      end_code.each { |end_code_val| write_uint16(io, end_code_val.to_u32) }
      # reservedPad
      write_uint16(io, 0_u32)
      # startCode
      start_code.each { |start_code_val| write_uint16(io, start_code_val.to_u32) }
      # idDelta
      id_delta.each { |delta| write_sint16(io, delta) }
      # idRangeOffset (all zero for simplicity)
      seg_count.times { write_uint16(io, 0_u32) }

      io.to_slice
    end

    private def build_hmtx_table : Bytes
      hm = @ttf.horizontal_metrics.not_nil!  # ameba:disable Lint/NotNil
      hhea = @ttf.horizontal_header.not_nil! # ameba:disable Lint/NotNil
      sorted = sorted_glyph_ids

      # compute number of HMetrics as in build_hhea_table
      hmetrics = sorted.count { |gid| gid < hhea.@number_of_h_metrics }
      if !sorted.empty? && sorted.last >= hhea.@number_of_h_metrics && !sorted.includes?(hhea.@number_of_h_metrics - 1)
        hmetrics += 1
      end

      total_glyphs = sorted.size
      io = IO::Memory.new(hmetrics * 4 + (total_glyphs - hmetrics) * 2)

      # write hMetrics pairs
      sorted.each_with_index do |old_gid, new_gid|
        break if new_gid >= hmetrics
        write_uint16(io, hm.advance_width(old_gid).to_u32)
        write_sint16(io, hm.left_side_bearing(old_gid).to_i32)
      end

      # write leftSideBearings for remaining glyphs
      sorted.each_with_index do |old_gid, new_gid|
        next if new_gid < hmetrics
        write_sint16(io, hm.left_side_bearing(old_gid).to_i32)
      end
      io.to_slice
    end

    private def build_post_table : Bytes?
      post = @ttf.table("post").as?(PostScriptTable)
      if post.nil? || post.glyph_names.nil? ||
         (keep = @keep_tables) && !keep.includes?(PostScriptTable::TAG)
        return
      end

      io = IO::Memory.new
      write_fixed(io, 2.0) # version
      write_fixed(io, post.italic_angle.to_f64)
      write_sint16(io, post.underline_position.to_i32)
      write_sint16(io, post.underline_thickness.to_i32)
      write_uint32(io, post.is_fixed_pitch)
      write_uint32(io, post.min_mem_type42)
      write_uint32(io, post.max_mem_type42)
      write_uint32(io, post.min_mem_type1)
      write_uint32(io, post.max_mem_type1)

      # version 2.0
      # numberOfGlyphs
      write_uint16(io, @glyph_ids.size.to_u32)

      # glyphNameIndex[numGlyphs]
      names = {} of String => Int32
      sorted_glyph_ids.each do |old_gid|
        name = post.name(old_gid) || ".undefined"
        mac_id = WGL4Names.glyph_index(name)
        if mac_id
          # the name is implicit, as it's from MacRoman
          write_uint16(io, mac_id.to_u32)
        else
          # the name will be written explicitly
          ordinal = names.fetch(name) do
            size = names.size
            names[name] = size
            size
          end
          write_uint16(io, (258 + ordinal).to_u32)
        end
      end

      # names[numberNewGlyphs]
      names.each_key do |name|
        buf = name.to_slice
        if buf.size > 255
          # truncate? According to spec, max 255 bytes
          buf = buf[0, 255]
        end
        write_uint8(io, buf.size.to_u32)
        io.write(buf)
      end

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

# Embedded PDCIDFontType2 builder. Helper to populate PDCIDFontType2 and parent
# PDType0Font from a TTF.
# Port of org.apache.pdfbox.pdmodel.font.PDCIDFontType2Embedder.
module Pdfbox::Pdmodel::Font
  class PDCIDFontType2Embedder < TrueTypeEmbedder
    @document : Document
    @parent : PDType0Font
    @dict : Cos::Dictionary
    @cid_font : Cos::Dictionary
    @vertical : Bool

    def initialize(@document : Document, @dict : Cos::Dictionary, ttf : Fontbox::TTF::TrueTypeFont,
                   embed_subset : Bool, @parent : PDType0Font, @vertical : Bool)
      super(@document, @dict, ttf, embed_subset)

      fd = @font_descriptor || raise "Font descriptor not initialized"
      fd

      # Parent Type 0 font
      @dict[Cos::Name::SUBTYPE] = Cos::Name::TYPE0
      @dict.set_name(Cos::Name::BASE_FONT, fd.font_name)
      @dict[Cos::Name::ENCODING] = @vertical ? Cos::Name::IDENTITY_V : Cos::Name::IDENTITY_H

      # Descendant CIDFont
      @cid_font = create_cid_font
      descendant_fonts = Cos::Array.new
      descendant_fonts << @cid_font
      @dict[Cos::Name.new("DescendantFonts")] = descendant_fonts

      unless embed_subset
        build_to_unicode_cmap(nil)
      end
    end

    # Rebuild a font subset.
    def build_subset(ttf_subset : ::IO, tag : String, gid_to_cid : Hash(Int32, Int32)) : Nil
      cid_to_gid = Hash(Int32, Int32).new
      gid_to_cid.each { |new_gid, old_cid| cid_to_gid[old_cid] = new_gid }

      build_to_unicode_cmap(gid_to_cid)
      build_vertical_metrics(cid_to_gid) if @vertical
      build_font_file2(ttf_subset)
      add_name_tag(tag)
      build_widths(cid_to_gid)
      build_cid_to_gid_map(cid_to_gid)
      build_cid_set(cid_to_gid)
    end

    private def build_to_unicode_cmap(new_gid_to_old_cid : Hash(Int32, Int32)?) : Nil
      to_uni_writer = ToUnicodeWriter.new
      has_surrogates = false
      max_glyphs = (mp = @ttf.maximum_profile || raise "maxp table missing"; mp.num_glyphs)

      (1..max_glyphs).each do |gid|
        cid = if new_gid_to_old_cid
                next unless new_gid_to_old_cid.has_key?(gid)
                new_gid_to_old_cid[gid]
              else
                gid
              end

        codes = @cmap_lookup.char_codes(cid)
        if codes && !codes.empty?
          code_point = codes[0]
          has_surrogates = true if code_point > 0xFFFF
          to_uni_writer.add(cid, String.new({code_point}))
        end
      end

      io = ::IO::Memory.new
      to_uni_writer.write_to(io)
      io.rewind

      stream = Pdmodel::Common::PDStream.new(@document, io, Cos::Name::FLATE_DECODE)

      if has_surrogates
        if @document.version < 1.5_f32
          @document.set_version(1.5_f32)
        end
      end

      @dict[Cos::Name::TO_UNICODE] = stream
    end

    private def to_cid_system_info(registry, ordering, supplement)
      info = Cos::Dictionary.new
      info.set_string(Cos::Name::REGISTRY, registry)
      info.set_string(Cos::Name::ORDERING, ordering)
      info.set_int(Cos::Name::SUPPLEMENT, supplement.to_i64)
      info
    end

    private def create_cid_font : Cos::Dictionary
      cid_font = Cos::Dictionary.new
      fd = @font_descriptor || raise "Font descriptor not initialized"
      fd

      cid_font[Cos::Name::TYPE] = Cos::Name::FONT
      cid_font[Cos::Name::SUBTYPE] = Cos::Name::CID_FONT_TYPE2
      cid_font.set_name(Cos::Name::BASE_FONT, fd.font_name)

      info = to_cid_system_info("Adobe", "Identity", 0)
      cid_font[Cos::Name.new("CIDSystemInfo")] = info
      cid_font[Cos::Name::FONT_DESC] = fd.cos_object

      build_widths_full(cid_font)
      if @vertical
        build_vertical_header(cid_font)
        build_vertical_metrics_full(cid_font)
      end

      cid_font[Cos::Name.new("CIDToGIDMap")] = Cos::Name::IDENTITY
      cid_font
    end

    private def add_name_tag(tag)
      fd = @font_descriptor || raise "Font descriptor not initialized"
      fd
      new_name = tag + fd.font_name
      @dict.set_name(Cos::Name::BASE_FONT, new_name)
      fd.font_name = new_name
      @cid_font.set_name(Cos::Name::BASE_FONT, new_name)
    end

    private def build_cid_to_gid_map(cid_to_gid)
      cid_max = cid_to_gid.keys.max? || 0
      buffer = Bytes.new(cid_max * 2 + 2, 0_u8)
      (0..cid_max).each do |cid|
        if gid = cid_to_gid[cid]?
          buffer[cid * 2] = ((gid >> 8) & 0xFF).to_u8
          buffer[cid * 2 + 1] = (gid & 0xFF).to_u8
        end
      end
      io = ::IO::Memory.new(buffer)
      stream = Pdmodel::Common::PDStream.new(@document, io, Cos::Name::FLATE_DECODE)
      @cid_font[Cos::Name.new("CIDToGIDMap")] = stream
    end

    private def build_cid_set(cid_to_gid)
      cid_max = cid_to_gid.keys.max? || 0
      bytes = Bytes.new(cid_max // 8 + 1, 0_u8)
      (0..cid_max).each do |cid|
        mask = 1 << (7 - cid % 8)
        bytes[cid // 8] |= mask.to_u8
      end
      io = ::IO::Memory.new(bytes)
      stream = Pdmodel::Common::PDStream.new(@document, io, Cos::Name::FLATE_DECODE)
      fd = @font_descriptor || raise "Font descriptor not initialized"
      fd.cid_set = stream
    end

    private def build_widths(cid_to_gid)
      scaling = 1000.0_f32 / (hdr = @ttf.header || raise "header table missing"; hdr.units_per_em)
      hmtx = @ttf.horizontal_metrics
      raise ::IO::Error.new("hmtx table missing") unless hmtx

      widths = Cos::Array.new
      ws = Cos::Array.new
      prev = Int32::MIN
      cid_to_gid.keys.sort!.each do |cid|
        gid = cid_to_gid[cid]
        width = (hmtx.advance_width(gid) * scaling).round.to_i64
        next if width == 1000
        if prev != cid - 1
          ws = Cos::Array.new
          widths << Cos::Integer.new(cid.to_i64)
          widths << ws
        end
        ws << Cos::Integer.new(width)
        prev = cid
      end
      @cid_font[Cos::Name::W] = widths
    end

    private def build_vertical_header(cid_font)
      vhea = @ttf.vertical_header
      unless vhea
        Log.warn { "Font set to vertical but has no 'vhea' table" }
        return false
      end
      scaling = 1000.0_f32 / (hdr = @ttf.header || raise "header table missing"; hdr.units_per_em)
      v = (vhea.ascender * scaling).round.to_i64
      w1 = (-vhea.advance_height_max * scaling).round.to_i64
      if v != 880 || w1 != -1000
        dw2 = Cos::Array.new
        dw2 << Cos::Integer.new(v)
        dw2 << Cos::Integer.new(w1)
        cid_font[Cos::Name.new("DW2")] = dw2
      end
      true
    end

    private def build_vertical_metrics(cid_to_gid)
      return unless build_vertical_header(@cid_font)
      scaling = 1000.0_f32 / (hdr = @ttf.header || raise "header table missing"; hdr.units_per_em)
      vhea = vh = @ttf.vertical_header || raise "vhea table missing"
      vh
      vmtx = @ttf.vertical_metrics
      glyf = @ttf.glyph
      hmtx = @ttf.horizontal_metrics
      v_y = (vhea.ascender * scaling).round.to_i64
      w1_default = (-vhea.advance_height_max * scaling).round.to_i64
      heights = Cos::Array.new
      w2 = Cos::Array.new
      prev = Int32::MIN
      cid_to_gid.keys.sort!.each do |cid|
        glyph = glyf.try(&.glyph(cid))
        next unless glyph
        height = ((glyph.y_maximum + (vmtx.try(&.top_side_bearing(cid)) || 0)) * scaling).round.to_i64
        advance = (-(vmtx.try(&.advance_height(cid)) || 0) * scaling).round.to_i64
        next if height == v_y && advance == w1_default
        if prev != cid - 1
          w2 = Cos::Array.new
          heights << Cos::Integer.new(cid.to_i64)
          heights << w2
        end
        w2 << Cos::Integer.new(advance)
        width = ((hmtx.try(&.advance_width(cid)) || 0) * scaling).round.to_i64
        w2 << Cos::Integer.new(width // 2)
        w2 << Cos::Integer.new(height)
        prev = cid
      end
      @cid_font[Cos::Name.new("W2")] = heights
    end

    private def build_widths_full(cid_font)
      cid_max = @ttf.number_of_glyphs
      widths_array = [] of Int32
      hmtx = @ttf.horizontal_metrics
      (0...cid_max).each do |cid|
        widths_array << cid
        widths_array << (hmtx.try(&.advance_width(cid)) || 0)
      end
      cid_font[Cos::Name::W] = build_widths_array(widths_array)
    end

    private def build_vertical_metrics_full(cid_font)
      return unless build_vertical_header(cid_font)
      cid_max = @ttf.number_of_glyphs
      metrics = [] of Int32
      glyf = @ttf.glyph
      vmtx = @ttf.vertical_metrics
      hmtx = @ttf.horizontal_metrics
      (0...cid_max).each do |cid|
        glyph = glyf.try(&.glyph(cid))
        if glyph
          metrics << cid
          metrics << (vmtx.try(&.advance_height(cid)) || 0)
          metrics << (hmtx.try(&.advance_width(cid)) || 0)
          metrics << (glyph.y_maximum + (vmtx.try(&.top_side_bearing(cid)) || 0))
        else
          metrics << Int32::MIN
        end
      end
      cid_font[Cos::Name.new("W2")] = build_vertical_metrics_array(metrics)
    end

    private def build_widths_array(widths)
      return Cos::Array.new if widths.size < 2
      scaling = 1000.0_f32 / (hdr = @ttf.header || raise "header table missing"; hdr.units_per_em)
      last_cid = widths[0].to_i64
      last_value = (widths[1] * scaling).round
      inner = Cos::Array.new
      outer = Cos::Array.new
      outer << Cos::Integer.new(last_cid)
      state = :first
      i = 2
      while i < widths.size - 1
        cid = widths[i].to_i64
        value = (widths[i + 1] * scaling).round
        case state
        when :first
          if cid == last_cid + 1 && value == last_value
            state = :serial
          elsif cid == last_cid + 1
            state = :bracket
            inner = Cos::Array.new
            inner << Cos::Integer.new(last_value)
          else
            inner = Cos::Array.new
            inner << Cos::Integer.new(last_value)
            outer << inner
            outer << Cos::Integer.new(cid)
          end
        when :bracket
          if cid == last_cid + 1 && value == last_value
            state = :serial
            outer << inner
            outer << Cos::Integer.new(last_cid)
          elsif cid == last_cid + 1
            inner << Cos::Integer.new(last_value)
          else
            state = :first
            inner << Cos::Integer.new(last_value)
            outer << inner
            outer << Cos::Integer.new(cid)
          end
        when :serial
          if cid != last_cid + 1 || value != last_value
            outer << Cos::Integer.new(last_cid)
            outer << Cos::Integer.new(last_value)
            outer << Cos::Integer.new(cid)
            state = :first
          end
        end
        last_value = value
        last_cid = cid
        i += 2
      end
      case state
      when :first
        inner = Cos::Array.new
        inner << Cos::Integer.new(last_value)
        outer << inner
      when :bracket
        inner << Cos::Integer.new(last_value)
        outer << inner
      when :serial
        outer << Cos::Integer.new(last_cid)
        outer << Cos::Integer.new(last_value)
      end
      outer
    end

    private def build_vertical_metrics_array(values)
      return Cos::Array.new if values.size < 4
      # Filter out MIN_VALUE entries (no glyph)
      filtered = [] of Int32
      i = 0
      while i < values.size - 3
        if values[i] != Int32::MIN
          filtered << values[i]
          filtered << values[i + 1]
          filtered << values[i + 2]
          filtered << values[i + 3]
        end
        i += 4
      end
      return Cos::Array.new if filtered.size < 4

      scaling = 1000.0_f32 / (hdr = @ttf.header || raise "header table missing"; hdr.units_per_em)
      last_cid = filtered[0].to_i64
      last_w1 = (-filtered[1] * scaling).round
      last_vx = (filtered[2] * scaling / 2).round
      last_vy = (filtered[3] * scaling).round
      inner = Cos::Array.new
      outer = Cos::Array.new
      outer << Cos::Integer.new(last_cid)
      state = :first
      i = 4
      while i < filtered.size - 3
        cid = filtered[i].to_i64
        w1_val = (-filtered[i + 1] * scaling).round
        vx_val = (filtered[i + 2] * scaling / 2).round
        vy_val = (filtered[i + 3] * scaling).round
        case state
        when :first
          if cid == last_cid + 1 && w1_val == last_w1 && vx_val == last_vx && vy_val == last_vy
            state = :serial
          elsif cid == last_cid + 1
            state = :bracket
            inner = Cos::Array.new
            inner << Cos::Integer.new(last_w1)
            inner << Cos::Integer.new(last_vx)
            inner << Cos::Integer.new(last_vy)
          else
            inner = Cos::Array.new
            inner << Cos::Integer.new(last_w1)
            inner << Cos::Integer.new(last_vx)
            inner << Cos::Integer.new(last_vy)
            outer << inner
            outer << Cos::Integer.new(cid)
          end
        when :bracket
          if cid == last_cid + 1 && w1_val == last_w1 && vx_val == last_vx && vy_val == last_vy
            state = :serial
            outer << inner
            outer << Cos::Integer.new(last_cid)
          elsif cid == last_cid + 1
            inner << Cos::Integer.new(last_w1)
            inner << Cos::Integer.new(last_vx)
            inner << Cos::Integer.new(last_vy)
          else
            state = :first
            inner << Cos::Integer.new(last_w1)
            inner << Cos::Integer.new(last_vx)
            inner << Cos::Integer.new(last_vy)
            outer << inner
            outer << Cos::Integer.new(cid)
          end
        when :serial
          if cid != last_cid + 1 || w1_val != last_w1 || vx_val != last_vx || vy_val != last_vy
            outer << Cos::Integer.new(last_cid)
            outer << Cos::Integer.new(last_w1)
            outer << Cos::Integer.new(last_vx)
            outer << Cos::Integer.new(last_vy)
            outer << Cos::Integer.new(cid)
            state = :first
          end
        end
        last_w1 = w1_val
        last_vx = vx_val
        last_vy = vy_val
        last_cid = cid
        i += 4
      end
      case state
      when :first
        inner = Cos::Array.new
        inner << Cos::Integer.new(last_w1)
        inner << Cos::Integer.new(last_vx)
        inner << Cos::Integer.new(last_vy)
        outer << inner
      when :bracket
        inner << Cos::Integer.new(last_w1)
        inner << Cos::Integer.new(last_vx)
        inner << Cos::Integer.new(last_vy)
        outer << inner
      when :serial
        outer << Cos::Integer.new(last_cid)
        outer << Cos::Integer.new(last_w1)
        outer << Cos::Integer.new(last_vx)
        outer << Cos::Integer.new(last_vy)
      end
      outer
    end

    def cid_font : PDCIDFont
      PDCIDFontType2.new(@cid_font, @parent, @ttf)
    end
  end
end

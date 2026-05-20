# Common functionality for embedding TrueType fonts.
# Port of org.apache.pdfbox.pdmodel.font.TrueTypeEmbedder.
module Pdfbox::Pdmodel::Font
  abstract class TrueTypeEmbedder
    include Subsetter

    BASE25 = "BCDEFGHIJKLMNOPQRSTUVWXYZ"

    # PDF spec required tables (if present), all others will be removed
    REQUIRED_TABLES = %w[head hhea loca maxp cvt prep glyf hmtx fpgm gasp]

    getter font_descriptor : PDFontDescriptor?
    getter? embed_subset : Bool

    @document : Document
    @ttf : Fontbox::TTF::TrueTypeFont
    @cmap_lookup : Fontbox::TTF::CmapLookup
    @subset_code_points = Set(Int32).new
    @all_glyph_ids = Set(Int32).new

    def initialize(@document : Document, dict : Cos::Dictionary, @ttf : Fontbox::TTF::TrueTypeFont,
                   @embed_subset : Bool)
      unless embedding_permitted?(ttf)
        raise ::IO::Error.new("This font does not permit embedding")
      end

      @font_descriptor = create_font_descriptor(ttf)
      @cmap_lookup = ttf.unicode_cmap_lookup(false)

      unless @embed_subset
        # Full embedding: set FontFile2 stream
        original_data = ttf.original_data
        if original_data
          # Check for TTC (TrueType Collection) header
          if original_data.size >= 4 && String.new(original_data[0, 4]) == "ttcf"
            raise ::IO::Error.new("Full embedding of TrueType font collections not supported")
          end
          stream = Pdmodel::Common::PDStream.new(document, original_data, Cos::Name::FLATE_DECODE)
          stream.cos_object.set_long(Cos::Name.new("Length1"), ttf.original_data_size.to_i64)
          fd = @font_descriptor || raise "Font descriptor not initialized"
          fd.font_file2 = stream
        end
      end

      dict.set_name(Cos::Name::BASE_FONT, ttf.name)
    end

    # Build FontFile2 from an input stream (for re-building after subset).
    def build_font_file2(ttf_stream : ::IO) : Nil
      parser = Fontbox::TTF::TTFParser.new
      @ttf = parser.parse_embedded(ttf_stream)

      unless embedding_permitted?(@ttf)
        raise ::IO::Error.new("This font does not permit embedding")
      end

      @font_descriptor ||= create_font_descriptor(@ttf)

      # Re-read stream data for PDStream
      ttf_stream.rewind
      stream = Pdmodel::Common::PDStream.new(@document, ttf_stream, Cos::Name::FLATE_DECODE)
      stream.cos_object.set_long(Cos::Name.new("Length1"), @ttf.original_data_size.to_i64)
      fd = @font_descriptor || raise "Font descriptor not initialized"
      fd.font_file2 = stream
    end

    # Returns true if the fsType in the OS/2 table permits embedding.
    def embedding_permitted?(ttf : Fontbox::TTF::TrueTypeFont) : Bool
      os2 = ttf.os2windows
      if os2
        fs_type = os2.fs_type
        masked = fs_type & 0x000F
        if masked == Fontbox::TTF::OS2WindowsMetricsTable::FSTYPE_RESTRICTED
          return false
        elsif (fs_type & Fontbox::TTF::OS2WindowsMetricsTable::FSTYPE_BITMAP_ONLY) != 0
          return false
        end
      end
      true
    end

    # Returns true if the fsType in the OS/2 table permits subsetting.
    private def subsetting_permitted?(ttf : Fontbox::TTF::TrueTypeFont) : Bool
      os2 = ttf.os2windows
      if os2 && (os2.fs_type & Fontbox::TTF::OS2WindowsMetricsTable::FSTYPE_NO_SUBSETTING) != 0
        return false
      end
      true
    end

    # Creates a new font descriptor dictionary for the given TTF.
    private def create_font_descriptor(ttf : Fontbox::TTF::TrueTypeFont) : PDFontDescriptor
      ttf_name = ttf.name
      os2 = ttf.os2windows
      raise ::IO::Error.new("os2 table is missing in font #{ttf_name}") unless os2
      post = ttf.postscript
      raise ::IO::Error.new("post table is missing in font #{ttf_name}") unless post

      fd = PDFontDescriptor.new
      fd.font_name = ttf_name

      hhea = ttf.horizontal_header

      # Flags
      fd.fixed_pitch = (post.is_fixed_pitch > 0 || (hhea = @ttf.horizontal_header; hhea ? hhea.number_of_h_metrics : 0) == 1)

      fs_selection = os2.fs_selection
      fd.italic = ((fs_selection & 0x1) != 0 || (fs_selection & 0x200) != 0)

      family_class = os2.family_class
      case family_class
      when Fontbox::TTF::OS2WindowsMetricsTable::FAMILY_CLASS_CLAREDON_SERIFS,
           Fontbox::TTF::OS2WindowsMetricsTable::FAMILY_CLASS_FREEFORM_SERIFS,
           Fontbox::TTF::OS2WindowsMetricsTable::FAMILY_CLASS_MODERN_SERIFS,
           Fontbox::TTF::OS2WindowsMetricsTable::FAMILY_CLASS_OLDSTYLE_SERIFS,
           Fontbox::TTF::OS2WindowsMetricsTable::FAMILY_CLASS_SLAB_SERIFS
        fd.serif = true
      when Fontbox::TTF::OS2WindowsMetricsTable::FAMILY_CLASS_SCRIPTS
        fd.script = true
      end

      fd.font_weight = os2.weight_class

      fd.symbolic = true
      fd.non_symbolic = false

      # ItalicAngle
      fd.italic_angle = post.italic_angle

      # FontBBox
      header = ttf.header
      scaling = 1000.0_f32 / (hdr = @ttf.header || raise "header table missing"; hdr.units_per_em)
      rect = Pdmodel::Common::PDRectangle.new(
        header.x_min * scaling,
        header.y_min * scaling,
        header.x_max * scaling,
        header.y_max * scaling
      )
      fd.font_bounding_box = rect

      # Ascent, Descent
      fd.ascent = (hdr2 = @ttf.horizontal_header || raise "hhea table missing"; hdr2.ascender) * scaling
      fd.descent = (hdr3 = @ttf.horizontal_header || raise "hhea table missing"; hdr3.descender) * scaling

      # CapHeight, XHeight
      if os2.version >= 1.2
        fd.cap_height = os2.cap_height * scaling
        fd.x_height = os2.height * scaling
      else
        cap_h_path = ttf.path("H")
        if cap_h_path && !cap_h_path.commands.empty?
          fd.cap_height = cap_h_path.bounds.height.round * scaling
        else
          fd.cap_height = (os2.typo_ascender + os2.typo_descender) * scaling
        end
        x_path = ttf.path("x")
        if x_path && !x_path.commands.empty?
          fd.x_height = x_path.bounds.height.round * scaling
        else
          fd.x_height = os2.typo_ascender / 2.0_f32 * scaling
        end
      end

      # StemV - estimate
      fd.stem_v = rect.width * 0.13_f32

      fd
    end

    def add_to_subset(code_point : Int32)
      @subset_code_points << code_point
    end

    def add_glyph_ids(glyph_ids : Set(Int32)) : Nil
      @all_glyph_ids.concat(glyph_ids)
    end

    def subset : Nil
      unless subsetting_permitted?(@ttf)
        raise ::IO::Error.new("This font does not permit subsetting")
      end
      raise "Subsetting is disabled" unless @embed_subset

      subsetter = Fontbox::TTF::TTFSubsetter.new(@ttf, REQUIRED_TABLES)
      @subset_code_points.each { |_| subsetter.add(cp) }
      subsetter.force_invisible('\u200B')
      subsetter.force_invisible('\u200C')
      subsetter.force_invisible('\u2060')
      subsetter.force_invisible('\uFEFF')

      unless @all_glyph_ids.empty?
        @all_glyph_ids.each { |gid| subsetter.add_glyph_id(gid) }
      end

      gid_to_cid = subsetter.gid_map
      tag = get_tag(gid_to_cid)
      subsetter.prefix = tag

      io = ::IO::Memory.new
      subsetter.write_to_stream(io)
      io.rewind

      build_subset(io, tag, gid_to_cid)
      @ttf.close if @ttf.responds_to?(:close)
    end

    def needs_subset? : Bool
      @embed_subset
    end

    # Rebuild a font subset (abstract - implemented by concrete subclass).
    abstract def build_subset(ttf_subset : ::IO, tag : String, gid_to_cid : Hash(Int32, Int32)) : Nil

    # Returns an uppercase 6-character unique tag for the given subset.
    def get_tag(gid_to_cid : Hash(Int32, Int32)) : String
      num = gid_to_cid.hash.to_i64.abs
      sb = String::Builder.new
      loop do
        div = num // 25
        mod = (num % 25).to_i32
        sb << BASE25[mod]
        num = div
        break if num == 0 || sb.bytesize >= 6
      end
      while sb.bytesize < 6
        sb << 'A'
      end
      sb << '+'
      sb.to_s
    end
  end
end

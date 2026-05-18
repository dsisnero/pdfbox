require "./cid_system_info"
require "./panose"
require "digest/crc32"
require "../../../fontbox/cff"
require "../../../fontbox/font_box_font"
require "../../../fontbox/pfb"
require "../../../fontbox/ttf"
require "../../../fontbox/type1"
require "../../../fontbox/util/bounding_box"
require "../../../fontbox/util/path"
require "../../io"

module Pdfbox::Pdmodel::Font
  enum FontFormat
    Pfb
    Ttf
    Otf
  end

  abstract class FontProvider
    abstract def debug_string : String?
    abstract def font_info : Array(FontInfo)
  end

  abstract class FontInfo
    abstract def post_script_name : String
    abstract def format : FontFormat
    abstract def cid_system_info : PDCIDSystemInfo?
    abstract def font : Fontbox::FontBoxFont?
    abstract def family_class : Int32
    abstract def weight_class : Int32
    abstract def code_page_range1 : Int32
    abstract def code_page_range2 : Int32
    abstract def mac_style : Int32
    abstract def panose : PDPanoseClassification?

    def true_type_font : Fontbox::TTF::TrueTypeFont?
      nil
    end

    def weight_class_as_panose : Int32
      case weight_class
      when -1, 0 then 0
      when 100   then 2
      when 200   then 3
      when 300   then 4
      when 400   then 5
      when 500   then 6
      when 600   then 7
      when 700   then 8
      when 800   then 9
      when 900   then 10
      else            0
      end
    end

    def code_page_range : UInt64
      range1 = code_page_range1.to_u32.to_u64
      range2 = code_page_range2.to_u32.to_u64
      (range2 << 32) | range1
    end

    def to_s(io : ::IO) : Nil
      io << post_script_name
      io << " ("
      io << format
      io << ", mac: 0x"
      io << mac_style.to_s(16)
      io << ", os/2: 0x"
      io << family_class.to_s(16)
      io << ", cid: "
      io << cid_system_info
      io << ')'
    end
  end

  class FontCache
    @cache = Hash(FontInfo, Fontbox::FontBoxFont).new
    @mutex = Thread::Mutex.new

    def add_font(info : FontInfo, font : Fontbox::FontBoxFont) : Nil
      @mutex.synchronize do
        @cache[info] = font
      end
    end

    def font(info : FontInfo) : Fontbox::FontBoxFont?
      @mutex.synchronize do
        @cache[info]?
      end
    end
  end

  class CffType1FontBoxFont < Fontbox::FontBoxFont
    getter font : Fontbox::CFF::CFFType1Font

    def initialize(@font : Fontbox::CFF::CFFType1Font)
    end

    def name : String
      @font.name
    end

    def font_bbox : Fontbox::Util::BoundingBox
      @font.font_b_box || Fontbox::Util::BoundingBox.new
    end

    def font_matrix : Array(Float32)
      numbers = @font.font_matrix
      return [0.001_f32, 0.0_f32, 0.0_f32, 0.001_f32, 0.0_f32, 0.0_f32] unless numbers && numbers.size >= 6

      numbers.map { |value| value.is_a?(Int32) ? value.to_f32 : value.to_f32 }
    end

    def path(name : String) : Fontbox::Util::Path
      @font.path(name)
    end

    def width(name : String) : Float32
      @font.type1_char_string(name).width.to_f32
    rescue
      0.0_f32
    end

    def has_glyph?(name : String) : Bool
      @font.name_to_gid(name) > 0
    end
  end

  class CffCidFontBoxFont < Fontbox::FontBoxFont
    getter font : Fontbox::CFF::CFFCIDFont

    def initialize(@font : Fontbox::CFF::CFFCIDFont)
    end

    def name : String
      @font.name
    end

    def font_bbox : Fontbox::Util::BoundingBox
      @font.font_b_box || Fontbox::Util::BoundingBox.new
    end

    def font_matrix : Array(Float32)
      numbers = @font.font_matrix
      return [0.001_f32, 0.0_f32, 0.0_f32, 0.001_f32, 0.0_f32, 0.0_f32] unless numbers && numbers.size >= 6

      numbers.map { |value| value.is_a?(Int32) ? value.to_f32 : value.to_f32 }
    end

    def path(name : String) : Fontbox::Util::Path
      cid = name.to_i?
      return Fontbox::Util::Path.new unless cid
      @font.path(cid)
    end

    def width(name : String) : Float32
      cid = name.to_i?
      return 0.0_f32 unless cid
      @font.type2_char_string(cid).width.to_f32
    rescue
      0.0_f32
    end

    def has_glyph?(name : String) : Bool
      cid = name.to_i?
      return false unless cid
      !path(cid.to_s).empty?
    end
  end

  class OpenTypeFontBoxFont < Fontbox::FontBoxFont
    getter font : Fontbox::TTF::OpenTypeFont
    getter cff_font : Fontbox::CFF::CFFFont?

    def initialize(@font : Fontbox::TTF::OpenTypeFont)
      @cff_font = @font.table(Fontbox::TTF::CFFTable::TAG).as?(Fontbox::TTF::CFFTable).try(&.font)
    end

    def name : String
      @font.name
    end

    def font_bbox : Fontbox::Util::BoundingBox
      header = @font.header
      return Fontbox::Util::BoundingBox.new unless header

      units_per_em = @font.units_per_em
      scale = units_per_em > 0 ? (1000.0_f32 / units_per_em.to_f32) : 1.0_f32

      Fontbox::Util::BoundingBox.new(
        header.x_min.to_f32 * scale,
        header.y_min.to_f32 * scale,
        header.x_max.to_f32 * scale,
        header.y_max.to_f32 * scale
      )
    end

    def font_matrix : Array(Float32)
      units_per_em = @font.units_per_em
      scale = units_per_em > 0 ? (1.0_f32 / units_per_em.to_f32) : 0.001_f32
      [scale, 0.0_f32, 0.0_f32, scale, 0.0_f32, 0.0_f32]
    end

    def path(name : String) : Fontbox::Util::Path
      if post_script? && supported_otf?
        cff_path(name)
      else
        gid = @font.name_to_gid(name)
        return Fontbox::Util::Path.new if gid <= 0 || gid >= @font.number_of_glyphs

        glyph = @font.glyph.try(&.glyph(gid))
        glyph ? glyph.path : Fontbox::Util::Path.new
      end
    end

    def width(name : String) : Float32
      if post_script? && supported_otf?
        gid = @font.name_to_gid(name)
        return 0.0_f32 if gid < 0
        cff = @cff_font
        return 0.0_f32 unless cff

        case cff
        when Fontbox::CFF::CFFCIDFont
          cff.type2_char_string(gid).width.to_f32
        when Fontbox::CFF::CFFType1Font
          cff.type1_char_string(name).width.to_f32
        else
          0.0_f32
        end
      else
        hmtx = @font.horizontal_metrics
        return 0.0_f32 unless hmtx

        gid = @font.name_to_gid(name)
        return 0.0_f32 if gid <= 0

        units_per_em = @font.units_per_em
        return hmtx.advance_width(gid).to_f32 if units_per_em <= 0

        hmtx.advance_width(gid).to_f32 * (1000.0_f32 / units_per_em.to_f32)
      end
    rescue
      0.0_f32
    end

    def has_glyph?(name : String) : Bool
      !path(name).empty?
    end

    def post_script? : Bool
      @font.post_script?
    end

    def supported_otf? : Bool
      @font.supported_otf?
    end

    def has_layout_tables? : Bool
      @font.has_layout_tables?
    end

    private def cff_path(name : String) : Fontbox::Util::Path
      cff = @cff_font
      return Fontbox::Util::Path.new unless cff

      case cff
      when Fontbox::CFF::CFFCIDFont
        gid = @font.name_to_gid(name)
        return Fontbox::Util::Path.new if gid < 0
        cff.path(gid)
      when Fontbox::CFF::CFFType1Font
        cff.path(name)
      else
        Fontbox::Util::Path.new
      end
    rescue
      Fontbox::Util::Path.new
    end
  end

  class PfbFontBoxFont < Fontbox::FontBoxFont
    @path : String
    @bbox : Fontbox::Util::BoundingBox
    @matrix : Array(Float32)
    @glyph_names : Set(String)

    getter name : String

    def initialize(@path : String, @name : String)
      ascii = ascii_segment(@path)
      @bbox = parse_font_bbox(ascii)
      @matrix = parse_font_matrix(ascii)
      @glyph_names = parse_glyph_names(ascii)
    end

    def font_bbox : Fontbox::Util::BoundingBox
      @bbox
    end

    def font_matrix : Array(Float32)
      @matrix
    end

    def path(name : String) : Fontbox::Util::Path
      Fontbox::Util::Path.new
    end

    def width(name : String) : Float32
      0.0_f32
    end

    def has_glyph?(name : String) : Bool
      @glyph_names.includes?(name)
    end

    private def ascii_segment(path : String) : String
      parser = Fontbox::Pfb::PfbParser.new(path)
      bytes = Bytes.new(parser.segment1.size) { |index| parser.segment1[index] }
      String.new(bytes)
    rescue
      ""
    end

    private def parse_font_bbox(ascii : String) : Fontbox::Util::BoundingBox
      match = ascii.match(/\/FontBBox\s+\{?\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\}?/)
      return Fontbox::Util::BoundingBox.new unless match

      Fontbox::Util::BoundingBox.new(
        match[1].to_f32,
        match[2].to_f32,
        match[3].to_f32,
        match[4].to_f32
      )
    end

    private def parse_font_matrix(ascii : String) : Array(Float32)
      match = ascii.match(/\/FontMatrix\s+\[\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\]/)
      return [0.001_f32, 0.0_f32, 0.0_f32, 0.001_f32, 0.0_f32, 0.0_f32] unless match

      (1..6).map { |index| match[index].to_f32 }
    end

    private def parse_glyph_names(ascii : String) : Set(String)
      names = Set(String).new
      ascii.scan(/dup\s+\d+\s+\/([^\s]+)\s+put/) do |match|
        names << match[1]
      end
      names
    end
  end

  class FileSystemFontProvider < FontProvider
    Log                  = ::Log.for(self)
    CHECKSUM_PLACEHOLDER = "-"

    enum DiskCacheStatus
      Rebuild
      Loaded
      Missing
    end

    class FileSystemFontInfo < FontInfo
      @provider : FileSystemFontProvider
      @path : String
      @post_script_name : String
      @format : FontFormat
      @cid_system_info : PDCIDSystemInfo?
      @weight_class : Int32
      @family_class : Int32
      @code_page_range1 : Int32
      @code_page_range2 : Int32
      @mac_style : Int32
      @panose : PDPanoseClassification?
      @font_box_font : Fontbox::FontBoxFont?
      @ttf : Fontbox::TTF::TrueTypeFont?
      @checksum : String
      @last_modified : Int64
      @font_mutex = Thread::Mutex.new

      def initialize(
        @path : String,
        @format : FontFormat,
        @post_script_name : String,
        @cid_system_info : PDCIDSystemInfo?,
        @weight_class : Int32,
        @family_class : Int32,
        @code_page_range1 : Int32,
        @code_page_range2 : Int32,
        @mac_style : Int32,
        @panose : PDPanoseClassification?,
        @provider : FileSystemFontProvider,
        @checksum : String = "",
        @last_modified : Int64 = ::File.info?(@path).try(&.modification_time.to_unix_ms) || 0_i64,
      )
      end

      getter post_script_name : String
      getter format : FontFormat
      getter cid_system_info : PDCIDSystemInfo?
      getter family_class : Int32
      getter weight_class : Int32
      getter code_page_range1 : Int32
      getter code_page_range2 : Int32
      getter mac_style : Int32
      getter panose : PDPanoseClassification?
      getter path : String
      getter checksum : String
      getter last_modified : Int64

      def font : Fontbox::FontBoxFont?
        @font_mutex.synchronize do
          cached = @provider.cache.font(self)
          return cached if cached

          loaded = load_font
          if loaded
            @provider.cache.add_font(self, loaded)
          end
          loaded
        end
      end

      def true_type_font : Fontbox::TTF::TrueTypeFont?
        @ttf ||= load_true_type_font
      end

      def to_s(io : ::IO) : Nil
        super(io)
        io << ' '
        io << @path
        io << ' '
        io << @checksum
        io << ' '
        io << @last_modified
      end

      private def load_font : Fontbox::FontBoxFont?
        case format
        when FontFormat::Pfb
          ::File.open(@path) do |file|
            Fontbox::Type1::Type1Font.create_with_pfb(file)
          end
        when FontFormat::Ttf
          ttf = true_type_font
          return unless ttf
          MappedFontBoxFont.new(ttf, @post_script_name)
        when FontFormat::Otf
          otf = true_type_font.as?(Fontbox::TTF::OpenTypeFont)
          return unless otf
          OpenTypeFontBoxFont.new(otf)
        end
      end

      private def load_true_type_font : Fontbox::TTF::TrueTypeFont?
        case format
        when FontFormat::Pfb
          nil
        when FontFormat::Ttf, FontFormat::Otf
          load_tt_or_otf_font
        end
      end

      private def load_tt_or_otf_font : Fontbox::TTF::TrueTypeFont?
        if @path.ends_with?(".ttc") || @path.ends_with?(".otc")
          File.open(@path) do |file|
            collection = Fontbox::TTF::TrueTypeCollection.new(file)
            begin
              collection.font_by_name(@post_script_name)
            ensure
              collection.close
            end
          end
        else
          parser = format == FontFormat::Otf ? Fontbox::TTF::OTFParser.new(false) : Fontbox::TTF::TTFParser.new(false)
          parser.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(@path))
        end
      rescue ex : ::Exception
        Log.warn(exception: ex) { "Could not load font #{@post_script_name} from #{@path}" }
        nil
      end
    end

    getter cache : FontCache

    @font_info : Array(FontInfo)
    @roots : Array(String)
    @disk_cache_status : DiskCacheStatus = DiskCacheStatus::Missing

    def initialize(@cache = FontCache.new, @roots = default_roots)
      @font_info = [] of FontInfo
      @font_info = scan_fonts
    end

    def debug_string : String?
      "FileSystemFontProvider(roots=#{@roots.join(",")}, fonts=#{@font_info.size})"
    end

    def font_info : Array(FontInfo)
      @font_info
    end

    def disk_cache_status : DiskCacheStatus
      @disk_cache_status
    end

    private def default_roots : Array(String)
      roots = Standard14Fonts::SYSTEM_FONT_DIRS.dup
      roots << File.dirname(Standard14Fonts::FALLBACK_TTF_PATH)
      roots.uniq
    end

    private def scan_fonts : Array(FontInfo)
      files = font_files
      unless files.empty?
        if cached_infos = load_disk_cache(files)
          @disk_cache_status = DiskCacheStatus::Loaded
          return cached_infos
        end
      end
      @disk_cache_status = files.empty? ? DiskCacheStatus::Missing : DiskCacheStatus::Rebuild

      infos = [] of FontInfo
      files.each do |path|
        ext = File.extname(path).downcase
        case ext
        when ".ttf"
          if info = ttf_or_otf_info(path, FontFormat::Ttf)
            infos << info
          end
        when ".otf"
          if info = ttf_or_otf_info(path, FontFormat::Otf)
            infos << info
          end
        when ".ttc", ".otc"
          infos.concat(ttc_infos(path))
        when ".pfb"
          if info = pfb_info(path)
            infos << info
          end
        end
      end
      save_disk_cache(infos)
      infos
    end

    private def font_files : Array(String)
      seen = Set(String).new
      files = [] of String
      @roots.each do |root|
        next unless Dir.exists?(root)
        Dir.glob(File.join(root, "**", "*")).sort.each do |path|
          next unless File.file?(path)
          next unless {".ttf", ".otf", ".ttc", ".otc", ".pfb"}.includes?(File.extname(path).downcase)
          next if seen.includes?(path)
          seen << path
          files << path
        end
      end
      files
    end

    private def ttf_or_otf_info(path : String, format : FontFormat) : FontInfo?
      headers = Fontbox::TTF::TTFParser.new(false).parse_table_headers(Pdfbox::IO::RandomAccessReadBufferedFile.new(path))
      return if headers.error

      build_font_info(path, format, headers)
    rescue ex : ::Exception
      Log.warn(exception: ex) { "Could not scan font headers from #{path}" }
      nil
    end

    private def ttc_infos(path : String) : Array(FontInfo)
      infos = [] of FontInfo
      file = ::File.new(path)
      begin
        processor = ->(headers : Fontbox::TTF::FontHeaders) do
          if !headers.error
            info = build_font_info(path, headers.open_type_post_script? ? FontFormat::Otf : FontFormat::Ttf, headers)
            infos << info if info
          end
          nil
        end
        Fontbox::TTF::TrueTypeCollection.process_all_font_headers(file, processor)
      ensure
        file.close
      end
      infos
    rescue ex : ::Exception
      Log.warn(exception: ex) { "Could not scan TTC headers from #{path}" }
      [] of FontInfo
    end

    private def pfb_info(path : String) : FontInfo?
      parser = Fontbox::Pfb::PfbParser.new(path)
      bytes = Bytes.new(parser.segment1.size) { |index| parser.segment1[index] }
      ascii = String.new(bytes)
      name = ascii.match(/\/FontName\s+\/([^\s]+)/).try(&.[1]) || File.basename(path, ".pfb")
      return if name.includes?('|')
      FileSystemFontInfo.new(
        path,
        FontFormat::Pfb,
        name,
        nil,
        -1,
        -1,
        0,
        0,
        -1,
        nil,
        self,
        compute_hash(path),
        file_last_modified(path)
      )
    rescue ex : ::Exception
      Log.warn(exception: ex) { "Could not scan PFB font #{path}" }
      nil
    end

    private def build_font_info(path : String, format : FontFormat, headers : Fontbox::TTF::FontHeaders) : FontInfo?
      post_script_name = headers.name || File.basename(path, File.extname(path))
      os2 = headers.os2_windows
      cid_info = nil
      if registry = headers.otf_registry
        if ordering = headers.otf_ordering
          cid_info = PDCIDSystemInfo.new(registry, ordering, headers.otf_supplement)
        end
      end
      panose = os2.try(&.panose).try { |bytes| bytes.size >= PDPanoseClassification::LENGTH ? PDPanoseClassification.new(bytes) : nil }

      FileSystemFontInfo.new(
        path,
        format,
        post_script_name,
        cid_info,
        os2.try(&.weight_class.to_i32) || -1,
        os2.try(&.family_class.to_i32) || -1,
        os2.try(&.code_page_range1.to_i32) || 0,
        os2.try(&.code_page_range2.to_i32) || 0,
        headers.header_mac_style || -1,
        panose,
        self,
        compute_hash(path),
        file_last_modified(path)
      )
    end

    private def save_disk_cache(infos : Array(FontInfo)) : Nil
      cache_file = disk_cache_file
      return unless cache_file

      begin
        file = ::File.new(cache_file, "w")
        begin
          infos.each do |info|
            next unless info.is_a?(FileSystemFontInfo)
            write_font_info(file, info)
          end
        ensure
          file.close
        end
      rescue ex : ::Exception
        Log.warn(exception: ex) { "Could not write font cache #{cache_file}" }
      end
    end

    private def write_font_info(io : ::IO, info : FileSystemFontInfo) : Nil
      ros = ""
      if cid = info.cid_system_info
        ros = "#{cid.registry}-#{cid.ordering}-#{cid.supplement}"
      end
      panose = ""
      if panose_data = info.panose
        panose = panose_data.bytes.hexstring
      end
      io << info.post_script_name.strip << '|'
      io << info.format << '|'
      io << ros << '|'
      io << hex_or_empty(info.weight_class) << '|'
      io << hex_or_empty(info.family_class) << '|'
      io << info.code_page_range1.to_u32.to_s(16) << '|'
      io << info.code_page_range2.to_u32.to_s(16) << '|'
      io << hex_or_empty(info.mac_style) << '|'
      io << panose << '|'
      io << File.expand_path(info.path) << '|'
      io << info.checksum << '|'
      io << info.last_modified
      io << '\n'
    end

    private def load_disk_cache(files : Array(String)) : Array(FontInfo)?
      cache_file = disk_cache_file
      return unless cache_file && ::File.exists?(cache_file)

      pending = files.map { |path| File.expand_path(path) }.to_set
      infos = [] of FontInfo

      begin
        file = ::File.new(cache_file)
        begin
          file.each_line do |line|
            info = parse_disk_cache_line(line)
            next unless info
            next unless ::File.exists?(info.path)

            keep = file_last_modified(info.path) == info.last_modified
            unless keep || skip_checksums?
              keep = compute_hash(info.path) == info.checksum
            end
            next unless keep

            infos << info
            pending.delete(File.expand_path(info.path))
          end
        ensure
          file.close
        end
      rescue ex : ::Exception
        Log.warn(exception: ex) { "Error loading font cache #{cache_file}" }
        return
      end

      return unless pending.empty?
      infos
    end

    private def parse_disk_cache_line(line : String) : FileSystemFontInfo?
      parts = line.rstrip.split('|', remove_empty: false)
      return if parts.size < 10

      format = FontFormat.parse?(parts[1])
      return unless format

      cid_info = parse_cid_system_info(parts[2])
      panose = parse_panose(parts[8])
      path = parts[9]
      checksum = parts.size >= 11 ? parts[10] : ""
      last_modified = parts.size >= 12 ? parts[11].to_i64 : file_last_modified(path)

      FileSystemFontInfo.new(
        path,
        format,
        parts[0],
        cid_info,
        parse_hex(parts[3], -1),
        parse_hex(parts[4], -1),
        parse_hex(parts[5], 0),
        parse_hex(parts[6], 0),
        parse_hex(parts[7], -1),
        panose,
        self,
        checksum,
        last_modified
      )
    rescue ex : ::Exception
      Log.warn(exception: ex) { "Incorrect line '#{line.rstrip}' in font disk cache is skipped" }
      nil
    end

    private def parse_cid_system_info(value : String) : PDCIDSystemInfo?
      return if value.empty?
      parts = value.split('-', 3)
      return unless parts.size == 3
      PDCIDSystemInfo.new(parts[0], parts[1], parts[2].to_i)
    end

    private def parse_panose(value : String) : PDPanoseClassification?
      return if value.empty? || value.size < PDPanoseClassification::LENGTH * 2
      bytes = Bytes.new(PDPanoseClassification::LENGTH) do |index|
        value[index * 2, 2].to_u8(16)
      end
      PDPanoseClassification.new(bytes)
    end

    private def parse_hex(value : String, default_value : Int32) : Int32
      return default_value if value.empty?
      value.to_u32(16).to_i32
    end

    private def hex_or_empty(value : Int32) : String
      value >= 0 ? value.to_u32.to_s(16) : ""
    end

    private def compute_hash(path : String) : String
      return CHECKSUM_PLACEHOLDER if skip_checksums?
      digest = Digest::CRC32.new
      ::File.open(path) do |file|
        buffer = Bytes.new(4096)
        while (read_bytes = file.read(buffer)) > 0
          digest.update(buffer[0, read_bytes])
        end
      end
      digest.hexfinal
    rescue ex : ::Exception
      Log.debug(exception: ex) { "Could not hash font #{path}" }
      ""
    end

    private def file_last_modified(path : String) : Int64
      ::File.info(path).modification_time.to_unix_ms
    rescue
      0_i64
    end

    private def disk_cache_file : String?
      path = ENV["PDFBOX_FONTCACHE"]?
      if path && !path.empty?
        return ::File.directory?(path) ? ::File.join(path, ".pdfbox.cache") : path
      end

      workspace_temp = ::File.expand_path("temp", Dir.current)
      return ::File.join(workspace_temp, ".pdfbox.cache") if Dir.exists?(workspace_temp)

      home = ENV["HOME"]?
      if home && Dir.exists?(home)
        return ::File.join(home, ".pdfbox.cache")
      end

      tmp = ENV["TMPDIR"]? || "/tmp"
      return ::File.join(tmp, ".pdfbox.cache") if Dir.exists?(tmp)
      nil
    end

    private def skip_checksums? : Bool
      ENV["PDFBOX_FONTCACHE_SKIPCHECKSUMS"]? == "true"
    end
  end
end

require "./font_descriptor"
require "./font_provider"
require "./standard14_fonts"
require "../../../fontbox/font_box_font"
require "../../../fontbox/ttf/true_type_font"
require "../../../fontbox/util/bounding_box"
require "../../../fontbox/util/path"

module Pdfbox::Pdmodel::Font
  class FontMapping(T)
    getter font : T
    @fallback : Bool

    def initialize(@font : T, @fallback : Bool)
    end

    def fallback? : Bool
      @fallback
    end
  end

  class MappedFontBoxFont < Fontbox::FontBoxFont
    getter ttf : Fontbox::TTF::TrueTypeFont
    getter name : String

    def initialize(@ttf : Fontbox::TTF::TrueTypeFont, @name : String)
    end

    def font_bbox : Fontbox::Util::BoundingBox
      header = @ttf.header
      return Fontbox::Util::BoundingBox.new if header.nil?

      Fontbox::Util::BoundingBox.new(
        header.x_min.to_f32,
        header.y_min.to_f32,
        header.x_max.to_f32,
        header.y_max.to_f32
      )
    end

    def font_matrix : Array(Float32)
      units_per_em = @ttf.units_per_em
      scale = units_per_em > 0 ? (1.0_f32 / units_per_em.to_f32) : 0.001_f32
      [scale, 0.0_f32, 0.0_f32, scale, 0.0_f32, 0.0_f32]
    end

    def path(name : String) : Fontbox::Util::Path
      gid = @ttf.name_to_gid(name)
      return Fontbox::Util::Path.new if gid <= 0 || gid >= @ttf.number_of_glyphs

      glyph = @ttf.glyph.try(&.glyph(gid))
      glyph ? glyph.path : Fontbox::Util::Path.new
    end

    def width(name : String) : Float32
      gid = @ttf.name_to_gid(name)
      return 0.0_f32 if gid <= 0

      hmtx = @ttf.horizontal_metrics
      return 0.0_f32 unless hmtx

      units_per_em = @ttf.units_per_em
      return hmtx.advance_width(gid).to_f32 if units_per_em <= 0

      hmtx.advance_width(gid).to_f32 * (1000.0_f32 / units_per_em.to_f32)
    end

    def has_glyph?(name : String) : Bool
      !path(name).empty?
    end
  end

  class CIDFontMapping < FontMapping(Fontbox::FontBoxFont?)
    getter true_type_font : Fontbox::FontBoxFont?

    def initialize(font : Fontbox::FontBoxFont?, @true_type_font : Fontbox::FontBoxFont?, fallback : Bool)
      super(font, fallback)
    end

    def cid_font? : Bool
      !font.nil?
    end
  end

  class FontMapperImpl
    Log                 = ::Log.for(self)
    JIS_JAPAN           = 1_u64 << 17
    CHINESE_SIMPLIFIED  = 1_u64 << 18
    KOREAN_WANSUNG      = 1_u64 << 19
    CHINESE_TRADITIONAL = 1_u64 << 20
    KOREAN_JOHAB        = 1_u64 << 21

    @substitutes = Hash(String, Array(String)).new
    @provider : FontProvider?
    @font_info_by_name : Hash(String, FontInfo)?
    @font_cache : FontCache

    private struct FontMatch
      include Comparable(FontMatch)

      getter info : FontInfo
      getter score : Float64

      def initialize(@info : FontInfo, @score : Float64)
      end

      def <=>(other : FontMatch)
        score <=> other.score
      end
    end

    def initialize
      @font_cache = FontCache.new

      Standard14Fonts::SUBSTITUTES.each do |match, replacements|
        @substitutes[normalize_lookup_key(match)] = replacements.dup
      end

      Standard14Fonts.names.each do |base_name|
        next if @substitutes.has_key?(normalize_lookup_key(base_name))
        mapped_name = Standard14Fonts.get_mapped_font_name(base_name)
        next unless mapped_name
        substitutes = @substitutes[normalize_lookup_key(mapped_name.to_s)]?
        @substitutes[normalize_lookup_key(base_name)] = substitutes.dup if substitutes
      end
    end

    def add_substitute(match : String, replace : String) : Nil
      key = normalize_lookup_key(match)
      replacements = (@substitutes[key]? || [] of String)
      replacements << replace unless replacements.includes?(replace)
      @substitutes[key] = replacements
    end

    def font_cache : FontCache
      @font_cache
    end

    def provider : FontProvider
      current = @provider
      return current if current

      fresh = FileSystemFontProvider.new(@font_cache)
      self.provider = fresh
      fresh
    end

    def provider=(font_provider : FontProvider) : Nil
      @provider = font_provider
      @font_info_by_name = create_font_info_by_name(font_provider.font_info)
    end

    def get_true_type_font(base_font : String?, font_descriptor : PDFontDescriptor?) : FontMapping(Fontbox::TTF::TrueTypeFont)
      font = find_true_type_font(base_font)
      return FontMapping(Fontbox::TTF::TrueTypeFont).new(font, false) if font

      fallback_name = fallback_font_name(font_descriptor)
      fallback_font = find_true_type_font(fallback_name) || load_last_resort_true_type_font(base_font || fallback_name)
      FontMapping(Fontbox::TTF::TrueTypeFont).new(fallback_font, true)
    end

    def get_font_box_font(base_font : String?, font_descriptor : PDFontDescriptor?) : FontMapping(Fontbox::FontBoxFont)
      found = find_font_box_font(base_font)
      return FontMapping(Fontbox::FontBoxFont).new(found, false) if found

      fallback_name = fallback_font_name(font_descriptor)
      fallback_font = find_font_box_font(fallback_name) || MappedFontBoxFont.new(load_last_resort_true_type_font(base_font || fallback_name), fallback_name)
      FontMapping(Fontbox::FontBoxFont).new(fallback_font, true)
    end

    def get_cid_font(base_font : String?, font_descriptor : PDFontDescriptor?, cid_system_info : PDCIDSystemInfo?) : CIDFontMapping
      otf = find_cid_font(base_font, cid_system_info)
      return CIDFontMapping.new(otf, nil, false) if otf

      ttf = find_font(FontFormat::Ttf, base_font).try(&.font)
      return CIDFontMapping.new(nil, ttf, false) if ttf

      substitute = cid_system_info && font_descriptor ? best_cid_font_match(font_descriptor, cid_system_info) : nil
      if substitute
        font = substitute.font
        if font.is_a?(CffCidFontBoxFont) || open_type_cid_font?(font)
          return CIDFontMapping.new(font, nil, true)
        end
        return CIDFontMapping.new(nil, font, true) if font
      end

      last_resort = MappedFontBoxFont.new(load_last_resort_true_type_font(base_font || fallback_font_name(font_descriptor)), "LiberationSans-Regular")
      CIDFontMapping.new(nil, last_resort, true)
    end

    private def create_font_info_by_name(fonts : Array(FontInfo)) : Hash(String, FontInfo)
      map = Hash(String, FontInfo).new
      fonts.each do |info|
        post_script_names(info.post_script_name).each do |name|
          map[normalize_lookup_key(name)] = info
        end
      end
      map
    end

    private def post_script_names(post_script_name : String) : Set(String)
      names = Set(String).new
      names << post_script_name
      names << post_script_name.gsub("-", "")
      names
    end

    private def find_true_type_font(post_script_name : String?) : Fontbox::TTF::TrueTypeFont?
      find_font(FontFormat::Ttf, post_script_name).try(&.true_type_font)
    end

    private def find_cid_font(post_script_name : String?, cid_system_info : PDCIDSystemInfo?) : Fontbox::FontBoxFont?
      font = find_font(FontFormat::Otf, post_script_name).try(&.font)
      return font if font && (!cid_system_info || font_matches_cid?(font, cid_system_info))
      nil
    end

    private def font_matches_cid?(font : Fontbox::FontBoxFont, cid_system_info : PDCIDSystemInfo) : Bool
      case font
      when CffCidFontBoxFont
        cff_font = font.font
        cff_font.registry == cid_system_info.registry &&
          cff_font.ordering == cid_system_info.ordering
      when OpenTypeFontBoxFont
        cff_font = font.cff_font
        return false unless cff_font.is_a?(Fontbox::CFF::CFFCIDFont)

        cff_font.registry == cid_system_info.registry &&
          cff_font.ordering == cid_system_info.ordering
      else
        false
      end
    end

    private def open_type_cid_font?(font : Fontbox::FontBoxFont?) : Bool
      return false unless font.is_a?(OpenTypeFontBoxFont)
      font.cff_font.is_a?(Fontbox::CFF::CFFCIDFont)
    end

    private def find_font_box_font(post_script_name : String?) : Fontbox::FontBoxFont?
      find_font(FontFormat::Pfb, post_script_name).try(&.font) ||
        find_font(FontFormat::Ttf, post_script_name).try(&.font) ||
        find_font(FontFormat::Otf, post_script_name).try(&.font)
    end

    private def find_font(format : FontFormat, post_script_name : String?) : FontInfo?
      return if post_script_name.nil? || post_script_name.empty?

      provider

      lookup_candidates(post_script_name).each do |candidate|
        info = font_info_by_name[normalize_lookup_key(candidate)]?
        return info if info && info.format == format
      end

      nil
    end

    private def best_cid_font_match(font_descriptor : PDFontDescriptor, cid_system_info : PDCIDSystemInfo) : FontInfo?
      return unless supported_collection?(cid_system_info)

      matches = provider.font_info.compact_map do |info|
        next unless info.format == FontFormat::Otf || info.format == FontFormat::Ttf
        next unless char_set_match?(cid_system_info, info)
        next if barcode_font?(info) && !probably_barcode_font?(font_descriptor)

        score = score_match(font_descriptor, info)
        FontMatch.new(info, score)
      end

      matches.max?.try(&.info)
    end

    private def supported_collection?(cid_system_info : PDCIDSystemInfo) : Bool
      collection = "#{cid_system_info.registry}-#{cid_system_info.ordering}"
      {"Adobe-GB1", "Adobe-CNS1", "Adobe-Japan1", "Adobe-Korea1"}.includes?(collection)
    end

    private def char_set_match?(requested : PDCIDSystemInfo, info : FontInfo) : Bool
      ordering = requested.ordering
      return false unless ordering

      actual = info.cid_system_info
      if actual
        return actual.registry == requested.registry && actual.ordering == ordering
      end

      code_page_range = info.code_page_range
      if info.post_script_name == "MalgunGothic-Semilight"
        code_page_range &= ~(JIS_JAPAN | CHINESE_SIMPLIFIED | CHINESE_TRADITIONAL)
      end

      case ordering
      when "GB1"
        (code_page_range & CHINESE_SIMPLIFIED) == CHINESE_SIMPLIFIED
      when "CNS1"
        (code_page_range & CHINESE_TRADITIONAL) == CHINESE_TRADITIONAL
      when "Japan1"
        (code_page_range & JIS_JAPAN) == JIS_JAPAN
      when "Korea1"
        (code_page_range & KOREAN_WANSUNG) == KOREAN_WANSUNG ||
          (code_page_range & KOREAN_JOHAB) == KOREAN_JOHAB
      else
        false
      end
    end

    private def barcode_font?(info : FontInfo) : Bool
      name = normalize_lookup_key(info.post_script_name)
      name.includes?("barcode") || info.post_script_name.starts_with?("Code")
    end

    private def probably_barcode_font?(font_descriptor : PDFontDescriptor) : Bool
      font_family = font_descriptor.font_family.to_s
      font_name = font_descriptor.font_name.to_s

      font_family.starts_with?("Code") ||
        font_family.downcase.includes?("barcode") ||
        font_name.starts_with?("Code") ||
        font_name.downcase.includes?("barcode")
    end

    private def score_match(font_descriptor : PDFontDescriptor, info : FontInfo) : Float64
      panose_score(font_descriptor, info) +
        weight_score(font_descriptor, info) +
        fixed_pitch_score(font_descriptor, info) +
        serif_score(font_descriptor, info) +
        italic_score(font_descriptor, info) +
        bold_score(font_descriptor, info) +
        family_name_score(font_descriptor, info)
    end

    private def expected_weight_class(font_descriptor : PDFontDescriptor) : Int32
      weight = font_descriptor.font_weight.round.to_i32
      return weight if weight > 0
      return 700 if bold_descriptor?(font_descriptor)
      400
    end

    private def fixed_pitch_match?(info : FontInfo) : Bool
      normalized_name = normalize_lookup_key(info.post_script_name)
      normalized_name.includes?("mono") || normalized_name.includes?("courier")
    end

    private def serif_match?(info : FontInfo) : Bool
      family = info.family_class
      (family >> 8) != Fontbox::TTF::OS2WindowsMetricsTable::FAMILY_CLASS_SANS_SERIF
    end

    private def italic_match?(info : FontInfo) : Bool
      (info.mac_style & Fontbox::TTF::HeaderTable::MAC_STYLE_ITALIC) != 0 ||
        normalize_lookup_key(info.post_script_name).includes?("italic") ||
        normalize_lookup_key(info.post_script_name).includes?("oblique")
    end

    private def bold_match?(info : FontInfo) : Bool
      (info.mac_style & Fontbox::TTF::HeaderTable::MAC_STYLE_BOLD) != 0 ||
        info.weight_class >= 700 ||
        normalize_lookup_key(info.post_script_name).includes?("bold")
    end

    private def font_info_by_name : Hash(String, FontInfo)
      @font_info_by_name ||= create_font_info_by_name(provider.font_info)
    end

    private def lookup_candidates(post_script_name : String) : Array(String)
      candidates = [] of String
      candidates << post_script_name
      candidates << post_script_name.gsub("-", "")
      substitutes_for(post_script_name).each { |substitute| candidates << substitute unless candidates.includes?(substitute) }

      windows_name = post_script_name.gsub(",", "-")
      candidates << windows_name unless candidates.includes?(windows_name)

      if comma = post_script_name.index(',')
        base_name = post_script_name[0...comma]
        candidates << base_name unless candidates.includes?(base_name)
        regular_name = "#{base_name}-Regular"
        candidates << regular_name unless candidates.includes?(regular_name)
      end

      regular_name = "#{post_script_name}-Regular"
      candidates << regular_name unless candidates.includes?(regular_name)
      candidates
    end

    private def panose_score(font_descriptor : PDFontDescriptor, info : FontInfo) : Float64
      descriptor_panose = font_descriptor.panose.try(&.panose)
      info_panose = info.panose
      return 0.0 unless descriptor_panose && info_panose
      return 0.0 unless descriptor_panose.family_kind == info_panose.family_kind

      if descriptor_panose.family_kind == 0 && barcode_font?(info) && !probably_barcode_font?(font_descriptor)
        return -100.0
      end

      serif_style_score(descriptor_panose, info_panose) + panose_weight_score(descriptor_panose, info_panose, info)
    end

    private def cove_serif?(value : Int32) : Bool
      value >= 2 && value <= 5
    end

    private def sans_serif?(value : Int32) : Bool
      value >= 11 && value <= 13
    end

    private def serif_style_score(
      descriptor_panose : PDPanoseClassification,
      info_panose : PDPanoseClassification,
    ) : Float64
      if descriptor_panose.serif_style == info_panose.serif_style
        2.0
      elsif cove_serif?(descriptor_panose.serif_style) && cove_serif?(info_panose.serif_style)
        1.0
      elsif sans_serif?(descriptor_panose.serif_style) && sans_serif?(info_panose.serif_style)
        1.0
      elsif descriptor_panose.serif_style != 0 && info_panose.serif_style != 0
        -1.0
      else
        0.0
      end
    end

    private def panose_weight_score(
      descriptor_panose : PDPanoseClassification,
      info_panose : PDPanoseClassification,
      info : FontInfo,
    ) : Float64
      weight = info_panose.weight
      weight_class = info.weight_class_as_panose
      weight = weight_class if (weight - weight_class).abs > 2

      if descriptor_panose.weight == weight
        2.0
      elsif descriptor_panose.weight > 1 && weight > 1
        1.0 - (descriptor_panose.weight - weight).abs * 0.5
      else
        0.0
      end
    end

    private def weight_score(font_descriptor : PDFontDescriptor, info : FontInfo) : Float64
      return 0.0 unless info.weight_class > 0

      expected_weight = expected_weight_class(font_descriptor)
      1.0 - (((expected_weight - info.weight_class).abs.to_f64 / 100.0) * 0.5)
    end

    private def fixed_pitch_score(font_descriptor : PDFontDescriptor, info : FontInfo) : Float64
      return 0.0 unless font_descriptor.fixed_pitch?
      fixed_pitch_match?(info) ? 2.0 : -2.0
    end

    private def serif_score(font_descriptor : PDFontDescriptor, info : FontInfo) : Float64
      if font_descriptor.serif?
        serif_match?(info) ? 2.0 : -2.0
      else
        serif_match?(info) ? 0.0 : 1.0
      end
    end

    private def italic_score(font_descriptor : PDFontDescriptor, info : FontInfo) : Float64
      return 0.0 unless font_descriptor.italic?
      italic_match?(info) ? 2.0 : -2.0
    end

    private def bold_score(font_descriptor : PDFontDescriptor, info : FontInfo) : Float64
      return 0.0 unless bold_descriptor?(font_descriptor)
      bold_match?(info) ? 2.0 : -2.0
    end

    private def family_name_score(font_descriptor : PDFontDescriptor, info : FontInfo) : Float64
      family = font_descriptor.font_family
      return 0.0 unless family

      normalized_family = normalize_lookup_key(family)
      normalized_name = normalize_lookup_key(info.post_script_name)
      normalized_name.includes?(normalized_family) ? 2.0 : 0.0
    end

    private def substitutes_for(post_script_name : String) : Array(String)
      @substitutes[normalize_lookup_key(post_script_name)]? || [] of String
    end

    private def fallback_font_name(font_descriptor : PDFontDescriptor?) : String
      return "Times-Roman" unless font_descriptor

      is_bold = bold_descriptor?(font_descriptor)
      is_italic = font_descriptor.italic?

      return fixed_pitch_fallback(is_bold, is_italic) if font_descriptor.fixed_pitch?
      return serif_fallback(is_bold, is_italic) if font_descriptor.serif?

      sans_fallback(is_bold, is_italic)
    end

    private def bold_descriptor?(font_descriptor : PDFontDescriptor) : Bool
      font_name = font_descriptor.font_name.to_s.downcase
      font_descriptor.force_bold? || font_name.includes?("bold") || font_name.includes?("black") || font_name.includes?("heavy")
    end

    private def fixed_pitch_fallback(is_bold : Bool, is_italic : Bool) : String
      return "Courier-BoldOblique" if is_bold && is_italic
      return "Courier-Bold" if is_bold
      return "Courier-Oblique" if is_italic
      "Courier"
    end

    private def serif_fallback(is_bold : Bool, is_italic : Bool) : String
      return "Times-BoldItalic" if is_bold && is_italic
      return "Times-Bold" if is_bold
      return "Times-Italic" if is_italic
      "Times-Roman"
    end

    private def sans_fallback(is_bold : Bool, is_italic : Bool) : String
      return "Helvetica-BoldOblique" if is_bold && is_italic
      return "Helvetica-Bold" if is_bold
      return "Helvetica-Oblique" if is_italic
      "Helvetica"
    end

    private def strip_subset_tag(post_script_name : String) : String
      if index = post_script_name.index('+')
        post_script_name[(index + 1)..]
      else
        post_script_name
      end
    end

    private def normalize_lookup_key(name : String) : String
      strip_subset_tag(name).gsub(/[,\s-]+/, "").downcase
    end

    private def load_last_resort_true_type_font(base_font : String) : Fontbox::TTF::TrueTypeFont
      info = find_font(FontFormat::Ttf, "LiberationSans-Regular")
      font = info.try(&.true_type_font)
      return font if font

      raise ::IO::Error.new("Fallback TrueType font not found for #{base_font}: #{Standard14Fonts::FALLBACK_TTF_PATH}")
    end
  end

  class FontMappers
    @@instance : FontMapperImpl?

    def self.instance : FontMapperImpl
      @@instance ||= FontMapperImpl.new
    end

    def self.set(font_mapper : FontMapperImpl) : FontMapperImpl
      @@instance = font_mapper
      font_mapper
    end
  end
end

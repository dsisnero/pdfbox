require "../../../spec_helper"

class SpecCFFCIDFont < Fontbox::CFF::CFFCIDFont
  def initialize(registry : String, ordering : String, supplement : Int32)
    super()
    self.name = "SpecCID"
    self.registry = registry
    self.ordering = ordering
    self.supplement = supplement
  end
end

class SpecFontInfo < Pdfbox::Pdmodel::Font::FontInfo
  @font : Fontbox::FontBoxFont?
  @cid_system_info : Pdfbox::Pdmodel::Font::PDCIDSystemInfo?
  @format : Pdfbox::Pdmodel::Font::FontFormat
  @post_script_name : String

  def initialize(
    @post_script_name : String,
    @format : Pdfbox::Pdmodel::Font::FontFormat,
    @font : Fontbox::FontBoxFont?,
    @cid_system_info : Pdfbox::Pdmodel::Font::PDCIDSystemInfo? = nil,
    @family_class : Int32 = -1,
    @weight_class : Int32 = 400,
    @code_page_range1 : Int32 = 0,
    @code_page_range2 : Int32 = 0,
    @mac_style : Int32 = 0,
    @panose : Pdfbox::Pdmodel::Font::PDPanoseClassification? = nil,
  )
  end

  getter post_script_name : String
  getter format : Pdfbox::Pdmodel::Font::FontFormat
  getter cid_system_info : Pdfbox::Pdmodel::Font::PDCIDSystemInfo?
  getter font : Fontbox::FontBoxFont?
  getter family_class : Int32
  getter weight_class : Int32
  getter code_page_range1 : Int32
  getter code_page_range2 : Int32
  getter mac_style : Int32
  getter panose : Pdfbox::Pdmodel::Font::PDPanoseClassification?
end

class SpecProvider < Pdfbox::Pdmodel::Font::FontProvider
  def initialize(@font_info : Array(Pdfbox::Pdmodel::Font::FontInfo))
  end

  def debug_string : String?
    "spec-provider"
  end

  getter font_info : Array(Pdfbox::Pdmodel::Font::FontInfo)
end

describe "FontMapper provider parity" do
  # PDFBox Java does not currently have a dedicated unit test class for FontMapperImpl or
  # FileSystemFontProvider. These specs are intentionally source-derived from the Java
  # implementation and are kept scoped to observable provider/mapper behavior.
  fonts_dir = File.expand_path("../../../../vendor/pdfbox/fontbox/target/fonts", __DIR__)

  it "supports FontMappers singleton replacement and Java-style mapping wrappers" do
    original = Pdfbox::Pdmodel::Font::FontMappers.instance
    begin
      custom = Pdfbox::Pdmodel::Font::FontMapperImpl.new
      Pdfbox::Pdmodel::Font::FontMappers.set(custom).should be(custom)
      Pdfbox::Pdmodel::Font::FontMappers.instance.should be(custom)

      mapping = Pdfbox::Pdmodel::Font::FontMapping(String).new("MappedFont", true)
      mapping.font.should eq("MappedFont")
      mapping.fallback?.should be_true

      cid_mapping = Pdfbox::Pdmodel::Font::CIDFontMapping.new(nil, nil, false)
      cid_mapping.cid_font?.should be_false
      cid_mapping.true_type_font.should be_nil
      cid_mapping.fallback?.should be_false

      Pdfbox::Pdmodel::Font::FontFormat.parse("Ttf").should eq(Pdfbox::Pdmodel::Font::FontFormat::Ttf)
      Pdfbox::Pdmodel::Font::FontFormat.parse("Otf").should eq(Pdfbox::Pdmodel::Font::FontFormat::Otf)
      Pdfbox::Pdmodel::Font::FontFormat.parse("Pfb").should eq(Pdfbox::Pdmodel::Font::FontFormat::Pfb)
    ensure
      Pdfbox::Pdmodel::Font::FontMappers.set(original)
    end
  end

  it "scans filesystem font info and exposes debug output" do
    pending("Font fixture directory not found: #{fonts_dir}") unless Dir.exists?(fonts_dir)

    provider = Pdfbox::Pdmodel::Font::FileSystemFontProvider.new(
      Pdfbox::Pdmodel::Font::FontCache.new,
      [fonts_dir]
    )

    provider.font_info.should_not be_empty
    provider.debug_string.should contain("FileSystemFontProvider")
  end

  it "indexes TTF and OTF entries through the provider" do
    pending("Font fixture directory not found: #{fonts_dir}") unless Dir.exists?(fonts_dir)

    provider = Pdfbox::Pdmodel::Font::FileSystemFontProvider.new(
      Pdfbox::Pdmodel::Font::FontCache.new,
      [fonts_dir]
    )

    provider.font_info.any? { |info| info.format == Pdfbox::Pdmodel::Font::FontFormat::Ttf }.should be_true
    provider.font_info.any? { |info| info.format == Pdfbox::Pdmodel::Font::FontFormat::Otf }.should be_true
  end

  it "loads PFB and OTF FontBox fonts through the shared mapper" do
    pending("Font fixture directory not found: #{fonts_dir}") unless Dir.exists?(fonts_dir)

    provider = Pdfbox::Pdmodel::Font::FileSystemFontProvider.new(
      Pdfbox::Pdmodel::Font::FontCache.new,
      [fonts_dir]
    )
    mapper = Pdfbox::Pdmodel::Font::FontMapperImpl.new
    mapper.provider = provider

    pfb_info = provider.font_info.find { |info| info.format == Pdfbox::Pdmodel::Font::FontFormat::Pfb }
    if pfb_info
      pfb_mapping = mapper.get_font_box_font(pfb_info.post_script_name, nil)
      pfb_mapping.fallback?.should be_false
      pfb_mapping.font.should be_a(Fontbox::Type1::Type1Font)
      pfb_mapping.font.name.should eq(pfb_info.post_script_name)
    end

    otf_info = provider.font_info.find { |info| info.format == Pdfbox::Pdmodel::Font::FontFormat::Otf }
    if otf_info
      otf_mapping = mapper.get_font_box_font(otf_info.post_script_name, nil)
      otf_mapping.fallback?.should be_false
      otf_mapping.font.should be_a(Pdfbox::Pdmodel::Font::OpenTypeFontBoxFont | Fontbox::CFF::CFFFont)
      otf_mapping.font.name.should eq(otf_info.post_script_name)
    end
  end

  it "reuses the on-disk filesystem font cache when the scanned files match" do
    pending("Font fixture directory not found: #{fonts_dir}") unless Dir.exists?(fonts_dir)

    cache_dir = File.expand_path("../../../../temp/font-provider-cache", __DIR__)
    Dir.mkdir_p(cache_dir)
    cache_file = File.join(cache_dir, ".pdfbox.cache")
    previous_cache = ENV["PDFBOX_FONTCACHE"]?
    begin
      ENV["PDFBOX_FONTCACHE"] = cache_dir
      File.delete(cache_file) if File.exists?(cache_file)

      initial_provider = Pdfbox::Pdmodel::Font::FileSystemFontProvider.new(
        Pdfbox::Pdmodel::Font::FontCache.new,
        [fonts_dir]
      )
      initial_provider.disk_cache_status.should eq(Pdfbox::Pdmodel::Font::FileSystemFontProvider::DiskCacheStatus::Rebuild)

      cached_provider = Pdfbox::Pdmodel::Font::FileSystemFontProvider.new(
        Pdfbox::Pdmodel::Font::FontCache.new,
        [fonts_dir]
      )
      cached_provider.disk_cache_status.should eq(Pdfbox::Pdmodel::Font::FileSystemFontProvider::DiskCacheStatus::Loaded)
      cached_provider.font_info.size.should eq(initial_provider.font_info.size)
      cached_provider.debug_string.should contain("FileSystemFontProvider")
    ensure
      if previous_cache
        ENV["PDFBOX_FONTCACHE"] = previous_cache
      else
        ENV.delete("PDFBOX_FONTCACHE")
      end
    end
  end

  it "maps CID OpenType fonts through cid system info" do
    cid_system_info = Pdfbox::Pdmodel::Font::PDCIDSystemInfo.new("Adobe", "Japan1", 6)
    cid_font = SpecCFFCIDFont.new("Adobe", "Japan1", 6)
    provider = SpecProvider.new([
      SpecFontInfo.new(
        "SpecCIDFont",
        Pdfbox::Pdmodel::Font::FontFormat::Otf,
        Pdfbox::Pdmodel::Font::CffCidFontBoxFont.new(cid_font),
        cid_system_info
      ),
    ] of Pdfbox::Pdmodel::Font::FontInfo)
    mapper = Pdfbox::Pdmodel::Font::FontMapperImpl.new
    mapper.provider = provider
    mapping = mapper.get_cid_font("SpecCIDFont", nil, cid_system_info)

    mapping.cid_font?.should be_true
    mapping.font.should be_a(Fontbox::FontBoxFont)
    mapping.true_type_font.should be_nil
  end

  it "matches CID fallback fonts through code page ranges when ROS metadata is absent" do
    descriptor = Pdfbox::Pdmodel::Font::PDFontDescriptor.new(Pdfbox::Cos::Dictionary.new)
    descriptor.font_family = "Sans"
    descriptor.font_weight = 400

    cid_system_info = Pdfbox::Pdmodel::Font::PDCIDSystemInfo.new("Adobe", "Japan1", 6)
    japan_code_page = (1 << 17)
    ttf = Fontbox::TTF::TTFParser.new.parse(
      Pdfbox::IO::RandomAccessReadBufferedFile.new(
        Pdfbox::Pdmodel::Font::Standard14Fonts::FALLBACK_TTF_PATH
      )
    )

    provider = SpecProvider.new([
      SpecFontInfo.new(
        "JapaneseFallback",
        Pdfbox::Pdmodel::Font::FontFormat::Ttf,
        Pdfbox::Pdmodel::Font::MappedFontBoxFont.new(ttf, "JapaneseFallback"),
        nil,
        -1,
        400,
        japan_code_page,
        0
      ),
    ] of Pdfbox::Pdmodel::Font::FontInfo)

    mapper = Pdfbox::Pdmodel::Font::FontMapperImpl.new
    mapper.provider = provider

    mapping = mapper.get_cid_font("MissingCIDFont", descriptor, cid_system_info)
    mapping.cid_font?.should be_false
    mapping.true_type_font.should be_a(Fontbox::FontBoxFont)
    mapping.fallback?.should be_true
  end

  it "skips barcode-style CID fallbacks unless the descriptor looks like a barcode font" do
    descriptor = Pdfbox::Pdmodel::Font::PDFontDescriptor.new(Pdfbox::Cos::Dictionary.new)
    descriptor.font_family = "Sans"
    descriptor.font_weight = 400

    cid_system_info = Pdfbox::Pdmodel::Font::PDCIDSystemInfo.new("Adobe", "Japan1", 6)
    japan_code_page = (1 << 17)
    ttf = Fontbox::TTF::TTFParser.new.parse(
      Pdfbox::IO::RandomAccessReadBufferedFile.new(
        Pdfbox::Pdmodel::Font::Standard14Fonts::FALLBACK_TTF_PATH
      )
    )

    provider = SpecProvider.new([
      SpecFontInfo.new(
        "Code128Barcode",
        Pdfbox::Pdmodel::Font::FontFormat::Ttf,
        Pdfbox::Pdmodel::Font::MappedFontBoxFont.new(ttf, "Code128Barcode"),
        nil,
        -1,
        400,
        japan_code_page,
        0
      ),
      SpecFontInfo.new(
        "JapaneseSans",
        Pdfbox::Pdmodel::Font::FontFormat::Ttf,
        Pdfbox::Pdmodel::Font::MappedFontBoxFont.new(ttf, "JapaneseSans"),
        nil,
        -1,
        400,
        japan_code_page,
        0
      ),
    ] of Pdfbox::Pdmodel::Font::FontInfo)

    mapper = Pdfbox::Pdmodel::Font::FontMapperImpl.new
    mapper.provider = provider

    mapping = mapper.get_cid_font("MissingCIDFont", descriptor, cid_system_info)
    mapping.fallback?.should be_true
    mapping.true_type_font.should_not be_nil
    mapping.true_type_font.not_nil!.name.should eq("JapaneseSans")
  end
end

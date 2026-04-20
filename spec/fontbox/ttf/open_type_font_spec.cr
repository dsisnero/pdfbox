require "../../spec_helper"

describe Fontbox::TTF::OpenTypeFont do
  # Upstream Java coverage for OTFParser/OpenTypeFont is indirect rather than class-local:
  # - fontbox/src/test/java/org/apache/fontbox/ttf/GlyfCompositeDescriptTest.java
  # - fontbox/src/test/java/org/apache/fontbox/ttf/GlyphSubstitutionTableLiberationFontTest.java
  # This spec keeps that contract explicit and only adds a standalone OTF check as supplemental
  # source-derived coverage for the PostScript/CFF branch.
  fonts_dir = File.expand_path("../../../vendor/pdfbox/fontbox/target/fonts", __DIR__)
  otf_path = File.join(fonts_dir, "SourceSansProBold.otf")
  liberation_ttf_path = File.expand_path("../../../vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf", __DIR__)

  it "parses TrueType outlines through OTFParser like the upstream Java tests" do
    pending("Font fixture not found: #{liberation_ttf_path}") unless File.exists?(liberation_ttf_path)

    font = Fontbox::TTF::OTFParser.new.parse(
      Pdfbox::IO::RandomAccessReadBufferedFile.new(liberation_ttf_path)
    )

    font.should be_a(Fontbox::TTF::OpenTypeFont)
    font.post_script?.should be_false
    font.supported_otf?.should be_true
    font.glyph.should_not be_nil
    font.path("A").should_not be_empty
  end

  it "parses standalone OpenType/CFF fonts through OTFParser" do
    pending("Font fixture not found: #{otf_path}") unless File.exists?(otf_path)

    font = Fontbox::TTF::OTFParser.new.parse(
      Pdfbox::IO::RandomAccessReadBufferedFile.new(otf_path)
    )

    font.should be_a(Fontbox::TTF::OpenTypeFont)
    font.post_script?.should be_true
    font.supported_otf?.should be_true
    font.cff.should be_a(Fontbox::TTF::CFFTable)
    font.has_layout_tables?.should be_a(Bool)
    charset = font.cff.font.try(&.charset)
    glyph_name = nil
    (1..32).each do |gid|
      glyph_name = charset.try(&.name_for_gid(gid))
      break if glyph_name
    end
    glyph_name.should_not be_nil
    font.path(glyph_name.as(String)).should be_a(Fontbox::Util::Path)
    expect_raises(IO::Error, "OTF fonts do not have a glyf table") do
      font.glyph
    end
  end
end

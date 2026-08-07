require "../../spec_helper"

describe Fontbox::TTF::OpenTypeFont do
  # Upstream Java coverage for OTFParser/OpenTypeFont is indirect rather than class-local:
  # - fontbox/src/test/java/org/apache/fontbox/ttf/GlyfCompositeDescriptTest.java
  # - fontbox/src/test/java/org/apache/fontbox/ttf/GlyphSubstitutionTableLiberationFontTest.java
  # This spec keeps that contract explicit and only adds a standalone OTF check as supplemental
  # source-derived coverage for the PostScript/CFF branch.
  fonts_dir = SpecPaths.resolve("vendor/pdfbox/fontbox/target/fonts")
  otf_path = File.join(fonts_dir, "SourceSansProBold.otf")
  liberation_ttf_path = SpecPaths.resolve("vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")

  it "parses TrueType outlines through OTFParser like the upstream Java tests" do
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
    font = Fontbox::TTF::OTFParser.new.parse(
      Pdfbox::IO::RandomAccessReadBufferedFile.new(otf_path)
    )

    font.should be_a(Fontbox::TTF::OpenTypeFont)
    font.post_script?.should be_true
    font.supported_otf?.should be_true

    expect_raises(IO::Error, "OTF fonts do not have a glyf table") do
      font.glyph
    end

    font.path("A").should_not be_empty
  end
end

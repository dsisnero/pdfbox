require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/fontbox/src/test/java/org/apache/fontbox/ttf/GlyphSubstitutionTableLiberationFontTest.java
#
# Loads LiberationSans-Regular.ttf (vendored under the Java fontbox test
# resources) and exercises the GSUB table's script/feature data: default script
# is "latn", unsupported script tags yield null, the "cyrl" script exposes the
# "subs"/"sups" features, and all 7 supported script tags load with language
# UNSPECIFIED.

module Fontbox::TTF
  LIBERATION_TTF = "vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf"

  private def self.with_liberation_font(&)
    font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(LIBERATION_TTF))
    begin
      yield font
    ensure
      font.close
    end
  end

  describe GlyphSubstitutionTable do
    it "getGsubData() with no args yields latn" do
      with_liberation_font do |font|
        font.gsub_data.active_script_name.should eq("latn")
      end
    end

    it "getGsubData() for an unsupported script yields null" do
      with_liberation_font do |font|
        gsub = font.gsub.not_nil!
        gsub.gsub_data("<some_non_existent_script_tag>").should be_nil
      end
    end

    it "getGsubData() for 'cyrl' tag yields GSUB features of Cyrillic script" do
      with_liberation_font do |font|
        gsub = font.gsub.not_nil!
        cyrillic_script_tag = "cyrl"
        expected_features = Set(String).new(["subs", "sups"])

        cyrillic_gsub_data = gsub.gsub_data(cyrillic_script_tag)
        cyrillic_gsub_data.should_not be_nil
        cyrillic_gsub_data.not_nil!.active_script_name.should eq(cyrillic_script_tag)
        cyrillic_gsub_data.not_nil!.supported_features.should eq(expected_features)
      end
    end

    it "all the script tags are loaded from GSUB as is" do
      with_liberation_font do |font|
        gsub = font.gsub.not_nil!
        expected_set = Set(String).new(["DFLT", "bopo", "copt", "cyrl", "grek", "hebr", "latn"])
        gsub.supported_script_tags.should eq(expected_set)
      end
    end

    it "GSUB data is loaded for all scripts supported by the font" do
      with_liberation_font do |font|
        gsub = font.gsub.not_nil!
        ["DFLT", "bopo", "copt", "cyrl", "grek", "hebr", "latn"].each do |script_tag|
          gsub_data = gsub.gsub_data(script_tag)
          gsub_data.should_not be_nil
          gsub_data.should_not eq(Model::GsubData::NO_DATA_FOUND)

          gsub_data.not_nil!.language.should eq(Model::Language::UNSPECIFIED)
          gsub_data.not_nil!.active_script_name.should eq(script_tag)
        end
      end
    end
  end
end

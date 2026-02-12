require "../../spec_helper"

module Fontbox::TTF
  private def self.liberation_sans_ttf
    File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
  end

  describe GlyphSubstitutionTable do
    describe "with LiberationSans-Regular.ttf" do
      it "getGsubData() with no args yields latn" do
        font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(liberation_sans_ttf))
        begin
          gsub_data = font.gsub_data
          gsub_data.get_active_script_name.should eq("latn")
        ensure
          font.close
        end
      end

      it "getGsubData() for an unsupported script yields nil" do
        font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(liberation_sans_ttf))
        begin
          gsub_table = font.table(GlyphSubstitutionTable::TAG).as(GlyphSubstitutionTable)
          gsub_data = gsub_table.get_gsub_data("<some_non_existent_script_tag>")
          gsub_data.should be_nil
        ensure
          font.close
        end
      end

      it "getGsubData() for 'cyrl' tag yields GSUB features of Cyrillic script" do
        font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(liberation_sans_ttf))
        begin
          gsub_table = font.table(GlyphSubstitutionTable::TAG).as(GlyphSubstitutionTable)
          cyrillic_script_tag = "cyrl"
          expected_features = ["subs", "sups"]

          cyrillic_gsub_data = gsub_table.get_gsub_data(cyrillic_script_tag)
          cyrillic_gsub_data.should_not be_nil
          gsub_data = cyrillic_gsub_data.not_nil!
          gsub_data.as(Model::MapBackedGsubData).get_active_script_name.should eq(cyrillic_script_tag)
          gsub_data.get_supported_features.should eq(Set.new(expected_features))
        ensure
          font.close
        end
      end

      it "All the script tags are loaded from GSUB as is" do
        font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(liberation_sans_ttf))
        begin
          gsub_table = font.table(GlyphSubstitutionTable::TAG).as(GlyphSubstitutionTable)
          expected_set = Set.new(["DFLT", "bopo", "copt", "cyrl", "grek", "hebr", "latn"])

          supported_script_tags = gsub_table.get_supported_script_tags
          supported_script_tags.should eq(expected_set)
        ensure
          font.close
        end
      end

      # Parameterized test for all supported scripts
      ["DFLT", "bopo", "copt", "cyrl", "grek", "hebr", "latn"].each do |script_tag|
        it "GSUB data is loaded for script #{script_tag}" do
          font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(liberation_sans_ttf))
          begin
            gsub_table = font.table(GlyphSubstitutionTable::TAG).as(GlyphSubstitutionTable)
            gsub_data = gsub_table.get_gsub_data(script_tag)

            gsub_data.should_not be_nil
            gsub_data.should_not eq(Model::GsubData::NO_DATA_FOUND)
            data = gsub_data.not_nil!
            data.get_language.should eq(Model::Language::UNSPECIFIED)
            data.as(Model::MapBackedGsubData).get_active_script_name.should eq(script_tag)
          ensure
            font.close
          end
        end
      end
    end

    it "parses GSUB script list and exposes script-specific gsub data" do
      font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(liberation_sans_ttf))
      begin
        gsub_table = font.table(GlyphSubstitutionTable::TAG)
        gsub_table.should_not be_nil
        gsub = gsub_table.as(GlyphSubstitutionTable)
        gsub.initialized.should be_true

        supported_script_tags = gsub.get_supported_script_tags
        supported_script_tags.includes?("latn").should be_true
        supported_script_tags.includes?("cyrl").should be_true

        cyrl_data = gsub.get_gsub_data("cyrl")
        cyrl_data.should_not be_nil
        data = cyrl_data.not_nil!
        data.as(Model::MapBackedGsubData).get_active_script_name.should eq("cyrl")
        data.as(Model::MapBackedGsubData).get_supported_features.empty?.should be_false
      ensure
        font.close
      end
    end
  end
end

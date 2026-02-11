require "../../spec_helper"

module Fontbox::TTF
  describe GlyphSubstitutionTable do
    it "parses GSUB script list and exposes script-specific gsub data" do
      font_path = File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
      font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))

      gsub_table = font.get_table(GlyphSubstitutionTable::TAG)
      gsub_table.should_not be_nil
      gsub = gsub_table.as(GlyphSubstitutionTable)
      gsub.get_initialized.should be_true

      supported_script_tags = gsub.get_supported_script_tags
      supported_script_tags.includes?("latn").should be_true
      supported_script_tags.includes?("cyrl").should be_true

      cyrl_data = gsub.get_gsub_data("cyrl")
      cyrl_data.should_not be_nil
      cyrl_data.as(Model::MapBackedGsubData).get_active_script_name.should eq("cyrl")
      cyrl_data.as(Model::MapBackedGsubData).get_supported_features.empty?.should be_false

      font.close
    end
  end
end

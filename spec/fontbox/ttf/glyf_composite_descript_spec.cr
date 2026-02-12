require "../../spec_helper"

module Fontbox::TTF
  describe GlyfCompositeDescript do
    it "returns components without exposing internal mutable storage" do
      font_path = File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
      font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))
      glyph_table = font.glyph
      glyph_table.should_not be_nil
      glyph = glyph_table.as(GlyphTable).get_glyph(131)
      glyph.should_not be_nil

      glyph_data = glyph.as(GlyphData)
      description = glyph_data.get_description
      description.is_composite.should be_true

      composite = description.as(GlyfCompositeDescript)
      composite.get_component_count.should eq(2)

      components = composite.get_components
      components.size.should eq(2)
      components.pop

      composite.get_component_count.should eq(2)
      composite.get_components.size.should eq(2)

      font.close
    end
  end
end

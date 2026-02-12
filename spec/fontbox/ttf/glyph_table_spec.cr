require "../../spec_helper"

module Fontbox::TTF
  describe GlyphTable do
    it "is initialized when parsed from a TTF" do
      font_path = File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
      font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))

      glyph_table = font.table(GlyphTable::TAG)
      glyph_table.should_not be_nil
      glyph_table.as(TTFTable).initialized.should be_true

      font.close
    end

    it "returns a composite glyph with its resolved components" do
      font_path = File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
      font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))

      glyph_table = font.glyph
      glyph_table.should_not be_nil
      glyph = glyph_table.as(GlyphTable).glyph(131)
      glyph.should_not be_nil

      description = glyph.as(GlyphData).description
      description.is_composite.should be_true

      composite = description.as(GlyfCompositeDescript)
      composite.component_count.should eq(2)
      composite.components.map(&.glyph_index).should eq([36, 2335])
      composite.point_count.should be > 0
      composite.contour_count.should be > 0

      font.close
    end

    it "returns an empty glyph when loca reports no outline data" do
      font_path = File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
      font = TTFParser.new.parse(Pdfbox::IO::RandomAccessReadBufferedFile.new(font_path))
      glyph_table = font.glyph
      glyph_table.should_not be_nil
      index_to_location = font.index_to_location
      index_to_location.should_not be_nil
      offsets = index_to_location.as(IndexToLocationTable).offsets

      empty_gid = -1
      (0...(offsets.size - 1)).each do |gid|
        if offsets[gid] == offsets[gid + 1]
          empty_gid = gid
          break
        end
      end

      empty_gid.should be >= 0
      glyph = glyph_table.as(GlyphTable).glyph(empty_gid)
      glyph.should_not be_nil
      glyph.as(GlyphData).description.is_composite.should be_false
      glyph.as(GlyphData).description.point_count.should eq(0)

      font.close
    end
  end
end

require "../../spec_helper"

module Fontbox::TTF
  private def self.liberation_sans_path
    File.join("apache_pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
  end

  private def self.load_liberation_sans
    TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(liberation_sans_path))
  end

  private def self.simhei_path : String?
    # Common font directories
    font_dirs = [
      "/System/Library/Fonts",
      "/Library/Fonts",
      File.expand_path("~/.fonts"),
      File.expand_path("~/.local/share/fonts"),
      "/usr/share/fonts",
      "/usr/local/share/fonts",
    ]
    font_dirs.each do |dir|
      next unless Dir.exists?(dir)
      Dir.each_child(dir) do |filename|
        if filename.downcase == "simhei.ttf" || filename.downcase == "simhei.ttc"
          return File.join(dir, filename)
        end
      end
    end
    nil
  end

  describe TTFSubsetter do
    it "test empty subset" do
      font = load_liberation_sans
      subsetter = TTFSubsetter.new(font)

      output = IO::Memory.new
      subsetter.write_to_stream(output)

      # Parse the subset font
      subset_io = Pdfbox::IO::MemoryRandomAccessRead.new(output.to_slice)
      subset_font = TTFParser.new(true).parse(subset_io)

      subset_font.number_of_glyphs.should eq(1)
      subset_font.name_to_gid(".notdef").should eq(0)

      glyph_table = subset_font.glyph
      glyph_table.should_not be_nil
      glyph_table.as(GlyphTable).glyph(0).should_not be_nil
    end

    it "test empty subset with selected tables" do
      font = load_liberation_sans
      # List copied from TrueTypeEmbedder.java
      tables = ["head", "hhea", "loca", "maxp", "cvt ", "prep", "glyf", "hmtx", "fpgm", "gasp"]
      subsetter = TTFSubsetter.new(font, tables)

      output = IO::Memory.new
      subsetter.write_to_stream(output)

      # Parse the subset font
      subset_io = Pdfbox::IO::MemoryRandomAccessRead.new(output.to_slice)
      subset_font = TTFParser.new(true).parse(subset_io)

      subset_font.number_of_glyphs.should eq(1)
      # name_to_gid only works if post table is present
      if subset_font.table("post")
        subset_font.name_to_gid(".notdef").should eq(0)
      end

      glyph_table = subset_font.glyph
      glyph_table.should_not be_nil
      glyph_table.as(GlyphTable).glyph(0).should_not be_nil
      # TODO: verify that the selected tables are present
    end
    it "test non-empty subset with one glyph" do
      font = load_liberation_sans
      subsetter = TTFSubsetter.new(font)
      subsetter.add('a')

      output = IO::Memory.new
      subsetter.write_to_stream(output)

      # Parse the subset font
      subset_io = Pdfbox::IO::MemoryRandomAccessRead.new(output.to_slice)
      subset_font = TTFParser.new(true).parse(subset_io)

      subset_font.number_of_glyphs.should eq(2)
      subset_font.name_to_gid(".notdef").should eq(0)
      subset_font.name_to_gid("a").should eq(1)

      glyph_table = subset_font.glyph
      glyph_table.should_not be_nil
      glyph_table.as(GlyphTable).glyph(0).should_not be_nil
      glyph_table.as(GlyphTable).glyph(1).should_not be_nil
      # glyph 2 should not exist
      glyph_table.as(GlyphTable).glyph(2).should be_nil

      # check advance width and left side bearing match original
      original_gid = font.name_to_gid("a")
      subset_gid = subset_font.name_to_gid("a")
      font.horizontal_metrics.not_nil! # ameba:disable Lint/NotNil
        .advance_width(original_gid).should eq(
        subset_font.horizontal_metrics.not_nil! # ameba:disable Lint/NotNil
          .advance_width(subset_gid))
      font.horizontal_metrics.not_nil! # ameba:disable Lint/NotNil
        .left_side_bearing(original_gid).should eq(
        subset_font.horizontal_metrics.not_nil! # ameba:disable Lint/NotNil
          .left_side_bearing(subset_gid))
      # verify gid_map
      subsetter.gid_map.size.should eq(2)
      subsetter.gid_map[0].should eq(0) # .notdef
      subsetter.gid_map[1].should eq(original_gid)
    end
    path = simhei_path
    if path
      it "test PDFBox-3319: widths and left side bearings in partially monospaced font" do
        font = TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(path))
        # List copied from TrueTypeEmbedder.java
        tables = ["head", "hhea", "loca", "maxp", "cvt ", "prep", "glyf", "hmtx", "fpgm", "gasp"]
        subsetter = TTFSubsetter.new(font, tables)
        chinese = "中国你好!"
        chinese.each_char { |char| subsetter.add(char) }
        output = IO::Memory.new
        subsetter.write_to_stream(output)
        subset_io = Pdfbox::IO::MemoryRandomAccessRead.new(output.to_slice)
        subset_font = TTFParser.new(true).parse(subset_io)
        subset_font.number_of_glyphs.should eq(6)
        subsetter.gid_map.each do |new_gid, old_gid|
          font.horizontal_metrics.not_nil! # ameba:disable Lint/NotNil
            .advance_width(old_gid).should eq(
            subset_font.horizontal_metrics.not_nil! # ameba:disable Lint/NotNil
              .advance_width(new_gid))
          font.horizontal_metrics.not_nil! # ameba:disable Lint/NotNil
            .left_side_bearing(old_gid).should eq(
            subset_font.horizontal_metrics.not_nil! # ameba:disable Lint/NotNil
              .left_side_bearing(new_gid))
        end
      end
    else
      pending "test PDFBox-3319: widths and left side bearings in partially monospaced font" do
        # SimHei font not available on this machine, test skipped
      end
    end
    pending "test PDFBox-3379: left side bearings in partially monospaced font"
    pending "test PDFBox-3757: PostScript names not in WGL4Names don't get shuffled"
    pending "test PDFBox-5728: font with v3 PostScript table format and no glyph names"
    pending "test PDFBox-6015: font with 0/1 cmap"
  end
end

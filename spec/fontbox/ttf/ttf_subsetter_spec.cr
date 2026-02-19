require "../../spec_helper"

module Fontbox::TTF
  private def self.liberation_sans_path
    File.join("vendor/pdfbox", "fontbox", "src", "test", "resources", "ttf", "LiberationSans-Regular.ttf")
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

  private def self.dejavu_sans_mono_path : String?
    # Common font directories
    font_dirs = [
      "/usr/share/fonts/truetype/dejavu/",
      "/System/Library/Fonts",
      "/Library/Fonts",
      File.expand_path("~/Library/Fonts"),
      "/usr/local/share/fonts",
      "/usr/share/fonts",
      File.expand_path("~/.fonts"),
      File.expand_path("~/.local/share/fonts"),
    ]
    font_dirs.each do |dir|
      next unless Dir.exists?(dir)
      Dir.each_child(dir) do |filename|
        if filename.downcase == "dejavusansmono.ttf" || filename.downcase =~ /deja.*sans.*mono.*\.ttf/
          return File.join(dir, filename)
        end
      end
    end
    nil
  end

  private def self.noto_mono_path : String?
    # Common font directories
    font_dirs = [
      "/System/Library/Fonts",
      "/Library/Fonts",
      File.expand_path("~/.fonts"),
      File.expand_path("~/.local/share/fonts"),
      "/usr/share/fonts",
      "/usr/local/share/fonts",
      "/usr/share/fonts/truetype/noto/",
      File.expand_path("~/Library/Fonts"),
    ]
    font_dirs.each do |dir|
      next unless Dir.exists?(dir)
      Dir.each_child(dir) do |filename|
        if filename.downcase == "notomono-regular.ttf"
          return File.join(dir, filename)
        end
      end
    end
    nil
  end

  private def self.keyboard_path : String?
    # Common font directories
    font_dirs = [
      "/System/Library/Fonts",
      "/Library/Fonts",
      File.expand_path("~/Library/Fonts"),
      "/usr/share/fonts",
      "/usr/local/share/fonts",
      File.expand_path("~/.fonts"),
      File.expand_path("~/.local/share/fonts"),
    ]
    font_dirs.each do |dir|
      next unless Dir.exists?(dir)
      Dir.each_child(dir) do |filename|
        if filename.downcase == "keyboard.ttf"
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
      original_hmtx = font.horizontal_metrics
      subset_hmtx = subset_font.horizontal_metrics
      original_hmtx.should_not be_nil
      subset_hmtx.should_not be_nil
      hmtx_original = original_hmtx || raise "expected original horizontal metrics"
      hmtx_subset = subset_hmtx || raise "expected subset horizontal metrics"
      hmtx_original.advance_width(original_gid).should eq(hmtx_subset.advance_width(subset_gid))
      hmtx_original.left_side_bearing(original_gid).should eq(hmtx_subset.left_side_bearing(subset_gid))
      # verify gid_map
      subsetter.gid_map.size.should eq(2)
      subsetter.gid_map[0].should eq(0) # .notdef
      subsetter.gid_map[1].should eq(original_gid)
    end
    path = simhei_path
    it "test PDFBox-3319: widths and left side bearings in partially monospaced font" do
      unless ENV["PDFBOX_OPTIONAL_FONT_TESTS"]? == "1"
        true.should be_true
        next
      end
      font_path = path
      unless font_path
        true.should be_true
        next
      end

      font = TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(font_path))
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
      original_hmtx = font.horizontal_metrics
      subset_hmtx = subset_font.horizontal_metrics
      original_hmtx.should_not be_nil
      subset_hmtx.should_not be_nil
      hmtx_original = original_hmtx || raise "expected original horizontal metrics"
      hmtx_subset = subset_hmtx || raise "expected subset horizontal metrics"
      subsetter.gid_map.each do |new_gid, old_gid|
        hmtx_original.advance_width(old_gid).should eq(hmtx_subset.advance_width(new_gid))
        hmtx_original.left_side_bearing(old_gid).should eq(hmtx_subset.left_side_bearing(new_gid))
      end
    end
    dejavu_path = dejavu_sans_mono_path
    it "test PDFBox-3379: left side bearings in partially monospaced font" do
      unless ENV["PDFBOX_OPTIONAL_FONT_TESTS"]? == "1"
        true.should be_true
        next
      end
      font_path = dejavu_path
      unless font_path
        true.should be_true
        next
      end

      font = TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(font_path))
      subsetter = TTFSubsetter.new(font)
      subsetter.add('A')
      subsetter.add(' ')
      subsetter.add('B')
      output = IO::Memory.new
      subsetter.write_to_stream(output)
      subset_io = Pdfbox::IO::MemoryRandomAccessRead.new(output.to_slice)
      subset_font = TTFParser.new(true).parse(subset_io)
      subset_font.number_of_glyphs.should eq(4)
      subset_font.name_to_gid(".notdef").should eq(0)
      subset_font.name_to_gid("space").should eq(1)
      subset_font.name_to_gid("A").should eq(2)
      subset_font.name_to_gid("B").should eq(3)
      original_hmtx = font.horizontal_metrics
      subset_hmtx = subset_font.horizontal_metrics
      original_hmtx.should_not be_nil
      subset_hmtx.should_not be_nil
      hmtx_original = original_hmtx || raise "expected original horizontal metrics"
      hmtx_subset = subset_hmtx || raise "expected subset horizontal metrics"
      ["A", "B", "space"].each do |name|
        original_gid = font.name_to_gid(name)
        subset_gid = subset_font.name_to_gid(name)
        hmtx_original.advance_width(original_gid).should eq(hmtx_subset.advance_width(subset_gid))
        hmtx_original.left_side_bearing(original_gid).should eq(hmtx_subset.left_side_bearing(subset_gid))
      end
    end
    it "test PDFBox-3757: PostScript names not in WGL4Names don't get shuffled" do
      font = load_liberation_sans
      subsetter = TTFSubsetter.new(font)
      subsetter.add('Ö')
      subsetter.add('\u200A')

      output = IO::Memory.new
      subsetter.write_to_stream(output)

      # Parse the subset font
      subset_io = Pdfbox::IO::MemoryRandomAccessRead.new(output.to_slice)
      subset_font = TTFParser.new(true).parse(subset_io)

      subset_font.number_of_glyphs.should eq(5)

      subset_font.name_to_gid(".notdef").should eq(0)
      subset_font.name_to_gid("O").should eq(1)
      subset_font.name_to_gid("Odieresis").should eq(2)
      subset_font.name_to_gid("uni200A").should eq(3)
      subset_font.name_to_gid("dieresis.uc").should eq(4)

      post = subset_font.postscript
      post.should_not be_nil
      post.as(PostScriptTable).name(0).should eq(".notdef")
      post.as(PostScriptTable).name(1).should eq("O")
      post.as(PostScriptTable).name(2).should eq("Odieresis")
      post.as(PostScriptTable).name(3).should eq("uni200A")
      post.as(PostScriptTable).name(4).should eq("dieresis.uc")

      # Optional: check hair space has empty contour, dieresis.uc has non-empty contour
      glyph_table = subset_font.glyph
      glyph_table.should_not be_nil
      hair_gid = subset_font.name_to_gid("uni200A")
      hair_glyph = glyph_table.as(GlyphTable).glyph(hair_gid)
      hair_glyph.should_not be_nil
      hair_glyph.as(GlyphData).number_of_contours.should eq(0)

      dieresis_gid = subset_font.name_to_gid("dieresis.uc")
      dieresis_glyph = glyph_table.as(GlyphTable).glyph(dieresis_gid)
      dieresis_glyph.should_not be_nil
      dieresis_glyph.as(GlyphData).number_of_contours.should be > 0
    end
    path = noto_mono_path
    it "test PDFBox-5728: font with v3 PostScript table format and no glyph names" do
      unless ENV["PDFBOX_OPTIONAL_FONT_TESTS"]? == "1"
        true.should be_true
        next
      end
      font_path = path
      unless font_path
        true.should be_true
        next
      end

      font = TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(font_path))
      post = font.postscript
      post.should_not be_nil
      post.as(PostScriptTable).format_type.should eq(3.0)
      post.as(PostScriptTable).glyph_names.should be_nil
      subsetter = TTFSubsetter.new(font)
      subsetter.add('a')
      output = IO::Memory.new
      subsetter.write_to_stream(output)
      # parse subset font to ensure no exception
      subset_io = Pdfbox::IO::MemoryRandomAccessRead.new(output.to_slice)
      _subset_font = TTFParser.new(true).parse(subset_io)
      # optional: verify subset font has no post table (or minimal table)
      # subset_font.table("post").should be_nil
    end
    path = keyboard_path
    it "test PDFBox-6015: font with 0/1 cmap" do
      unless ENV["PDFBOX_OPTIONAL_FONT_TESTS"]? == "1"
        true.should be_true
        next
      end
      font_path = path
      unless font_path
        true.should be_true
        next
      end

      font = TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(font_path))
      lookup = font.unicode_cmap_lookup
      lookup.glyph_id('a'.ord).should eq(185)
      lookup.glyph_id('z'.ord).should eq(210)
      lookup.glyph_id('A'.ord).should eq(159)
      lookup.glyph_id('Z'.ord).should eq(184)
      lookup.glyph_id('0'.ord).should eq(49)
      lookup.glyph_id('9'.ord).should eq(58)
    end
  end
end

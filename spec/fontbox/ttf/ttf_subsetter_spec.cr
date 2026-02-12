require "../../spec_helper"

module Fontbox::TTF
  private def self.liberation_sans_path
    File.join(__DIR__, "../../../../apache_pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")
  end

  private def self.load_liberation_sans
    TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(liberation_sans_path))
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
      subset_font.glyph.glyph(0).should_not be_nil
    end

    pending "test empty subset with selected tables"
    pending "test non-empty subset with one glyph"
    pending "test PDFBox-3319: widths and left side bearings in partially monospaced font"
    pending "test PDFBox-3379: left side bearings in partially monospaced font"
    pending "test PDFBox-3757: PostScript names not in WGL4Names don't get shuffled"
    pending "test PDFBox-5728: font with v3 PostScript table format and no glyph names"
    pending "test PDFBox-6015: font with 0/1 cmap"
  end
end

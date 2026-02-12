require "../../spec_helper"

module Fontbox::TTF
  private def liberation_sans_path
    File.join(__DIR__, "../../../../apache_pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")
  end

  private def load_liberation_sans
    TTFParser.new.parse(Pdfbox::IO::FileRandomAccessRead.new(liberation_sans_path))
  end

  describe TTFSubsetter do
    pending "test empty subset"
    pending "test empty subset with selected tables"
    pending "test non-empty subset with one glyph"
    pending "test PDFBox-3319: widths and left side bearings in partially monospaced font"
    pending "test PDFBox-3379: left side bearings in partially monospaced font"
    pending "test PDFBox-3757: PostScript names not in WGL4Names don't get shuffled"
    pending "test PDFBox-5728: font with v3 PostScript table format and no glyph names"
    pending "test PDFBox-6015: font with 0/1 cmap"
  end
end

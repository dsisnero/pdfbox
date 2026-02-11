# GlyphArraySplitter interface
#
# Ported from Apache PDFBox GlyphArraySplitter.
module Fontbox::TTF::Gsub
  abstract class GlyphArraySplitter
    # Splits an array of glyph IDs with a prospective match.
    abstract def split(glyph_ids : Array(Int32)) : Array(Array(Int32))
  end
end

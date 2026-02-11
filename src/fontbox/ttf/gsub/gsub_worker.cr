require "../ttf_tables"

module Fontbox::TTF::Gsub
  # This class is responsible for replacing GlyphIDs with new ones according to the GSUB tables. Each language should
  # have an implementation of this.
  #
  # Ported from Apache PDFBox GsubWorker.
  abstract class GsubWorker
    # Applies language-specific transforms including GSUB and any other pre or post-processing necessary for displaying
    # Glyphs correctly.
    #
    # @param original_glyph_ids list of original glyph IDs
    # @return list of transformed glyph IDs
    abstract def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
  end

  # A default implementation of GsubWorker that actually does not transform the glyphs yet allows to correctly
  # load GSUB table data even from fonts for which a complete glyph substitution is not implemented.
  #
  # Ported from Apache PDFBox DefaultGsubWorker.
  class DefaultGsubWorker < GsubWorker
    Log = ::Log.for(self)

    def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
      Log.warn {
        "#{self.class} does not perform actual GSUB substitutions. Perhaps the selected language is not yet supported by the FontBox library."
      }
      # Return a duplicate to prevent accidental modifications of the source list
      original_glyph_ids.dup
    end
  end
end

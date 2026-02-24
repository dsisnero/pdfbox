# Vector outline font interface
# Corresponds to PDVectorFont in Apache PDFBox
module Pdfbox::Pdmodel::Font::PDVectorFont
  # Returns the glyph path for the given character code.
  # @param code character code in a PDF. Not to be confused with unicode.
  # @return the glyph path for the given character code
  abstract def get_path(code : Int32)

  # Returns the normalized glyph path for the given character code in a PDF.
  # The resulting path is normalized to the PostScript 1000 unit square,
  # and fallback glyphs are returned where appropriate, e.g. for missing glyphs.
  # @param code character code in a PDF. Not to be confused with unicode.
  # @return the normalized glyph path for the given character code
  abstract def get_normalized_path(code : Int32)

  # Returns true if this font contains a glyph for the given character code in a PDF.
  # @param code character code in a PDF. Not to be confused with unicode.
  # @return true if this font contains a glyph for the given character code
  abstract def has_glyph(code : Int32) : Bool
end

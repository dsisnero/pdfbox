# An interface that abstracts the cid <-> codepoint lookup functionality of cmap.
#
# Ported from Apache PDFBox CmapLookup.
module Fontbox::TTF
  module CmapLookup
    # Returns the GlyphId linked with the given character code.
    #
    # @param character_code [Int32] the given character code to be mapped
    # @return [Int32] glyph id for the given character code
    abstract def get_glyph_id(character_code : Int32) : Int32

    # Returns all possible character codes for the given gid, or nil if there is none.
    #
    # @param gid [Int32] glyph id
    # @return [Array(Int32)?] a list with all character codes the given gid maps to
    abstract def get_char_codes(gid : Int32) : Array(Int32)?
  end
end

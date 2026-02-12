# GlyphArraySplitterRegexImpl
#
# Ported from Apache PDFBox GlyphArraySplitterRegexImpl.
module Fontbox::TTF::Gsub
  class GlyphArraySplitterRegexImpl < GlyphArraySplitter
    GLYPH_ID_SEPARATOR = '_'

    @compound_character_tokenizer : CompoundCharacterTokenizer

    def initialize(matchers : Set(Array(Int32)))
      @compound_character_tokenizer = CompoundCharacterTokenizer.new(get_matchers_as_strings(matchers))
    end

    def split(glyph_ids : Array(Int32)) : Array(Array(Int32))
      original_glyphs_as_text = convert_glyph_ids_to_string(glyph_ids)
      tokens = @compound_character_tokenizer.tokenize(original_glyphs_as_text)

      modified_glyphs = Array(Array(Int32)).new(tokens.size)
      tokens.each do |token|
        modified_glyphs << convert_glyph_ids_to_list(token)
      end
      modified_glyphs
    end

    private def get_matchers_as_strings(matchers : Set(Array(Int32))) : Set(String)
      # Sort strings with custom comparator: longer strings first,
      # if same length, reverse lexicographic order
      sorted_strings = matchers.map { |glyph_ids| convert_glyph_ids_to_string(glyph_ids) }
        .sort! do |str1, str2|
          if str1.size == str2.size
            str2 <=> str1 # reverse comparison
          else
            str2.size <=> str1.size # longer first
          end
        end
      Set.new(sorted_strings)
    end

    private def convert_glyph_ids_to_string(glyph_ids : Array(Int32)) : String
      String.build do |io|
        io << GLYPH_ID_SEPARATOR
        glyph_ids.each do |glyph_id|
          io << glyph_id << GLYPH_ID_SEPARATOR
        end
      end
    end

    private def convert_glyph_ids_to_list(glyph_ids_as_string : String) : Array(Int32)
      glyph_ids = [] of Int32
      glyph_ids_as_string.split(GLYPH_ID_SEPARATOR).each do |glyph_id|
        glyph_id = glyph_id.strip
        next if glyph_id.empty?
        glyph_ids << glyph_id.to_i32
      end
      glyph_ids
    end
  end
end

# CompoundCharacterTokenizer
#
# Ported from Apache PDFBox CompoundCharacterTokenizer.
module Fontbox::TTF::Gsub
  class CompoundCharacterTokenizer
    GLYPH_ID_SEPARATOR = '_'

    @regex_expression : Regex

    # Constructor. Calls get_regex_from_tokens which returns strings like
    # (_79_99_)|(_80_99_)|(_92_99_) and creates a regex assigned to regex_expression.
    # It is assumed the compound words are sorted in descending order of length.
    #
    # @param compound_words A set of strings like _79_99_, _80_99_ or _92_99_.
    def initialize(compound_words : Set(String))
      validate_compound_words(compound_words)
      @regex_expression = Regex.new(regex_from_tokens(compound_words))
    end

    # Tokenize a string into tokens.
    #
    # @param text A string like "_66_71_71_74_79_70_"
    # @return A list of tokens like "_66_", "_71_71_", "74_79_70_". The "_" is sometimes missing at
    # the beginning or end, this has to be cleaned by the caller.
    def tokenize(text : String) : Array(String)
      tokens = [] of String

      last_index_of_prev_match = 0

      while match = @regex_expression.match(text, last_index_of_prev_match)
        begin_index_of_next_match = match.begin

        prev_token = text[last_index_of_prev_match...begin_index_of_next_match]
        tokens << prev_token unless prev_token.empty?

        current_match = match[0]
        tokens << current_match

        last_index_of_prev_match = match.end
        if last_index_of_prev_match < text.size && text[last_index_of_prev_match] != '_'
          # because it is sometimes positioned after the "_", but it should be positioned
          # before the "_"
          last_index_of_prev_match -= 1
        end
      end

      tail = text[last_index_of_prev_match..]
      tokens << tail unless tail.empty?

      tokens
    end

    private def validate_compound_words(compound_words : Set(String)) : Nil
      if compound_words.empty?
        raise ArgumentError.new("Compound words cannot be null or empty")
      end

      # Ensure all words start and end with the GLYPH_ID_SEPARATOR
      compound_words.each do |word|
        unless word.starts_with?(GLYPH_ID_SEPARATOR) && word.ends_with?(GLYPH_ID_SEPARATOR)
          raise ArgumentError.new(
            "Compound words should start and end with #{GLYPH_ID_SEPARATOR}"
          )
        end
      end
    end

    private def regex_from_tokens(compound_words : Set(String)) : String
      "(" + compound_words.join(")|(") + ")"
    end
  end
end

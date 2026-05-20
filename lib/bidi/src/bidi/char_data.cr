# Accessor for `Bidi_Class` property from Unicode Character Database (UCD)

require "./char_data/tables"
require "./char_data/tables_data"
require "./data_source"

module Bidi
  module CharData
    extend self

    # Find the `BidiClass` of a single char.
    #
    # This function uses hardcoded data that ships with the unicode-bidi crate.
    # In the Rust version, this is enabled with the `hardcoded-data` Cargo feature.
    def bidi_class(c : Char) : BidiClass
      bsearch_range_value_table(c, BIDI_CLASS_TABLE)
    end

    # Binary search for character in range-value table
    private def bsearch_range_value_table(c : Char, table : Array(Tuple(Char, Char, BidiClass))) : BidiClass
      low = 0
      high = table.size - 1

      while low <= high
        mid = (low + high) // 2
        lo, hi, cat = table[mid]

        if c < lo
          high = mid - 1
        elsif c > hi
          low = mid + 1
        else
          # c is in range [lo, hi]
          return cat
        end
      end

      # UCD/extracted/DerivedBidiClass.txt: "All code points not explicitly listed
      # for Bidi_Class have the value Left_To_Right (L)."
      BidiClass::L
    end

    # Returns true if the BidiClass represents a right-to-left embedding, override, or isolate.
    def rtl?(bidi_class : BidiClass) : Bool
      case bidi_class
      when BidiClass::RLE, BidiClass::RLO, BidiClass::RLI
        true
      else
        false
      end
    end

    # If this character is a bracket according to BidiBrackets.txt,
    # return the corresponding *normalized* *opening bracket* of the pair,
    # and whether or not it itself is an opening bracket.
    #
    # Note: This is marked as crate-private in Rust (`pub(crate)`).
    # We'll need to decide on visibility in Crystal.
    def bidi_matched_opening_bracket(c : Char) : BidiMatchedOpeningBracket?
      BIDI_PAIRS_TABLE.each do |opening, closing, normalized|
        if c == opening || c == closing
          skeleton = normalized || opening
          return BidiMatchedOpeningBracket.new(skeleton, c == opening)
        end
      end
      nil
    end
  end

  # Hardcoded Bidi data that ships with the unicode-bidi crate.
  #
  # This corresponds to the `hardcoded-data` Cargo feature in Rust.
  struct HardcodedBidiData
    include BidiDataSource

    def bidi_class(c : Char) : BidiClass
      CharData.bidi_class(c)
    end
  end
end

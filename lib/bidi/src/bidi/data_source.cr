module Bidi
  # This is the return value of `BidiDataSource#bidi_matched_opening_bracket()`.
  #
  # It represents the matching *normalized* opening bracket for a given bracket in a bracket pair,
  # and whether or not that bracket is opening.
  struct BidiMatchedOpeningBracket
    # The corresponding opening bracket in this bracket pair, normalized
    #
    # In case of opening brackets, this will be the bracket itself, except for when the bracket
    # is not normalized, in which case it will be the normalized form.
    property opening : Char

    # Whether or not the requested bracket was an opening bracket. True for opening
    property is_open : Bool

    def initialize(@opening : Char, @is_open : Bool)
    end
  end

  # This module abstracts over a data source that is able to produce the Unicode Bidi class for a given
  # character.
  #
  # In Rust, this is a trait. In Crystal, we'll use a module with abstract methods.
  module BidiDataSource
    abstract def bidi_class(c : Char) : BidiClass

    # If this character is a bracket according to BidiBrackets.txt,
    # return the corresponding *normalized* *opening bracket* of the pair,
    # and whether or not it itself is an opening bracket.
    #
    # This effectively buckets brackets into equivalence classes keyed on the
    # normalized opening bracket.
    #
    # The default implementation will pull in a small amount of hardcoded data,
    # regardless of the `hardcoded-data` feature. This is in part for convenience
    # (since this data is small and changes less often), and in part so that this method can be
    # added without needing a breaking version bump.
    # Override this method in your custom data source to prevent the use of hardcoded data.
    def bidi_matched_opening_bracket(c : Char) : BidiMatchedOpeningBracket?
      CharData.bidi_matched_opening_bracket(c)
    end
  end
end

# Directional Formatting Characters
#
# <http://www.unicode.org/reports/tr9/#Directional_Formatting_Characters>

module Bidi
  module FormatChars
    # == Implicit ==

    # ARABIC LETTER MARK
    ALM = '\u{061C}'

    # LEFT-TO-RIGHT MARK
    LRM = '\u{200E}'

    # RIGHT-TO-LEFT MARK
    RLM = '\u{200F}'

    # == Explicit Isolates ==

    # LEFT‑TO‑RIGHT ISOLATE
    LRI = '\u{2066}'

    # RIGHT‑TO‑LEFT ISOLATE
    RLI = '\u{2067}'

    # FIRST STRONG ISOLATE
    FSI = '\u{2068}'

    # POP DIRECTIONAL ISOLATE
    PDI = '\u{2069}'

    # == Explicit Embeddings and Overrides ==

    # LEFT-TO-RIGHT EMBEDDING
    LRE = '\u{202A}'

    # RIGHT-TO-LEFT EMBEDDING
    RLE = '\u{202B}'

    # POP DIRECTIONAL FORMATTING
    PDF = '\u{202C}'

    # LEFT-TO-RIGHT OVERRIDE
    LRO = '\u{202D}'

    # RIGHT-TO-LEFT OVERRIDE
    RLO = '\u{202E}'
  end
end

# Crystal port of the Unicode Bidirectional Algorithm implementation.
# Upstream source: https://github.com/servo/unicode-bidi.git (v0.3.18)

# Load all submodules
require "./bidi/char_data"
require "./bidi/data_source"
require "./bidi/level"
require "./bidi/format_chars"
require "./bidi/prepare"
require "./bidi/explicit"
require "./bidi/implicit"
require "./bidi/info"
require "./bidi/text_source"
require "./bidi/utf16"

module Bidi
  VERSION = "0.1.0"

  # Re-export commonly used types and functions
  alias BidiClass = CharData::BidiClass

  # Forward common functions
  def self.bidi_class(c : Char) : BidiClass
    CharData.bidi_class(c)
  end

  def self.rtl?(bidi_class : BidiClass) : Bool
    CharData.rtl?(bidi_class)
  end
end

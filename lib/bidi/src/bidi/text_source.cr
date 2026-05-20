# Text source abstraction for UTF-8 text (Crystal String).
# This provides utilities for working with text at the byte level,
# which is what the bidi algorithms need.

module Bidi
  # Iterator over (UTF-8) string slices returning (index, char_len) tuple.
  class Utf8IndexLenIter
    include Iterator({Int32, Int32})

    @text : String
    @char_iter : Iterator(Char)
    @index : Int32

    def initialize(@text : String)
      @char_iter = @text.chars.each
      @index = 0
    end

    def next : {Int32, Int32}?
      ch = @char_iter.next
      return stop if ch.nil?

      pos = @index
      char_len = ch.bytesize
      @index += char_len
      {pos, char_len}
    end
  end

  # Abstract text source for bidi algorithms.
  # In Crystal, we only implement this for String (UTF-8).
  # This corresponds to Rust's TextSource trait.
  module TextSource
    # Get the character at a given byte index, along with its length in bytes.
    # Returns nil if index is out of range or points inside a multi-byte character.
    def self.char_at(text : String, index : Int32) : {Char, Int32}?
      return nil if index < 0 || index >= text.bytesize

      # Get the byte at index
      byte = text.byte_at(index)

      # Determine UTF-8 character length from first byte
      char_len = case byte
                 when 0x00..0x7F then 1          # ASCII
                 when 0xC0..0xDF then 2          # 2-byte UTF-8
                 when 0xE0..0xEF then 3          # 3-byte UTF-8
                 when 0xF0..0xF7 then 4          # 4-byte UTF-8
                 else                 return nil # Invalid UTF-8 or continuation byte
                 end

      # Check if we have enough bytes
      return nil if index + char_len > text.bytesize

      # Get the character
      char = text.byte_slice(index, char_len)
      {char, char_len}
    end

    # Iterate over characters with their byte indices and lengths.
    # Yields (byte_index, char, char_length) for each character.
    def self.each_char_with_index(text : String, &block : Int32, Char, Int32 ->)
      index = 0
      text.each_char do |char|
        char_len = char.bytesize
        yield index, char, char_len
        index += char_len
      end
    end

    # Get an array of (byte_index, char_length) pairs for each character.
    def self.indices_lengths(text : String) : Array({Int32, Int32})
      result = [] of {Int32, Int32}
      index = 0
      text.each_char do |char|
        char_len = char.bytesize
        result << {index, char_len}
        index += char_len
      end
      result
    end

    # Get an array of (byte_index, char) pairs for each character.
    def self.char_indices(text : String) : Array({Int32, Char})
      result = [] of {Int32, Char}
      index = 0
      text.each_char do |char|
        result << {index, char}
        index += char.bytesize
      end
      result
    end

    # Number of bytes a character uses in UTF-8.
    def self.char_len(char : Char) : Int32
      char.bytesize
    end
  end
end

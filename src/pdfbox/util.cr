module Pdfbox::Util
  # Ported from Apache PDFBox StringUtil.
  module StringUtil
    PATTERN_SPACE = /\s/

    # Split on whitespace using Java Pattern.split semantics:
    # keep empty tokens between delimiters, drop trailing empty tokens.
    def self.split_on_space(s : String) : Array(String)
      return [s] if s.empty?

      tokens = [] of String
      current = ""

      s.each_char do |char|
        if char.whitespace?
          tokens << current
          current = ""
        else
          current += char
        end
      end
      tokens << current

      while !tokens.empty? && tokens.last.empty?
        tokens.pop
      end

      tokens
    end

    # Split at whitespace but keep delimiters as individual tokens.
    def self.tokenize_on_space(s : String) : Array(String)
      return [s] if s.empty?

      tokens = [] of String
      current = ""

      s.each_char do |char|
        if char.whitespace?
          tokens << current unless current.empty?
          tokens << char.to_s
          current = ""
        else
          current += char
        end
      end

      tokens << current unless current.empty?
      tokens
    end
  end

  # Ported from Apache PDFBox Hex.
  module Hex
    HEX_BYTES = Bytes['0'.ord.to_u8, '1'.ord.to_u8, '2'.ord.to_u8, '3'.ord.to_u8, '4'.ord.to_u8, '5'.ord.to_u8, '6'.ord.to_u8, '7'.ord.to_u8, '8'.ord.to_u8, '9'.ord.to_u8, 'A'.ord.to_u8, 'B'.ord.to_u8, 'C'.ord.to_u8, 'D'.ord.to_u8, 'E'.ord.to_u8, 'F'.ord.to_u8]
    HEX_CHARS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F']

    def self.get_string(b : UInt8) : String
      String.new(Bytes[HEX_BYTES[high_nibble(b)], HEX_BYTES[low_nibble(b)]])
    end

    def self.get_string(bytes : Bytes) : String
      ascii = Bytes.new(bytes.size * 2)
      bytes.each_with_index do |b, i|
        ascii[i * 2] = HEX_BYTES[high_nibble(b)]
        ascii[(i * 2) + 1] = HEX_BYTES[low_nibble(b)]
      end
      String.new(ascii)
    end

    def self.get_bytes(b : UInt8) : Bytes
      Bytes[HEX_BYTES[high_nibble(b)], HEX_BYTES[low_nibble(b)]]
    end

    def self.get_bytes(bytes : Bytes) : Bytes
      ascii = Bytes.new(bytes.size * 2)
      bytes.each_with_index do |b, i|
        ascii[i * 2] = HEX_BYTES[high_nibble(b)]
        ascii[(i * 2) + 1] = HEX_BYTES[low_nibble(b)]
      end
      ascii
    end

    def self.get_chars(num : Int16) : Array(Char)
      u = num.unsafe_as(UInt16)
      [
        HEX_CHARS[((u >> 12) & 0x0f).to_i],
        HEX_CHARS[((u >> 8) & 0x0f).to_i],
        HEX_CHARS[((u >> 4) & 0x0f).to_i],
        HEX_CHARS[(u & 0x0f).to_i],
      ]
    end

    def self.get_chars_utf16be(text : String) : Array(Char)
      hex = Array(Char).new(text.size * 4)
      text.each_char do |char|
        c = char.ord
        hex << HEX_CHARS[((c >> 12) & 0x0f).to_i]
        hex << HEX_CHARS[((c >> 8) & 0x0f).to_i]
        hex << HEX_CHARS[((c >> 4) & 0x0f).to_i]
        hex << HEX_CHARS[(c & 0x0f).to_i]
      end
      hex
    end

    def self.decode_base64(base64_value : String) : Bytes
      Base64.decode(StringUtil::PATTERN_SPACE.replace(base64_value, ""))
    end

    def self.decode_hex(value : String) : Bytes
      decoded = ::IO::Memory.new
      i = 0
      while i < value.size - 1
        if value[i] == '\n' || value[i] == '\r'
          i += 1
        else
          current = 16 * get_hex_value(value[i]) + get_hex_value(value[i + 1])
          decoded.write_byte(current.to_u8) if current >= 0
          i += 2
        end
      end
      decoded.to_slice
    end

    def self.get_hex_value(char : Char) : Int32
      if char >= '0' && char <= '9'
        char.ord - '0'.ord
      elsif char >= 'A' && char <= 'F'
        char.ord - 'A'.ord + 10
      elsif char >= 'a' && char <= 'f'
        char.ord - 'a'.ord + 10
      else
        -256
      end
    end

    private def self.high_nibble(b : UInt8) : Int32
      ((b & 0xf0_u8) >> 4).to_i
    end

    private def self.low_nibble(b : UInt8) : Int32
      (b & 0x0f_u8).to_i
    end
  end
end

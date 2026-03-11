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

  # Ported from Apache PDFBox NumberFormatUtil.
  module NumberFormatUtil
    MAX_FRACTION_DIGITS = 5
    POWER_OF_TENS       = (0..18).map { |exp| 10_i64**exp }.to_a
    POWER_OF_TENS_INT   = (0..9).map { |exp| 10_i32**exp }.to_a

    def self.format_float_fast(value : Float32, max_fraction_digits : Int32, ascii_buffer : Bytes) : Int32
      if value.nan? || value.infinite? || value > Int64::MAX || value <= Int64::MIN || max_fraction_digits > MAX_FRACTION_DIGITS
        return -1
      end

      offset = 0
      integer_part = value.to_i64

      if value < 0
        ascii_buffer[offset] = '-'.ord.to_u8
        offset += 1
        integer_part = -integer_part
      end

      fraction_scale = POWER_OF_TENS[max_fraction_digits]
      fraction_part = ((value.abs.to_f64 - integer_part.to_f64) * fraction_scale.to_f64 + 0.5_f64).to_i64

      if fraction_part >= fraction_scale
        integer_part += 1
        fraction_part -= fraction_scale
      end

      offset = format_positive_number(integer_part, get_exponent(integer_part), false, ascii_buffer, offset)

      if fraction_part > 0 && max_fraction_digits > 0
        ascii_buffer[offset] = '.'.ord.to_u8
        offset += 1
        offset = format_positive_number(fraction_part, max_fraction_digits - 1, true, ascii_buffer, offset)
      end

      offset
    end

    private def self.format_positive_number(number : Int64, exp : Int32, omit_trailing_zeros : Bool, ascii_buffer : Bytes, start_offset : Int32) : Int32
      offset = start_offset
      remaining = number
      current_exp = exp

      while remaining > Int32::MAX
        digit = remaining // POWER_OF_TENS[current_exp]
        remaining -= digit * POWER_OF_TENS[current_exp]
        ascii_buffer[offset] = ('0'.ord + digit).to_u8
        offset += 1
        current_exp -= 1
      end

      remaining_int = remaining.to_i32
      while current_exp >= 0 && (!omit_trailing_zeros || remaining_int > 0)
        digit = remaining_int // POWER_OF_TENS_INT[current_exp]
        remaining_int -= digit * POWER_OF_TENS_INT[current_exp]
        ascii_buffer[offset] = ('0'.ord + digit).to_u8
        offset += 1
        current_exp -= 1
      end

      offset
    end

    private def self.get_exponent(number : Int64) : Int32
      (0...POWER_OF_TENS.size - 1).each do |exp|
        return exp if number < POWER_OF_TENS[exp + 1]
      end
      POWER_OF_TENS.size - 1
    end
  end

  # Ported from Apache PDFBox IterativeMergeSort.
  module IterativeMergeSort
    def self.sort(list : Array(T), &cmp : T, T -> Int32) : Nil forall T
      return if list.size < 2

      arr = list.dup
      iterative_merge_sort(arr, cmp)
      list.replace(arr)
    end

    private def self.iterative_merge_sort(arr : Array(T), cmp : Proc(T, T, Int32)) : Nil forall T
      aux = arr.dup
      block_size = 1
      while block_size < arr.size
        start = 0
        doubled = block_size << 1
        while start < arr.size
          merge(arr, aux, start, start + block_size, start + doubled, cmp)
          start += doubled
        end
        block_size = doubled
      end
    end

    private def self.merge(arr : Array(T), aux : Array(T), from : Int32, mid : Int32, to : Int32, cmp : Proc(T, T, Int32)) : Nil forall T
      return if mid >= arr.size
      to = arr.size if to > arr.size

      i = from
      j = mid
      k = from
      while k < to
        if i == mid
          aux[k] = arr[j]
          j += 1
        elsif j == to
          aux[k] = arr[i]
          i += 1
        elsif cmp.call(arr[j], arr[i]) < 0
          aux[k] = arr[j]
          j += 1
        else
          aux[k] = arr[i]
          i += 1
        end
        k += 1
      end

      index = from
      while index < to
        arr[index] = aux[index]
        index += 1
      end
    end
  end
end

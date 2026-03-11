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

  # Ported from Apache PDFBox Matrix.
  class Matrix
    SIZE = 9

    @single : Array(Float32)

    def initialize
      @single = [1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32]
    end

    def initialize(a : Float32, b : Float32, c : Float32, d : Float32, e : Float32, f : Float32)
      @single = Array.new(SIZE, 0.0_f32)
      @single[0] = a
      @single[1] = b
      @single[3] = c
      @single[4] = d
      @single[6] = e
      @single[7] = f
      @single[8] = 1.0_f32
    end

    # Internal constructor mirroring Java clone/from-array usage.
    def initialize(@single : Array(Float32))
    end

    def self.create_matrix(base : Pdfbox::Cos::Base) : Matrix
      array = base.as?(Pdfbox::Cos::Array)
      return Matrix.new unless array
      return Matrix.new if array.items.size < 6

      values = Array(Float32).new(6)
      6.times do |i|
        item = array.get(i)
        case item
        when Pdfbox::Cos::Integer
          values << item.value.to_f32
        when Pdfbox::Cos::Float
          values << item.value.to_f32
        else
          return Matrix.new
        end
      end
      Matrix.new(values[0], values[1], values[2], values[3], values[4], values[5])
    end

    def clone : Matrix
      Matrix.new(@single.dup)
    end

    def get_value(row : Int32, column : Int32) : Float32
      @single[(row * 3) + column]
    end

    def set_value(row : Int32, column : Int32, value : Float32) : Nil
      @single[(row * 3) + column] = value
    end

    def values : Array(Array(Float32))
      [
        [@single[0], @single[1], @single[2]],
        [@single[3], @single[4], @single[5]],
        [@single[6], @single[7], @single[8]],
      ]
    end

    def concatenate(matrix : Matrix) : Nil
      @single = check_float_values(multiply_arrays(matrix.@single, @single))
    end

    def translate(tx : Float32, ty : Float32) : Nil
      @single[6] += (tx * @single[0]) + (ty * @single[3])
      @single[7] += (tx * @single[1]) + (ty * @single[4])
      @single[8] += (tx * @single[2]) + (ty * @single[5])
      check_float_values(@single)
    end

    def scale(sx : Float32, sy : Float32) : Nil
      @single[0] *= sx
      @single[1] *= sx
      @single[2] *= sx
      @single[3] *= sy
      @single[4] *= sy
      @single[5] *= sy
      check_float_values(@single)
    end

    def multiply(other : Matrix) : Matrix
      Matrix.new(check_float_values(multiply_arrays(@single, other.@single)))
    end

    def self.concatenate(a : Matrix, b : Matrix) : Matrix
      b.multiply(a)
    end

    def scaling_factor_x : Float32
      if @single[1] != 0.0_f32
        Math.sqrt((@single[0] * @single[0]) + (@single[1] * @single[1])).to_f32
      else
        @single[0]
      end
    end

    def scaling_factor_y : Float32
      if @single[3] != 0.0_f32
        Math.sqrt((@single[3] * @single[3]) + (@single[4] * @single[4])).to_f32
      else
        @single[4]
      end
    end

    def to_cos_array : Pdfbox::Cos::Array
      array = Pdfbox::Cos::Array.new
      array.add(Pdfbox::Cos::Float.new(@single[0]))
      array.add(Pdfbox::Cos::Float.new(@single[1]))
      array.add(Pdfbox::Cos::Float.new(@single[3]))
      array.add(Pdfbox::Cos::Float.new(@single[4]))
      array.add(Pdfbox::Cos::Float.new(@single[6]))
      array.add(Pdfbox::Cos::Float.new(@single[7]))
      array
    end

    def ==(other : Matrix) : Bool
      @single == other.@single
    end

    def ==(other) : Bool
      false
    end

    private def check_float_values(values : Array(Float32)) : Array(Float32)
      unless values.all?(&.finite?)
        raise ArgumentError.new("Multiplying two matrices produces illegal values")
      end
      values
    end

    private def multiply_arrays(a : Array(Float32), b : Array(Float32)) : Array(Float32)
      c = Array.new(SIZE, 0.0_f32)
      c[0] = (a[0] * b[0]) + (a[1] * b[3]) + (a[2] * b[6])
      c[1] = (a[0] * b[1]) + (a[1] * b[4]) + (a[2] * b[7])
      c[2] = (a[0] * b[2]) + (a[1] * b[5]) + (a[2] * b[8])
      c[3] = (a[3] * b[0]) + (a[4] * b[3]) + (a[5] * b[6])
      c[4] = (a[3] * b[1]) + (a[4] * b[4]) + (a[5] * b[7])
      c[5] = (a[3] * b[2]) + (a[4] * b[5]) + (a[5] * b[8])
      c[6] = (a[6] * b[0]) + (a[7] * b[3]) + (a[8] * b[6])
      c[7] = (a[6] * b[1]) + (a[7] * b[4]) + (a[8] * b[7])
      c[8] = (a[6] * b[2]) + (a[7] * b[5]) + (a[8] * b[8])
      c
    end
  end

  # Ported from Apache PDFBox DateConverter (targeted parity subset).
  module DateConverter
    MINUTES_PER_HOUR    = 60_i64
    SECONDS_PER_MINUTE  = 60_i64
    MILLIS_PER_MINUTE   = SECONDS_PER_MINUTE * 1000_i64
    MILLIS_PER_HOUR     = MINUTES_PER_HOUR * MILLIS_PER_MINUTE
    HALF_DAY            = 12_i64 * MINUTES_PER_HOUR * MILLIS_PER_MINUTE
    DAY                 = 2_i64 * HALF_DAY
    MONTH_NAME_TO_INDEX = {
      "jan" => 1,
      "feb" => 2,
      "mar" => 3,
      "apr" => 4,
      "may" => 5,
      "jun" => 6,
      "jul" => 7,
      "aug" => 8,
      "sep" => 9,
      "oct" => 10,
      "nov" => 11,
      "dec" => 12,
    }

    # Java DateConverter.formatTZoffset equivalent.
    def self.format_tz_offset(millis : Int64, sep : String) : String
      offset = restrain_tz_offset(millis)
      sign = offset < 0 ? '-' : '+'
      abs_offset = offset.abs
      offset_hours = abs_offset // MILLIS_PER_HOUR
      offset_minutes = (abs_offset % MILLIS_PER_HOUR) // MILLIS_PER_MINUTE
      "#{sign}#{offset_hours.to_s.rjust(2, '0')}#{sep}#{offset_minutes.to_s.rjust(2, '0')}"
    end

    def self.to_string(cal : Time?) : String?
      return nil if cal.nil?

      offset = format_tz_offset((cal.offset * 1000).to_i64, "'")

      String.build do |io|
        io << "D:"
        io << cal.year.to_s.rjust(4, '0')
        io << cal.month.to_s.rjust(2, '0')
        io << cal.day.to_s.rjust(2, '0')
        io << cal.hour.to_s.rjust(2, '0')
        io << cal.minute.to_s.rjust(2, '0')
        io << cal.second.to_s.rjust(2, '0')
        io << offset
        io << '\''
      end
    end

    def self.to_iso8601(cal : Time) : String
      offset = format_tz_offset((cal.offset * 1000).to_i64, ":")

      "%04d-%02d-%02dT%02d:%02d:%02d%s" % {
        cal.year, cal.month, cal.day,
        cal.hour, cal.minute, cal.second,
        offset,
      }
    end

    def self.to_calendar(text : String?) : Time?
      return nil if text.nil?
      value = text.strip
      return nil if value.empty?

      value = value[2..] if value.starts_with?("D:")
      normalized = normalize_pdf_tz(value.strip)
      return if normalized.empty?

      parse_ambiguous_big_endian_with_minute(normalized) ||
        parse_compact_with_explicit_tz(normalized) ||
        parse_slash_date(normalized) ||
        parse_iso_with_tz(normalized) ||
        parse_textual_month_with_optional_tz(normalized) ||
        parse_with_exact_formats(normalized)
    end

    private def self.parse_ambiguous_big_endian_with_minute(normalized : String) : Time?
      # Java parseBigEndianDate-compatible ambiguous form: "1970 12 23:08" => HH defaults to 00.
      if match = normalized.match(/^(\d{4})\s+(\d{1,2})\s+(\d{1,2}):(\d{1,2})$/)
        year = match[1].to_i
        month = match[2].to_i
        day = match[3].to_i
        minute = match[4].to_i
        begin
          return Time.parse("%04d%02d%02d00%02d00+0000" % {year, month, day, minute}, "%Y%m%d%H%M%S%z", Time::Location::UTC)
        rescue Time::Format::Error
          return nil
        end
      end
      nil
    end

    private def self.parse_compact_with_explicit_tz(normalized : String) : Time?
      # Java TestDateUtil case: "20190401 6:1:1 -1130"
      if match = normalized.match(/^(\d{4})(\d{2})(\d{2})\s+(\d{1,2}):(\d{1,2}):(\d{1,2})\s*([+-]\d{2})(\d{2})$/)
        year = match[1].to_i
        month = match[2].to_i
        day = match[3].to_i
        hour = match[4].to_i
        minute = match[5].to_i
        second = match[6].to_i
        sign_hour = match[7]
        tz_minute = match[8].to_i
        begin
          return Time.parse("%04d%02d%02d%02d%02d%02d%s%02d" % {year, month, day, hour, minute, second, sign_hour, tz_minute}, "%Y%m%d%H%M%S%z", Time::Location::UTC)
        rescue Time::Format::Error
          return nil
        end
      end
      nil
    end

    private def self.parse_slash_date(normalized : String) : Time?
      # Java-compatible slash date forms used by TestDateUtil#testExtract.
      if match = normalized.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})(?:\s+(\d{1,2}):(\d{1,2}):(\d{1,2}))?$/)
        month = match[1].to_i
        day = match[2].to_i
        year = match[3].to_i
        hour = match[4]?.try(&.to_i) || 0
        minute = match[5]?.try(&.to_i) || 0
        second = match[6]?.try(&.to_i) || 0
        begin
          return Time.utc(year, month, day, hour, minute, second)
        rescue ArgumentError
          return nil
        end
      end
      nil
    end

    private def self.parse_iso_with_tz(normalized : String) : Time?
      formats = {
        "%Y-%m-%dT%H:%M%:z",
        "%Y-%m-%dT%H:%M.%N%:z",
        "%Y-%m-%dT%H:%M:%S%:z",
        "%Y-%m-%dT%H:%M:%S.%N%:z",
        "%Y-%m-%dT%H:%M%z",
        "%Y-%m-%dT%H:%M.%N%z",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S.%N%z",
      }

      formats.each do |fmt|
        begin
          return Time.parse(normalized, fmt, Time::Location::UTC)
        rescue Time::Format::Error
        end
      end
      nil
    end

    private def self.parse_textual_month_with_optional_tz(normalized : String) : Time?
      pattern = /^(\d{4})\s+([A-Za-z]+)\s+(\d{1,2})(?:\s+(?:GMT|UTC)\s*([+-])\s*(\d{1,2})(?::?(\d{2}))?)?$/
      match = normalized.match(pattern)
      return nil unless match

      year = match[1].to_i
      month = month_from_name(match[2])
      return nil unless month
      day = match[3].to_i

      sign = match[4]?
      hours = match[5]?.try(&.to_i) || 0
      minutes = match[6]?.try(&.to_i) || 0
      raw_seconds = (hours * 3600) + (minutes * 60)
      offset_seconds = sign == "-" ? -raw_seconds : raw_seconds

      begin
        location = Time::Location.fixed(offset_seconds)
        Time.local(year, month, day, 0, 0, 0, location: location)
      rescue ArgumentError
        nil
      end
    end

    private def self.parse_with_exact_formats(normalized : String) : Time?
      parse_exact(normalized, /^(\d{8})([+-]\d{2}:\d{2})$/, "%Y%m%d%:z") ||
        parse_exact(normalized, /^(\d{8})([+-]\d{4})$/, "%Y%m%d%z") ||
        parse_exact(normalized, /^(\d{8})(\d{6})([+-]\d{2}:\d{2})$/, "%Y%m%d%H%M%S%:z") ||
        parse_exact(normalized, /^(\d{8})(\d{6})([+-]\d{4})$/, "%Y%m%d%H%M%S%z") ||
        parse_exact(normalized, /^\d{14}$/, "%Y%m%d%H%M%S") ||
        parse_exact(normalized, /^\d{8}$/, "%Y%m%d") ||
        parse_exact(normalized, /^\d{4}$/, "%Y")
    end

    private def self.month_from_name(name : String) : Int32?
      month_key = name.downcase[0, Math.min(3, name.size)]
      MONTH_NAME_TO_INDEX[month_key]?
    end

    private def self.normalize_pdf_tz(value : String) : String
      # Convert PDF timezone form (+01'00' or -02'30') to ISO offset form (+01:00).
      value.gsub(/([+-]\d{2})'(\d{2})'?$/, "\\1:\\2")
    end

    private def self.parse_exact(text : String, guard : Regex, format : String) : Time?
      return nil unless text.matches?(guard)
      begin
        Time.parse(text, format, Time::Location::UTC)
      rescue Time::Format::Error
        nil
      end
    end

    private def self.restrain_tz_offset(proposed_offset : Int64) : Int64
      limit = 14_i64 * MILLIS_PER_HOUR
      if proposed_offset <= limit && proposed_offset >= -limit
        return proposed_offset
      end

      normalized = ((proposed_offset + HALF_DAY) % DAY + DAY) % DAY
      return HALF_DAY if normalized == 0

      (normalized - HALF_DAY) % HALF_DAY
    end
  end
end

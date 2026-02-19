# COS (Cos Object System) module for PDFBox Crystal
#
# This module contains the fundamental object types used in PDF documents,
# corresponding to the COS (Cos Object System) in Apache PDFBox.
module Pdfbox::Cos
  # Error class for COS operations
  class Error < Pdfbox::PDFError; end

  class UnsupportedOperationError < Error; end

  # Tracks document parse lifecycle to decide whether COS updates are accepted.
  class DocumentState
    @parsing = true

    def parsing=(parsing : Bool) : Nil
      @parsing = parsing
    end

    def accepting_updates? : Bool
      !@parsing
    end
  end

  # Tracks incremental-update state for a COS object.
  class UpdateState
    @origin_document_state : DocumentState?
    @updated = false

    def origin_document_state=(origin_document_state : DocumentState?) : Nil
      return if @origin_document_state || origin_document_state.nil?
      @origin_document_state = origin_document_state
      update(true)
    end

    def origin_document_state : DocumentState?
      @origin_document_state
    end

    def updated? : Bool
      @updated
    end

    def update(updated : Bool) : Nil
      return unless @origin_document_state.try(&.accepting_updates?)
      @updated = updated
    end
  end

  # Base class for all COS objects
  abstract class Base
    @direct : Bool = true
    @key : ObjectKey?
    @update_state : UpdateState?

    # Write this object in PDF format to the given IO
    abstract def write_pdf(io : ::IO) : Nil

    # Java compatibility: COSBase#getCOSObject returns the wrapped COS object.
    def cos_object : Base
      self
    end

    # If the state is set true, the dictionary will be written direct into the called object.
    # This means, no indirect object will be created.
    def direct? : Bool
      @direct
    end

    # Set the state true, if the dictionary should be written as a direct object and not indirect.

    def direct=(direct : Bool) : Bool
      @direct = direct
    end

    # This will return the ObjectKey of an indirect object.
    def key : ObjectKey?
      @key
    end

    # Set the ObjectKey of an indirect object.
    def key=(key : ObjectKey?) : Nil
      @key = key
    end

    def update_state : UpdateState
      @update_state ||= UpdateState.new
    end

    def need_to_be_updated? : Bool
      update_state.updated?
    end

    def need_to_be_updated=(flag : Bool) : Nil
      update_state.update(flag)
    end
  end

  # Marker for null values in PDF
  class Null < Base
    # Singleton instance
    INSTANCE = new

    private def initialize
    end

    def self.instance : Null
      INSTANCE
    end

    # Write null in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      io << "null"
    end
  end

  # Boolean value in PDF document
  class Boolean < Base
    # PDF true value
    TRUE = new(true)

    # PDF false value
    FALSE = new(false)

    @value : ::Bool

    private def initialize(@value : Bool)
    end

    # Gets the boolean value
    def value : Bool
      @value
    end

    # Gets the boolean value as object
    def value_as_object : Bool
      @value
    end

    # Gets the boolean value for the given parameter
    def self.get(value : Bool) : Boolean
      value ? TRUE : FALSE
    end

    # Write this boolean in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      io << (@value ? "true" : "false")
    end

    def ==(other : self) : Bool
      same?(other)
    end

    def ==(other) : Bool
      false
    end

    # Match java.lang.Boolean hash constants used by Apache PDFBox.
    def hash : Int32
      @value ? 1231 : 1237
    end

    def to_s(io : ::IO) : Nil
      io << (@value ? "true" : "false")
    end
  end

  # Marker module for numeric types (Integer and Float)
  module Number
    def self.get(number : ::String) : Integer | Float
      return parse_single_char(number) if number.size == 1
      return Float.new(number.to_f64) if number.includes?('.') || number.includes?('e')
      parse_integer_or_out_of_range(number)
    end

    private def self.parse_single_char(number : ::String) : Integer
      digit = number[0]
      return Integer.get((digit.ord - '0'.ord).to_i64) if digit >= '0' && digit <= '9'
      return Integer::ZERO if digit == '-' || digit == '.'
      raise Error.new("Not a number: #{number}")
    end

    private def self.parse_integer_or_out_of_range(number : ::String) : Integer
      Integer.get(number.to_i64)
    rescue
      number_string = (number.starts_with?('+') || number.starts_with?('-')) ? number[1..] : number
      raise Error.new("Not a number: #{number}") unless /\A\d*\z/.matches?(number_string)
      number.starts_with?('-') ? Integer::OUT_OF_RANGE_MIN : Integer::OUT_OF_RANGE_MAX
    end
  end

  # PDFDocEncoding mapping used for PDF text strings.
  module PDFDocEncoding
    CODE_TO_UNI = ::Array(Char).new(256, '\u0000')
    UNI_TO_CODE = ::Hash(Char, UInt8).new

    private def self.set(code : Int32, unicode : Char) : Nil
      CODE_TO_UNI[code] = unicode
      UNI_TO_CODE[unicode] = code.to_u8
    end

    private def self.init : Nil
      (0..255).each do |i|
        next if i > 0x17 && i < 0x20
        next if i > 0x7E && i < 0xA1
        next if i == 0xAD
        set(i, i.chr)
      end

      set(0x18, '\u02D8')
      set(0x19, '\u02C7')
      set(0x1A, '\u02C6')
      set(0x1B, '\u02D9')
      set(0x1C, '\u02DD')
      set(0x1D, '\u02DB')
      set(0x1E, '\u02DA')
      set(0x1F, '\u02DC')
      set(0x7F, '\uFFFD')
      set(0x80, '\u2022')
      set(0x81, '\u2020')
      set(0x82, '\u2021')
      set(0x83, '\u2026')
      set(0x84, '\u2014')
      set(0x85, '\u2013')
      set(0x86, '\u0192')
      set(0x87, '\u2044')
      set(0x88, '\u2039')
      set(0x89, '\u203A')
      set(0x8A, '\u2212')
      set(0x8B, '\u2030')
      set(0x8C, '\u201E')
      set(0x8D, '\u201C')
      set(0x8E, '\u201D')
      set(0x8F, '\u2018')
      set(0x90, '\u2019')
      set(0x91, '\u201A')
      set(0x92, '\u2122')
      set(0x93, '\uFB01')
      set(0x94, '\uFB02')
      set(0x95, '\u0141')
      set(0x96, '\u0152')
      set(0x97, '\u0160')
      set(0x98, '\u0178')
      set(0x99, '\u017D')
      set(0x9A, '\u0131')
      set(0x9B, '\u0142')
      set(0x9C, '\u0153')
      set(0x9D, '\u0161')
      set(0x9E, '\u017E')
      set(0x9F, '\uFFFD')
      set(0xA0, '\u20AC')
    end

    init

    def self.to_string(bytes : Bytes) : ::String
      ::String.build do |str|
        bytes.each do |byte|
          str << CODE_TO_UNI[byte]
        end
      end
    end

    def self.get_bytes(text : ::String) : Bytes
      Bytes.new(text.size) do |i|
        UNI_TO_CODE.fetch(text[i], 0_u8)
      end
    end

    def self.contains_char?(character : Char) : Bool
      UNI_TO_CODE.has_key?(character)
    end
  end

  # Integer value in PDF document
  class Integer < Base
    include Number
    LOW              = -100_i64
    HIGH             =  256_i64
    OUT_OF_RANGE_MAX = new(Int64::MAX, false)
    OUT_OF_RANGE_MIN = new(Int64::MIN, false)
    ZERO             = get(0_i64)
    ONE              = get(1_i64)
    TWO              = get(2_i64)
    THREE            = get(3_i64)

    @@cache = Hash(Int64, Integer).new

    @value : Int64
    @valid : Bool

    def initialize(@value : Int64, @valid : Bool = true)
    end

    def self.get(value : Int64) : Integer
      if value >= LOW && value <= HIGH
        @@cache[value] ||= new(value)
      else
        new(value)
      end
    end

    def value : Int64
      @value
    end

    def value_as_object : Int64
      @value
    end

    # Check if integer is within valid PDF range (signed 32-bit)
    def valid? : Bool
      @valid
    end

    # Write this integer in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      io << @value
    end

    def to_s(io : ::IO) : Nil
      io << @value
    end

    def ==(other : self) : Bool
      @value == other.@value
    end

    def ==(other) : Bool
      false
    end

    def_hash @value
  end

  # Floating point value in PDF document
  class Float < Base
    include Number
    @value : Float64

    def initialize(@value : Float64)
    end

    def value : Float64
      @value
    end

    def value_as_object : Float64
      @value
    end

    # Write this float in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      io << format_string
    end

    def to_s(io : ::IO) : Nil
      io << "COSFloat{" << format_string << "}"
    end

    def ==(other : self) : Bool
      value_bits == other.@value.unsafe_as(UInt64)
    end

    def ==(other) : Bool
      false
    end

    def hash : UInt64
      value_bits.hash
    end

    private def value_bits : UInt64
      @value.unsafe_as(UInt64)
    end

    private def format_string : ::String
      text = @value.to_s
      return text unless text.includes?('e') || text.includes?('E')
      expand_scientific_notation(text)
    end

    private def expand_scientific_notation(text : ::String) : ::String
      sign = ""
      mantissa_and_exponent = text
      if mantissa_and_exponent.starts_with?('-')
        sign = "-"
        mantissa_and_exponent = mantissa_and_exponent[1..]
      elsif mantissa_and_exponent.starts_with?('+')
        mantissa_and_exponent = mantissa_and_exponent[1..]
      end

      parts = mantissa_and_exponent.split(/e|E/, 2)
      mantissa = parts[0]
      exponent = parts[1].to_i

      decimal_point = mantissa.index('.')
      if decimal_point
        int_part = mantissa[0...decimal_point]
        frac_part = mantissa[(decimal_point + 1)..]
      else
        int_part = mantissa
        frac_part = ""
      end
      digits = int_part + frac_part
      decimal_position = int_part.size + exponent

      plain =
        if decimal_position <= 0
          "0." + ("0" * -decimal_position) + digits
        elsif decimal_position >= digits.size
          digits + ("0" * (decimal_position - digits.size))
        else
          digits[0...decimal_position] + "." + digits[decimal_position..]
        end

      if plain.includes?('.')
        while plain.ends_with?('0')
          plain = plain[0...-1]
        end
        plain = plain[0...-1] if plain.ends_with?('.')
      end

      plain = "0" if plain.empty?
      sign + plain
    end
  end

  # String value in PDF document
  class String < Base
    @bytes : Bytes
    @force_hex_form : Bool

    # Creates a new PDF string from a String (text string)
    def initialize(string : ::String, @force_hex_form : Bool = false)
      if string.each_char.all? { |char| PDFDocEncoding.contains_char?(char) }
        @bytes = PDFDocEncoding.get_bytes(string)
      else
        utf16 = string.to_utf16
        @bytes = Bytes.new(2 + utf16.size * 2)
        @bytes[0] = 0xFE_u8
        @bytes[1] = 0xFF_u8
        utf16.each_with_index do |code_unit, index|
          @bytes[2 + index * 2] = ((code_unit >> 8) & 0xFF).to_u8
          @bytes[3 + index * 2] = (code_unit & 0xFF).to_u8
        end
      end
    end

    # Creates a new PDF string from raw bytes
    def initialize(@bytes : Bytes, @force_hex_form : Bool = false)
    end

    # Gets the string value as a PDF text string.
    def value : ::String
      if @bytes.size >= 2
        if @bytes[0] == 0xFE_u8 && @bytes[1] == 0xFF_u8
          return ::String.new(@bytes[2, @bytes.size - 2], "UTF-16BE")
        elsif @bytes[0] == 0xFF_u8 && @bytes[1] == 0xFE_u8
          return ::String.new(@bytes[2, @bytes.size - 2], "UTF-16LE")
        end
      end

      PDFDocEncoding.to_string(@bytes)
    end

    # Gets the string value as object
    def value_as_object : ::String
      value
    end

    # Gets the raw bytes
    def bytes : Bytes
      @bytes
    end

    # Whether this string should be written in hex form
    def force_hex_form? : Bool
      @force_hex_form
    end

    # Creates a COS string from a hex string representation
    def self.parse_hex(hex : ::String) : self
      # Remove whitespace
      hex = hex.strip
      return new(Bytes.empty, false) if hex.empty?

      result = Bytes.new((hex.size + 1) // 2)
      i = 0
      j = 0

      while i + 1 < hex.size
        high = hex_char_to_nibble(hex[i])
        low = hex_char_to_nibble(hex[i + 1])
        result[j] = (high << 4 | low).to_u8
        i += 2
        j += 1
      end

      # Handle odd number of hex digits
      if i < hex.size
        high = hex_char_to_nibble(hex[i])
        result[j] = (high << 4).to_u8
        j += 1
      end

      bytes = result[0, j]
      # Handle BOM: if string contains only BOM, return empty string
      # PDFBOX-3881: Test that if String has only the BOM, that it be an empty string.
      if bytes.size == 2
        if (bytes[0] == 0xFE_u8 && bytes[1] == 0xFF_u8) ||
           (bytes[0] == 0xFF_u8 && bytes[1] == 0xFE_u8)
          bytes = Bytes.empty
        end
      end
      new(bytes, false)
    end

    private def self.hex_char_to_nibble(char : Char) : UInt8
      case char
      when '0'..'9'
        (char - '0').to_u8
      when 'a'..'f'
        (char - 'a' + 10).to_u8
      when 'A'..'F'
        (char - 'A' + 10).to_u8
      else
        raise Error.new("Invalid hex character: #{char.inspect}")
      end
    end

    # Returns hex representation of the string bytes
    def to_hex_string : ::String
      ::String.build do |str|
        @bytes.each do |byte|
          str << "0123456789ABCDEF"[byte >> 4]
          str << "0123456789ABCDEF"[byte & 0x0F]
        end
      end
    end

    # Write this string in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      Pdfbox::Pdfwriter::PDFIO.write_string(io, @bytes, @force_hex_form)
    end

    # Equality comparison
    def ==(other : self) : Bool
      value == other.value && @force_hex_form == other.@force_hex_form
    end

    def ==(other) : Bool
      false
    end

    # Hash code
    def_hash @bytes, @force_hex_form
  end

  # Name object in PDF document (PDF keyword)
  class Name < Base
    @value : ::String

    def initialize(@value : ::String)
    end

    def value : ::String
      @value
    end

    def value_as_object : ::String
      @value
    end

    # Write this name in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      Pdfbox::Pdfwriter::PDFIO.write_name(io, @value)
    end

    def ==(other : self) : Bool
      @value == other.@value
    end

    def ==(other) : Bool
      false
    end

    def_hash @value
  end

  # Array of COS objects
  class Array < Base
    @items = [] of Base

    def initialize(items : Enumerable = [] of Base)
      @items = items.map { |item| item.as(Base) }.to_a
    end

    def self.of_cos_names(names : Enumerable(::String)) : self
      new(names.map { |name| Name.new(name) })
    end

    def self.of_cos_strings(strings : Enumerable(::String)) : self
      new(strings.map { |value| String.new(value) })
    end

    def self.of_cos_integers(values : Enumerable(Int)) : self
      new(values.map { |value| Integer.get(value.to_i64) })
    end

    def items : ::Array(Base)
      @items
    end

    def add(item : Base) : self
      @items << item
      self
    end

    def [](index : Int) : Base
      @items[index]
    end

    def []?(index : Int) : Base?
      @items[index]?
    end

    def get(index : Int) : Base?
      self[index]?
    end

    def []=(index : Int, value : Base) : Base
      @items[index] = value
    end

    def get_string(index : Int, default : ::String? = nil) : ::String?
      value = self[index]?
      return default unless value.is_a?(String)
      value.value
    end

    def get_name(index : Int, default : ::String? = nil) : ::String?
      value = self[index]?
      return default unless value.is_a?(Name)
      value.value
    end

    def get_int(index : Int, default : Int64 = 0_i64) : Int64
      value = self[index]?
      return default unless value.is_a?(Integer)
      value.value
    end

    def set_name(index : Int, value : ::String) : Nil
      self[index] = Name.new(value)
    end

    def set_int(index : Int, value : Int) : Nil
      self[index] = Integer.get(value.to_i64)
    end

    def set_string(index : Int, value : ::String) : Nil
      self[index] = String.new(value)
    end

    def to_cos_name_string_list : ::Array(::String?)
      @items.map { |item| item.as?(Name).try(&.value) }
    end

    def to_cos_string_string_list : ::Array(::String?)
      @items.map { |item| item.as?(String).try(&.value) }
    end

    def to_cos_number_integer_list : ::Array(Int64?)
      @items.map { |item| item.as?(Integer).try(&.value) }
    end

    def float_array=(values : Enumerable(Float32 | Float64 | Int | Int64)) : Nil
      @items.clear
      values.each do |value|
        @items << Float.new(value.to_f64)
      end
    end

    def to_cos_number_float_list : ::Array(Float64?)
      @items.map do |item|
        case item
        when Float
          item.value
        when Integer
          item.value.to_f64
        end
      end
    end

    def to_float_array : ::Array(Float64)
      to_cos_number_float_list.map { |value| value || 0.0_f64 }
    end

    def to_list : ::Array(Base)
      @items.dup
    end

    def index_of(value : Base) : Int32
      index = @items.index(value)
      index ? index.to_i32 : -1
    end

    def clear : Nil
      @items.clear
    end

    def remove(index : Int) : Base
      delete_at(index)
    end

    def remove_object(value : Base) : Bool
      !!@items.delete(value)
    end

    def remove_all(values : Enumerable(Base)) : Nil
      values.each { |value| @items.delete(value) }
    end

    def retain_all(values : Enumerable(Base)) : Nil
      keep = values.to_set
      @items.select! { |item| keep.includes?(item) }
    end

    def grow_to_size(size : Int, fill_value : Base = Null.instance) : Nil
      return if @items.size >= size
      (size - @items.size).times { @items << fill_value }
    end

    def size : Int32
      @items.size
    end

    # Remove element at index and return it
    def delete_at(index : Int) : Base
      @items.delete_at(index)
    end

    # Write this array in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      io << '['
      @items.each_with_index do |item, index|
        item.write_pdf(io)
        if index < @items.size - 1
          Pdfbox::Pdfwriter::PDFIO.write_whitespace(io)
        end
      end
      io << ']'
    end

    def ==(other : self) : Bool
      @items == other.@items
    end

    def ==(other) : Bool
      false
    end

    def_hash @items
  end

  # Dictionary (key-value pairs) of COS objects
  class Dictionary < Base
    @entries = {} of Name => Base

    def initialize(@entries : ::Hash(Name, Base) = {} of Name => Base)
    end

    def entries : ::Hash(Name, Base)
      @entries
    end

    def []=(key : Name, value : Base) : Base
      @entries[key] = value
    end

    def set_item(key : Name, value : Base) : Base
      self[key] = value
    end

    def set_item(key : ::String, value : Base) : Base
      self[Name.new(key)] = value
    end

    def [](key : Name) : Base?
      @entries[key]?
    end

    def has_key?(key : Name) : Bool
      @entries.has_key?(key)
    end

    def contains_key?(key : ::String) : Bool
      has_key?(Name.new(key))
    end

    def delete(key : Name) : Base?
      @entries.delete(key)
    end

    def remove_item(key : Name) : Base?
      delete(key)
    end

    def clear : Nil
      @entries.clear
    end

    def add_all(other : Dictionary) : Nil
      other.entries.each do |key, value|
        @entries[key] = value
      end
    end

    def size : Int32
      @entries.size
    end

    def set_flag(key : Name, bit_flag : Int32, value : Bool) : Nil
      int_value = self[key].as?(Integer).try(&.value) || 0_i64
      updated =
        if value
          int_value | bit_flag
        else
          int_value & ~bit_flag
        end
      self[key] = Integer.new(updated)
    end

    def set_boolean(key : Name, value : Bool) : Nil
      self[key] = Boolean.get(value)
    end

    def set_boolean(key : ::String, value : Bool) : Nil
      set_boolean(Name.new(key), value)
    end

    def set_name(key : Name, value : ::String) : Nil
      self[key] = Name.new(value)
    end

    def set_name(key : ::String, value : ::String) : Nil
      set_name(Name.new(key), value)
    end

    def set_date(key : Name, value : Time) : Nil
      self[key] = String.new(value.to_s("%Y%m%d%H%M%S"))
    end

    def set_date(key : ::String, value : Time) : Nil
      set_date(Name.new(key), value)
    end

    def set_embedded_date(embedded : Name, key : Name, value : Time) : Nil
      embedded_dict = self[embedded].as?(Dictionary) || Dictionary.new
      embedded_dict.set_date(key, value)
      self[embedded] = embedded_dict
    end

    def set_string(key : Name, value : ::String) : Nil
      self[key] = String.new(value)
    end

    def set_string(key : ::String, value : ::String) : Nil
      set_string(Name.new(key), value)
    end

    def set_embedded_string(embedded : Name, key : Name, value : ::String) : Nil
      embedded_dict = self[embedded].as?(Dictionary) || Dictionary.new
      embedded_dict.set_string(key, value)
      self[embedded] = embedded_dict
    end

    def set_int(key : Name, value : Int) : Nil
      self[key] = Integer.new(value.to_i64)
    end

    def set_int(key : ::String, value : Int) : Nil
      set_int(Name.new(key), value)
    end

    def set_embedded_int(embedded : Name, key : Name, value : Int) : Nil
      embedded_dict = self[embedded].as?(Dictionary) || Dictionary.new
      embedded_dict.set_int(key, value)
      self[embedded] = embedded_dict
    end

    def set_long(key : Name, value : Int64) : Nil
      self[key] = Integer.new(value)
    end

    def set_long(key : ::String, value : Int64) : Nil
      set_long(Name.new(key), value)
    end

    def set_float(key : Name, value : Float64) : Nil
      self[key] = Float.new(value)
    end

    def set_float(key : ::String, value : Float64) : Nil
      set_float(Name.new(key), value)
    end

    def as_unmodifiable_dictionary : Dictionary
      UnmodifiableDictionary.new(@entries)
    end

    # Write this dictionary in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      io << "<<"
      @entries.each do |key, value|
        key.write_pdf(io)
        Pdfbox::Pdfwriter::PDFIO.write_whitespace(io)
        value.write_pdf(io)
        Pdfbox::Pdfwriter::PDFIO.write_whitespace(io)
      end
      io << ">>"
    end

    def ==(other : self) : Bool
      @entries == other.@entries
    end

    def ==(other) : Bool
      false
    end

    def_hash @entries
  end

  # Stream object (dictionary with binary data)
  class Stream < Dictionary
    @data : Bytes = Bytes.empty

    def initialize(entries : ::Hash(Name, Base) = {} of Name => Base, @data : Bytes = Bytes.empty)
      super(entries)
    end

    def data : Bytes
      @data
    end

    def data=(@data : Bytes) : Bytes
      @data
    end

    # Write this stream in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      # Write stream dictionary
      super
      io << '\n' << "stream" << '\n'
      io.write(@data)
      io << '\n' << "endstream"
    end

    def ==(other : self) : Bool
      super && @data == other.@data
    end

    def ==(other) : Bool
      false
    end

    def_hash @data
  end

  # Object reference (indirect object) - corresponds to COSObject in Apache PDFBox
  class Object < Base
    Log = ::Log.for(self)

    @base_object : Base?
    @parser : ICOSParser?
    @is_dereferenced = false
    @key : ObjectKey?

    # Constructor for already dereferenced object
    def initialize(object : Base)
      @base_object = object
      @parser = nil
      @is_dereferenced = true
      @key = nil
    end

    # Constructor for object with parser reference for lazy resolution
    def initialize(key : ObjectKey, parser : ICOSParser)
      @base_object = nil
      @parser = parser
      @is_dereferenced = false
      @key = key
    end

    # Constructor for object with object number/generation and parser
    def initialize(object_number : Int64, generation_number : Int64, parser : ICOSParser)
      @base_object = nil
      @parser = parser
      @is_dereferenced = false
      @key = ObjectKey.new(object_number, generation_number)
    end

    # Legacy constructor for compatibility
    def initialize(object_number : Int64, generation_number : Int64 = 0, object : Base? = nil)
      @base_object = object
      @parser = nil
      @is_dereferenced = object != nil
      @key = ObjectKey.new(object_number, generation_number)
    end

    def object_number : Int64
      key = @key
      return 0_i64 unless key
      key.number
    end

    def generation_number : Int64
      key = @key
      return 0_i64 unless key
      key.generation
    end

    def generation : Int64
      generation_number
    end

    def obj_number : Int64
      object_number
    end

    def gen_number : Int64
      generation_number
    end

    # Get the encapsulated object, dereferencing if needed
    def object : Base?
      if !@is_dereferenced && (parser = @parser)
        begin
          # Mark as dereferenced to avoid endless recursions
          @is_dereferenced = true
          @base_object = parser.dereference_object(self)
          @parser = nil
        rescue ex
          Log.error { "Can't dereference #{self}: #{ex.message}" }
          # Return nil on error
          return
        end
      end
      @base_object
    end

    def object=(object : Base?) : Base?
      @base_object = object
      @is_dereferenced = object != nil
      @parser = nil
      object
    end

    def object_null? : Bool
      @base_object.nil?
    end

    def key : ObjectKey?
      @key
    end

    def key=(key : ObjectKey?) : ObjectKey?
      @key = key
    end

    # Write this object reference in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
      io << object_number << ' ' << generation_number << " R"
    end

    def ==(other : self) : Bool
      key1 = @key
      key2 = other.@key
      return false unless key1 && key2
      key1 == key2
    end

    def ==(other) : Bool
      false
    end

    def_hash @key

    def to_s(io : IO) : Nil
      if key = @key
        io << "COSObject{" << key << "}"
      else
        io << "COSObject{unknown}"
      end
    end
  end

  # Minimal COSDocument implementation used for COS-level document tests.
  class Document < Base
    @xref_table = {} of ObjectKey? => Int64
    @object_pool = {} of ObjectKey => Object

    def write_pdf(io : ::IO) : Nil
      io << "%COSDocument"
    end

    def add_xref_table(values : Hash(ObjectKey?, Int64)) : Nil
      values.each do |key, value|
        @xref_table[key] = value
      end
    end

    def set_object(key : ObjectKey, object : Object) : Nil
      @object_pool[key] = object
    end

    def objects_by_type(type : Name) : ::Array(Object)
      result = [] of Object
      @xref_table.each_key do |object_key|
        next unless object_key
        object = @object_pool[object_key]?
        next unless object
        real_object = object.object
        next unless real_object.is_a?(Dictionary)
        dict_type = real_object[Name.new("Type")]
        result << object if dict_type == type
      end
      result
    end

    def linearized_dictionary : Dictionary?
      @xref_table.each do |object_key, offset|
        next unless object_key
        next unless offset > 0
        object = @object_pool[object_key]?
        next unless object
        real_object = object.object
        next unless real_object.is_a?(Dictionary)
        return real_object if real_object[Name.new("Linearized")]
      end
      nil
    end
  end

  class UnmodifiableDictionary < Dictionary
    def initialize(entries : ::Hash(Name, Base) = {} of Name => Base)
      super(entries.dup)
    end

    def []=(key : Name, value : Base) : Base
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def clear : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def delete(key : Name) : Base?
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def remove_item(key : Name) : Base?
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def add_all(other : Dictionary) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_flag(key : Name, bit_flag : Int32, value : Bool) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def need_to_be_updated=(flag : Bool) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_item(key : Name, value : Base) : Base
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_item(key : ::String, value : Base) : Base
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_boolean(key : Name, value : Bool) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_boolean(key : ::String, value : Bool) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_name(key : Name, value : ::String) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_name(key : ::String, value : ::String) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_date(key : Name, value : Time) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_date(key : ::String, value : Time) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_embedded_date(embedded : Name, key : Name, value : Time) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_string(key : Name, value : ::String) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_string(key : ::String, value : ::String) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_embedded_string(embedded : Name, key : Name, value : ::String) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_int(key : Name, value : Int) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_int(key : ::String, value : Int) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_embedded_int(embedded : Name, key : Name, value : Int) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_long(key : Name, value : Int64) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_long(key : ::String, value : Int64) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_float(key : Name, value : Float64) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end

    def set_float(key : ::String, value : Float64) : Nil
      raise UnsupportedOperationError.new("Unmodifiable dictionary")
    end
  end
end

# COS (Cos Object System) module for PDFBox Crystal
#
# This module contains the fundamental object types used in PDF documents,
# corresponding to the COS (Cos Object System) in Apache PDFBox.
require "compress/zlib"
require "../pdfbox"
require "../xmpbox/date_converter"

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

    # Java compatibility: COSBase#accept routes to a COS visitor/writer.
    def accept(visitor) : Nil
      visitor.write(self)
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

    # Convert to integer (default 0). Subclasses may override.
    def as_i : Int32
      0
    end

    # This will return the ObjectKey of an indirect object.
    def key : ObjectKey?
      @key
    end

    # Set the ObjectKey of an indirect object.
    def key=(key : ObjectKey?) : Nil
      @key = key
    end

    # Collects and clears all indirect object keys reachable from this object.
    # Used to avoid overlapping object numbers when importing a page into
    # another document. Java COSBase/COSDictionary/COSArray#resetObjectKeys.
    def reset_object_keys(indirect_objects : Set(ObjectKey)) : Set(ObjectKey)
      indirect_objects
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

    def as_i : Int32
      0
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

    def as_i : Int32
      @value ? 1 : 0
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
    # Shared numeric conversions used by PDF model code.
    def to_i : Int32
      as_i
    end

    def to_f32 : Float32
      case self
      when Pdfbox::Cos::Integer
        value.to_f32
      when Pdfbox::Cos::Float
        value.to_f32
      else
        0.0_f32
      end
    end

    def self.get(number : ::String) : Integer | Float
      return parse_single_char(number) if number.size == 1
      return parse_float(number) if number.includes?('.') || number.includes?('e') || number.includes?('E')
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

    # Java COSFloat(String) parity:
    # - accepts certain malformed values by normalizing misplaced negatives
    # - clamps infinities to Float::MAX
    # - coerces subnormal values to 0
    private def self.parse_float(number : ::String) : Float
      parsed = try_parse_float64(number)
      return Float.new(coerce_float64(parsed)) if parsed

      normalized = normalize_malformed_float(number) || raise Error.new("Not a number: #{number}")
      reparsed = try_parse_float64(normalized) || raise Error.new("Not a number: #{number}")
      Float.new(coerce_float64(reparsed))
    end

    private def self.try_parse_float64(text : ::String) : Float64?
      text.to_f64
    rescue ArgumentError
      nil
    end

    private def self.normalize_malformed_float(text : ::String) : ::String?
      return text[1..] if text.starts_with?("--")
      return "-" + text.sub("-", "") if /^0\.0*-\d+$/.matches?(text)
      return "-" + text.gsub("-", "") if /^-\d+\.-\d+$/.matches?(text)
      nil
    end

    private def self.coerce_float64(value : Float64) : Float64
      return Float32::MAX.to_f64 if value > Float32::MAX
      return -Float32::MAX.to_f64 if value < -Float32::MAX
      return 0_f64 if value.abs < Float32::MIN_POSITIVE
      value
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

    def as_i : Int32
      @value.to_i
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
    ZERO = new(0.0)
    ONE  = new(1.0)
    @value : Float64

    def initialize(@value : Float64)
    end

    def value : Float64
      @value
    end

    def value_as_object : Float64
      @value
    end

    def as_i : Int32
      @value.to_i
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
    def initialize(bytes : Bytes, @force_hex_form : Bool = false)
      @bytes = bytes.dup
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

    def as_i : Int32
      value.to_i? || 0
    end

    # Gets the raw bytes
    def bytes : Bytes
      @bytes.dup
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

    FILTER                      = new("Filter")
    FLATE_DECODE                = new("FlateDecode")
    ASCII85_DECODE              = new("ASCII85Decode")
    RUN_LENGTH_DECODE           = new("RunLengthDecode")
    LZW_DECODE                  = new("LZWDecode")
    LENGTH                      = new("Length")
    TYPE                        = new("Type")
    OUTPUT_INTENT               = new("OutputIntent")
    GTS_PDFA1                   = new("GTS_PDFA1")
    DEST_OUTPUT_PROFILE         = new("DestOutputProfile")
    INFO                        = new("Info")
    OUTPUT_CONDITION            = new("OutputCondition")
    OUTPUT_CONDITION_IDENTIFIER = new("OutputConditionIdentifier")
    REGISTRY_NAME               = new("RegistryName")
    FUNCTION                    = new("Function")
    FUNCTION_TYPE               = new("FunctionType")
    DOMAIN                      = new("Domain")
    RANGE                       = new("Range")
    C0                          = new("C0")
    C1                          = new("C1")
    N                           = new("N")
    SIZE                        = new("Size")
    BITS_PER_SAMPLE             = new("BitsPerSample")
    ORDER                       = new("Order")
    ENCODE                      = new("Encode")
    DECODE                      = new("Decode")
    BOUNDS                      = new("Bounds")
    FUNCTIONS                   = new("Functions")
    IDENTITY                    = new("Identity")
    KIDS                        = new("Kids")
    NAMES                       = new("Names")
    NUMS                        = new("Nums")
    LIMITS                      = new("Limits")
    P                           = new("P")
    S                           = new("S")
    ST                          = new("ST")
    EMBEDDED_FILE               = new("EmbeddedFile")
    SUBTYPE                     = new("Subtype")
    PARAMS                      = new("Params")
    CREATION_DATE               = new("CreationDate")
    MOD_DATE                    = new("ModDate")
    CHECK_SUM                   = new("CheckSum")
    MAC                         = new("Mac")
    CREATOR                     = new("Creator")
    RES_FORK                    = new("ResFork")
    OBJ_STM                     = new("ObjStm")
    FIRST                       = new("First")
    LAST                        = new("Last")
    PARENT                      = new("Parent")
    PREV                        = new("Prev")
    NEXT                        = new("Next")
    COUNT                       = new("Count")
    OUTLINES                    = new("Outlines")
    TITLE                       = new("Title")
    A                           = new("A")
    C                           = new("C")
    F                           = new("F")
    SE                          = new("SE")
    EXTENDS                     = new("Extends")
    STANDARD_ENCODING           = new("StandardEncoding")
    WIN_ANSI_ENCODING           = new("WinAnsiEncoding")
    MAC_ROMAN_ENCODING          = new("MacRomanEncoding")
    MAC_EXPERT_ENCODING         = new("MacExpertEncoding")
    SYMBOL_ENCODING             = new("SymbolEncoding")
    ZAPF_DINGBATS_ENCODING      = new("ZapfDingbatsEncoding")
    ENCODING                    = new("Encoding")
    BASE_ENCODING               = new("BaseEncoding")
    DIFFERENCES                 = new("Differences")
    # Font-related constants
    FONT             = new("Font")
    FONT_DESC        = new("FontDescriptor")
    FONT_NAME        = new("FontName")
    FONT_FAMILY      = new("FontFamily")
    FONT_WEIGHT      = new("FontWeight")
    FONT_STRETCH     = new("FontStretch")
    FLAGS            = new("Flags")
    FONT_BBOX        = new("FontBBox")
    ITALIC_ANGLE     = new("ItalicAngle")
    ASCENT           = new("Ascent")
    DESCENT          = new("Descent")
    LEADING          = new("Leading")
    CAP_HEIGHT       = new("CapHeight")
    XHEIGHT          = new("XHeight")
    STEM_V           = new("StemV")
    STEM_H           = new("StemH")
    AVG_WIDTH        = new("AvgWidth")
    MAX_WIDTH        = new("MaxWidth")
    CHAR_SET         = new("CharSet")
    FONT_FILE        = new("FontFile")
    FONT_FILE2       = new("FontFile2")
    FONT_FILE3       = new("FontFile3")
    CID_SET          = new("CIDSet")
    STYLE            = new("Style")
    PANOSE           = new("Panose")
    BASE_FONT        = new("BaseFont")
    NAME             = new("Name")
    RESOURCES        = new("Resources")
    DESCENDANT_FONTS = new("DescendantFonts")
    TYPE0            = new("Type0")
    TYPE1            = new("Type1")
    MM_TYPE1         = new("MMType1")
    TYPE3            = new("Type3")
    TRUE_TYPE        = new("TrueType")
    OPEN_TYPE        = new("OpenType")
    CID_FONT_TYPE0   = new("CIDFontType0")
    CID_FONT_TYPE2   = new("CIDFontType2")
    TO_UNICODE       = new("ToUnicode")
    FONT_MATRIX      = new("FontMatrix")
    CHAR_PROCS       = new("CharProcs")
    FILESPEC         = new("Filespec")
    CIDSYSTEMINFO    = new("CIDSystemInfo")
    CID_TO_GID_MAP   = new("CIDToGIDMap")
    WIDTHS           = new("Widths")
    W                = new("W")
    W2               = new("W2")
    DW               = new("DW")
    DW2              = new("DW2")
    MISSING_WIDTH    = new("MissingWidth")
    FIRST_CHAR       = new("FirstChar")
    LAST_CHAR        = new("LastChar")
    IDENTITY_H       = new("Identity-H")
    IDENTITY_V       = new("Identity-V")
    REGISTRY         = new("Registry")
    ORDERING         = new("Ordering")
    SUPPLEMENT       = new("Supplement")
    # Structure tree / logical structure keys
    K                    = new("K")
    PG                   = new("Pg")
    ID                   = new("ID")
    ENCRYPT              = new("Encrypt")
    OBJ                  = new("Obj")
    MCR                  = new("MCR")
    OBJR                 = new("OBJR")
    ANNOTS               = new("Annots")
    ANNOT                = new("Annot")
    LINK                 = new("Link")
    B                    = new("B")
    STRUCT_PARENTS       = new("StructParents")
    STRUCT_PARENT        = new("StructParent")
    ROLE_MAP             = new("RoleMap")
    PARENT_TREE          = new("ParentTree")
    PARENT_TREE_NEXT_KEY = new("ParentTreeNextKey")
    ID_TREE              = new("IDTree")
    CLASS_MAP            = new("ClassMap")
    LANG                 = new("Lang")
    METADATA             = new("Metadata")
    PAGE_LABELS          = new("PageLabels")
    OUTPUT_INTENTS       = new("OutputIntents")
    # Marked-content keys
    MCID            = new("MCID")
    ACTUAL_TEXT     = new("ActualText")
    ARTIFACT        = new("Artifact")
    ALT             = new("Alt")
    E               = new("E")
    BBOX            = new("BBox")
    ATTACHED        = new("Attached")
    MARK_INFO       = new("MarkInfo")
    MARKED          = new("Marked")
    SUSPECTS        = new("Suspects")
    USER_PROPERTIES = new("UserProperties")

    def initialize(@value : ::String)
    end

    def value : ::String
      @value
    end

    def value_as_object : ::String
      @value
    end

    def as_i : Int32
      0
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

    def initialize(items : Nil)
      raise ArgumentError.new("items cannot be nil")
    end

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

    # Builds a COSArray of COSFloats from the given values (Java COSArray#of(float...)).
    def self.of(floats : Enumerable(::Float)) : self
      new(floats.map { |value| Float.new(value.to_f64) })
    end

    def items : ::Array(Base)
      @items
    end

    def add(item : Base) : self
      @items << item
      self
    end

    # Insert item at index
    def add(index : Int, item : Base) : self
      @items.insert(index, item)
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

    # Identity-based search (Java COSArray#indexOfObject), as opposed to
    # index_of which compares by equality.
    def index_of_object(value : Base) : Int32
      @items.each_with_index do |item, index|
        return index.to_i32 if item.same?(value)
      end
      -1
    end

    # Replaces each element with the given float value, requiring the array to
    # already have the same length (Java COSArray#setFloatArray).
    def set_float_array(values : Enumerable(::Float)) : Nil # ameba:disable Naming/AccessorMethodName
      unless size == values.size
        raise ArgumentError.new("Array size does not match")
      end
      values.each_with_index do |value, index|
        self[index] = Float.new(value.to_f64)
      end
    end

    def empty? : Bool
      @items.empty?
    end

    def clear : Nil
      @items.clear
    end

    def remove(index : Int) : Base
      delete_at(index)
    end

    def remove_object(value : Base) : Bool
      # Java COSArray.removeObject calls ArrayList.remove(o), which removes only
      # the first equal occurrence.
      if index = @items.index { |item| item == value }
        @items.delete_at(index)
        return true
      end
      if value.is_a?(Dictionary)
        # Java COSArray.removeObject: an indirect COSObject entry pointing to the
        # target dict must also be removed.
        index = @items.index do |entry|
          entry.is_a?(Object) && entry.object == value
        end
        if index
          @items.delete_at(index)
          return true
        end
      end
      false
    end

    def remove_all(values : Enumerable(Base)) : Nil
      values.each { |value| @items.delete(value) }
    end

    def retain_all(values : Enumerable(Base)) : Nil
      keep = values.to_set
      @items.select! { |item| keep.includes?(item) }
    end

    # Java COSArray#resetObjectKeys.
    def reset_object_keys(indirect_objects : Set(ObjectKey)) : Set(ObjectKey)
      key = self.key
      if key
        return indirect_objects if indirect_objects.includes?(key)
        indirect_objects.add(key)
        self.key = nil
      end
      @items.each do |raw|
        next unless raw
        indirect_key = raw.is_a?(Object) ? raw.key : nil
        cos_base : Base = raw
        if indirect_key
          next if indirect_objects.includes?(indirect_key)
          # dereference object first, then reset its key
          cos_base = raw.as(Object).object || Null::INSTANCE
          raw.key = nil
        end
        if cos_base.is_a?(Dictionary)
          cos_base.reset_object_keys(indirect_objects)
        elsif cos_base.is_a?(Array)
          cos_base.reset_object_keys(indirect_objects)
        elsif indirect_key
          indirect_objects.add(indirect_key)
        end
      end
      indirect_objects
    end

    def grow_to_size(size : Int, fill_value : Base = Null.instance) : Nil
      return if @items.size >= size
      (size - @items.size).times { @items << fill_value }
    end

    def size : Int32
      @items.size
    end

    def each(& : Base ->) : Nil
      @items.each { |item| yield item }
    end

    def <<(item : Base) : self
      add(item)
    end

    def empty? : Bool
      @items.empty?
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
    PATH_SEPARATOR = "/"

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

    def []?(key : Name) : Base?
      @entries[key]?
    end

    def [](key : ::String) : Base?
      @entries[Name.new(key)]?
    end

    def []?(key : ::String) : Base?
      @entries[Name.new(key)]?
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
      self[key] = String.new(Xmpbox::DateConverter.to_iso8601(value, false))
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

    # Get a string from an embedded dictionary, returning default if not present
    def get_embedded_string(embedded : Name, key : Name, default : ::String? = nil) : ::String?
      embedded_dict = get_dictionary(embedded)
      return default unless embedded_dict
      embedded_dict.get_string(key, default)
    end

    # Get an integer from an embedded dictionary, returning default if not present
    def get_embedded_int(embedded : Name, key : Name, default : Int32 = 0) : Int32
      embedded_dict = get_dictionary(embedded)
      return default unless embedded_dict
      embedded_dict.get_int(key, default.to_i64).to_i
    end

    # Get a date from an embedded dictionary, returning default if not present
    def get_embedded_date(embedded : Name, key : Name, default : Time? = nil) : Time?
      embedded_dict = get_dictionary(embedded)
      return default unless embedded_dict
      embedded_dict.get_date(key, default)
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

    # Get the dictionary object, dereferencing COSObject and treating COSNull as nil
    # Get the dictionary object at the given key, dereferencing indirect
    # references and skipping null. Java COSDictionary#getDictionaryObject.
    def get_dictionary_object(key : Name) : Base?
      value = self[key]?
      return unless value
      if value.is_a?(Object)
        value = value.object
      end
      return if value.is_a?(Null)
      value
    end

    # Get a nested dictionary, returning nil if not present or not a dictionary
    def get_dictionary(key : Name) : Dictionary?
      dict = get_dictionary_object(key)
      dict.as?(Dictionary) if dict
    end

    # The value of the given key if it is a COSArray, otherwise nil.
    # Java COSDictionary#getCOSArray.
    def get_cos_array(key : Name) : Array?
      get_dictionary_object(key).as?(Array)
    end

    # The value of the given key if it is a COSName, otherwise nil.
    # Java COSDictionary#getCOSName.
    def get_cos_name(key : Name) : Name?
      get_dictionary_object(key).as?(Name)
    end

    # The value of the given key if it is a COSStream, otherwise nil.
    # Java COSDictionary#getCOSStream.
    def get_cos_stream(key : Name) : Stream?
      get_dictionary_object(key).as?(Stream)
    end

    # The name of the first entry whose value equals the given value, else nil.
    # Java COSDictionary#getKeyForValue.
    def get_key_for_value(value : Base) : Name?
      @entries.each do |name, base|
        return name if base == value
      end
      nil
    end

    # Iterates over the name/value entries in insertion order.
    # Java COSDictionary#forEach(BiConsumer).
    def each(& : (Name, Base) ->) : Nil
      @entries.each { |name, base| yield name, base }
    end

    # Returns the nested value addressed by an object path, resolving dictionary
    # keys with get_dictionary_object and array indexes (which may be written as
    # "0" or "\[0\]") with get_object. Java COSDictionary#getObjectFromPath.
    def get_object_from_path(obj_path : ::String) : Base?
      path = obj_path.split(PATH_SEPARATOR)
      # Java String.split drops trailing empty strings
      while !path.empty? && path.last.empty?
        path.pop
      end

      result : Base? = self
      path.each do |path_string|
        case current = result
        when Array
          idx = path_string.gsub("\\[", "").gsub("\\]", "").to_i
          item = current.get(idx)
          result = item.is_a?(Object) ? item.object : item
        when Dictionary
          result = current.get_dictionary_object(Name.new(path_string))
        end
      end
      result
    end

    # Get a string value, returning default if not present or not a string
    def get_string(key : Name, default : ::String? = nil) : ::String?
      value = get_dictionary_object(key)
      return default unless value.is_a?(String)
      value.value
    end

    # Get an integer value, returning default if not present or not a number.
    # Accepts both COSInteger and COSFloat, matching Java's instanceof COSNumber check.
    def get_int(key : Name, default : Int64 = 0_i64) : Int64
      value = get_dictionary_object(key)
      case value
      when Integer
        value.value
      when Float
        value.value.to_i64
      else
        default
      end
    end

    # Get a float value, returning default if not present or not a number.
    # Accepts both COSInteger and COSFloat, matching Java's instanceof COSNumber check.
    def get_float(key : Name, default : Float64 = 0.0_f64) : Float64
      value = get_dictionary_object(key)
      case value
      when Float
        value.value
      when Integer
        value.value.to_f64
      else
        default
      end
    end

    # Get an array value, returning nil if not present or not an array
    def get_array(key : Name) : Array?
      value = get_dictionary_object(key)
      value.as?(Array) if value
    end

    # Get a stream value, returning nil if not present or not a stream
    def get_stream(key : Name) : Stream?
      value = get_dictionary_object(key)
      value.as?(Stream) if value
    end

    # Get a name value as a string, returning nil if not present or not a name
    def get_name_as_string(key : Name) : ::String?
      value = get_dictionary_object(key)
      case value
      when Name
        value.value
      when String
        value.value
      else
        nil
      end
    end

    # Get a date value, returning default if not present or not a valid date string
    def get_date(key : Name, default : Time? = nil) : Time?
      value = get_dictionary_object(key)
      return default unless value.is_a?(String)
      Xmpbox::DateConverter.to_calendar(value.value)
    end

    def as_unmodifiable_dictionary : Dictionary
      UnmodifiableDictionary.new(@entries)
    end

    # Reset all object keys to avoid overlapping numbers when saving the new pdf.
    # Java COSDictionary#resetImportedObjectKeys.
    def reset_imported_object_keys : Nil
      reset_object_keys(Set(ObjectKey).new).clear
    end

    # Java COSDictionary#resetObjectKeys.
    def reset_object_keys(indirect_objects : Set(ObjectKey)) : Set(ObjectKey)
      key = self.key
      if key
        return indirect_objects if indirect_objects.includes?(key)
        indirect_objects.add(key)
        self.key = nil
      end
      @entries.each do |entry_key, raw|
        indirect_key = raw.is_a?(Object) ? raw.key : nil
        cos_base : Base? = raw
        if indirect_key
          next if indirect_objects.includes?(indirect_key)
          # dereference object first, then reset its key
          cos_base = raw.as(Object).object
          raw.key = nil
        end
        if cos_base.is_a?(Dictionary)
          # skip PARENT and P references to avoid recursions
          unless entry_key == Name::PARENT || entry_key == Name::P
            cos_base.reset_object_keys(indirect_objects)
          end
        elsif cos_base.is_a?(Array)
          cos_base.reset_object_keys(indirect_objects)
        elsif indirect_key
          indirect_objects.add(indirect_key)
        end
      end
      indirect_objects
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
      return true if other.same?(self)
      return false unless other.class == self.class
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

    def has_data : Bool
      !@data.empty?
    end

    def has_data? : Bool
      has_data
    end

    def create_raw_input_stream : ::IO
      ::IO::Memory.new(@data)
    end

    def create_input_stream : ::IO
      raise ::IO::Error.new("COSStream has no data") unless has_data
      ::IO::Memory.new(decode_filters(@data, self[Name::FILTER]))
    end

    # Gets a stream with some filters applied but not others: decoding stops
    # before the first filter whose name is in stop_filters.
    def create_input_stream(stop_filters : ::Array(::String)) : ::IO
      raise ::IO::Error.new("COSStream has no data") unless has_data
      ::IO::Memory.new(decode_filters_with_stop(@data, self[Name::FILTER], stop_filters))
    end

    # Decodes the stream data as a PDF text string (UTF-16BE/PDFDocEncoding),
    # returning "" when the stream cannot be read. Java COSStream#toTextString.
    def to_text_string : ::String
      Cos::String.new(create_input_stream.gets_to_end.to_slice).value
    rescue
      ""
    end

    def create_raw_output_stream : ::IO
      StreamOutput.new(self, nil, false)
    end

    def create_output_stream(filters : Base? = nil) : ::IO
      StreamOutput.new(self, filters, true)
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
      return false unless other.class == self.class
      super && @data == other.@data
    end

    def ==(other) : Bool
      false
    end

    def_hash @data

    def decode_filters(data : Bytes, filters : Base?) : Bytes
      return data if filters.nil?

      case filters
      when Name
        decode_with_filter(data, filters)
      when Array
        decoded = data
        filters.items.each do |item|
          filter = item.as?(Name) || raise Error.new("Invalid stream filter entry: #{item.inspect}")
          decoded = decode_with_filter(decoded, filter)
        end
        decoded
      else
        raise Error.new("Unsupported stream filter type: #{filters.class}")
      end
    end

    # Like decode_filters, but stops decoding before the first filter whose name
    # appears in stop_filters (Java PDStream#createInputStream(List)).
    def decode_filters_with_stop(data : Bytes, filters : Base?, stop_filters : ::Array(::String)) : Bytes
      return data if filters.nil?

      case filters
      when Name
        stop_filters.includes?(filters.value) ? data : decode_with_filter(data, filters)
      when Array
        decoded = data
        filters.items.each do |item|
          filter = item.as?(Name) || raise Error.new("Invalid stream filter entry: #{item.inspect}")
          break if stop_filters.includes?(filter.value)
          decoded = decode_with_filter(decoded, filter)
        end
        decoded
      else
        raise Error.new("Unsupported stream filter type: #{filters.class}")
      end
    end

    def encode_filters(data : Bytes, filters : Base?) : Bytes
      return data if filters.nil?

      case filters
      when Name
        encode_with_filter(data, filters)
      when Array
        encoded = data
        filters.items.reverse_each do |item|
          filter = item.as?(Name) || raise Error.new("Invalid stream filter entry: #{item.inspect}")
          encoded = encode_with_filter(encoded, filter)
        end
        encoded
      else
        raise Error.new("Unsupported stream filter type: #{filters.class}")
      end
    end

    private def decode_with_filter(data : Bytes, filter : Name) : Bytes
      decode_parms = self[Name.new("DecodeParms")]?
      decode_parms = decode_parms.object if decode_parms.is_a?(Object)
      parms_dict = decode_parms.as?(Dictionary)
      width = get_int(Name.new("Width"), 0).to_i32
      height = get_int(Name.new("Height"), 0).to_i32
      Pdfbox::Filter::FilterFactory::INSTANCE.filter(filter).decode(data, parms_dict, width, height)
    end

    private def encode_with_filter(data : Bytes, filter : Name) : Bytes
      Pdfbox::Filter::FilterFactory::INSTANCE.filter(filter).encode(data)
    end

    private def ascii85_encode(data : Bytes) : Bytes
      encoded = ::String.build do |io|
        index = 0
        while index + 4 <= data.size
          value = (data[index].to_u32 << 24) |
                  (data[index + 1].to_u32 << 16) |
                  (data[index + 2].to_u32 << 8) |
                  data[index + 3].to_u32
          if value == 0
            io << 'z'
          else
            chunk = StaticArray(UInt8, 5).new(0_u8)
            4.downto(0) do |position|
              chunk[position] = (value % 85 + 33).to_u8
              value //= 85
            end
            5.times { |i| io.write_byte(chunk[i]) }
          end
          index += 4
        end

        remaining = data.size - index
        if remaining > 0
          value = 0_u32
          4.times do |offset|
            value <<= 8
            value |= data[index + offset].to_u32 if offset < remaining
          end

          chunk = StaticArray(UInt8, 5).new(0_u8)
          4.downto(0) do |position|
            chunk[position] = (value % 85 + 33).to_u8
            value //= 85
          end
          (remaining + 1).times { |i| io.write_byte(chunk[i]) }
        end

        io << '~' << '>'
      end
      encoded.to_slice
    end

    private def ascii85_decode(data : Bytes) : Bytes
      output = [] of UInt8
      tuple = [] of UInt32
      index = 0

      while index < data.size
        char = data[index].chr
        index += 1

        next if char.whitespace?

        if char == 'z'
          raise Error.new("Invalid ASCII85 'z' inside tuple") unless tuple.empty?
          output.concat([0_u8, 0_u8, 0_u8, 0_u8])
          next
        end

        break if char == '~'

        unless char >= '!' && char <= 'u'
          raise Error.new("Invalid ASCII85 character: #{char.inspect}")
        end

        tuple << (char.ord - 33).to_u32
        next unless tuple.size == 5

        value = 0_u32
        tuple.each { |digit| value = value * 85 + digit }
        output << ((value >> 24) & 0xFF).to_u8
        output << ((value >> 16) & 0xFF).to_u8
        output << ((value >> 8) & 0xFF).to_u8
        output << (value & 0xFF).to_u8
        tuple.clear
      end

      unless tuple.empty?
        tuple_length = tuple.size
        raise Error.new("Invalid ASCII85 tuple length") if tuple_length == 1
        while tuple.size < 5
          tuple << 84_u32
        end
        value = 0_u32
        tuple.each { |digit| value = value * 85 + digit }
        decoded = StaticArray(UInt8, 4).new(0_u8)
        decoded[0] = ((value >> 24) & 0xFF).to_u8
        decoded[1] = ((value >> 16) & 0xFF).to_u8
        decoded[2] = ((value >> 8) & 0xFF).to_u8
        decoded[3] = (value & 0xFF).to_u8
        (tuple_length - 1).times { |i| output << decoded[i] }
      end

      Bytes.new(output.size) { |i| output[i] }
    end

    private class StreamOutput < ::IO
      @buffer : ::IO::Memory
      @buffer = ::IO::Memory.new
      @closed = false

      def initialize(@stream : Stream, @filters : Base?, @encode : Bool)
      end

      def read(slice : Bytes) : Int32
        raise ::IO::Error.new("Not readable")
      end

      def write(slice : Bytes) : Nil
        raise ::IO::Error.new("Closed stream") if @closed
        @buffer.write(slice)
      end

      def flush : Nil
      end

      def close : Nil
        return if @closed
        @closed = true

        raw = @buffer.to_slice
        data = @encode ? @stream.encode_filters(raw, @filters) : raw
        @stream.data = data
        @stream.set_int(Name::LENGTH, data.size)

        if @encode
          if filters = @filters
            @stream.set_item(Name::FILTER, filters)
          else
            @stream.remove_item(Name::FILTER)
          end
        end
      end

      def closed? : Bool
        @closed
      end
    end
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
    @streams = [] of Stream
    @version = 0.0_f32
    @start_xref = 0_i64
    @is_xref_stream = false
    @has_hybrid_xref = false
    @is_decrypted = false
    @highest_xref_object_number = 0_i64
    @trailer : Dictionary? = nil
    @stream_cache : Pdfbox::IO::RandomAccessStreamCache = Pdfbox::IO::RandomAccessStreamCacheImpl.new
    @closed = false

    def write_pdf(io : ::IO) : Nil
      io << "%COSDocument"
    end

    # The header version. Java COSDocument#getVersion / #setVersion.
    def version : Float32
      @version
    end

    def version=(value : Float32) : Float32
      @version = value
    end

    # The startxref position. Java getStartXref / setStartXref.
    def start_xref : Int64
      @start_xref
    end

    def start_xref=(value : Int64) : Int64
      @start_xref = value
    end

    # Whether the trailer is an xref stream. Java isXRefStream / setIsXRefStream.
    def is_xref_stream? : Bool # ameba:disable Naming/PredicateName
      @is_xref_stream
    end

    def is_xref_stream=(value : Bool) : Bool
      @is_xref_stream = value
    end

    # Whether the document has hybrid cross references. Java hasHybridXRef.
    def has_hybrid_xref? : Bool
      @has_hybrid_xref
    end

    def has_hybrid_xref=(value : Bool) : Bool
      @has_hybrid_xref = value
    end

    # Whether an encrypted document has already been decrypted. Java isDecrypted.
    def decrypted? : Bool
      @is_decrypted
    end

    # Signals that the document is decrypted completely. Java setDecrypted().
    def set_decrypted : Nil
      @is_decrypted = true
    end

    # The trailer dictionary. Java getTrailer / setTrailer.
    def trailer : Dictionary?
      @trailer
    end

    def trailer=(new_trailer : Dictionary) : Dictionary
      @trailer = new_trailer
    end

    # Whether the document is encrypted (the trailer has an /Encrypt entry).
    def encrypted? : Bool
      current = @trailer
      !current.nil? && !current.get_dictionary_object(Name::ENCRYPT).nil?
    end

    # The encryption dictionary from the trailer. Java getEncryptionDictionary.
    def encryption_dictionary : Dictionary?
      @trailer.try(&.get_dictionary(Name::ENCRYPT))
    end

    # Sets the encryption dictionary on the trailer. Java setEncryptionDictionary.
    def encryption_dictionary=(enc_dictionary : Dictionary?) : Dictionary?
      current = (@trailer ||= Dictionary.new)
      if enc_dictionary
        current.set_item(Name::ENCRYPT, enc_dictionary)
      else
        current.remove_item(Name::ENCRYPT)
      end
      enc_dictionary
    end

    # The document id (trailer /ID). Java getDocumentID / setDocumentID.
    def document_id : Array?
      @trailer.try(&.get_dictionary_object(Name::ID)).as?(Array)
    end

    def document_id=(id : Array) : Array
      current = (@trailer ||= Dictionary.new)
      current.set_item(Name::ID, id)
      id
    end

    # The object number of the highest XRef stream. Java getHighestXRefObjectNumber.
    def highest_xref_object_number : Int64
      @highest_xref_object_number
    end

    def highest_xref_object_number=(value : Int64) : Int64
      @highest_xref_object_number = value
    end

    # Returns a pooled object, creating a proxy if it has not been parsed yet.
    # Java COSDocument#getObjectFromPool.
    def object_from_pool(key : ObjectKey?) : Object?
      return unless key

      existing = @object_pool[key]?
      return existing if existing

      proxy = Object.new(key.number, key.generation)
      @object_pool[key] = proxy
      proxy
    end

    # The xrefTable mapping ObjectKeys to byte offsets. Java getXrefTable.
    def xref_table : ::Hash(ObjectKey?, Int64)
      @xref_table
    end

    # The stream cache backing this document. Java getStreamCache / setStreamCache.
    def stream_cache : Pdfbox::IO::RandomAccessStreamCache
      @stream_cache
    end

    def stream_cache=(cache : Pdfbox::IO::RandomAccessStreamCache) : Pdfbox::IO::RandomAccessStreamCache
      @stream_cache = cache
    end

    # Whether the document has been closed. Java isClosed.
    def closed? : Bool
      @closed
    end

    # Closes the document and its stream cache. Java COSDocument#close.
    def close : Nil
      return if @closed

      @closed = true
      @stream_cache.close
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

    def create_cos_stream : Stream
      stream = Stream.new
      @streams << stream
      stream
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

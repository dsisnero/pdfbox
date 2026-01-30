# COS (Cos Object System) module for PDFBox Crystal
#
# This module contains the fundamental object types used in PDF documents,
# corresponding to the COS (Cos Object System) in Apache PDFBox.
module Pdfbox::Cos
  # Error class for COS operations
  class Error < Pdfbox::PDFError; end

  # Base class for all COS objects
  abstract class Base
    @direct : Bool = true
    @key : ObjectKey?

    # Write this object in PDF format to the given IO
    abstract def write_pdf(io : ::IO) : Nil

    # If the state is set true, the dictionary will be written direct into the called object.
    # This means, no indirect object will be created.
    def direct? : Bool
      @direct
    end

    # Set the state true, if the dictionary should be written as a direct object and not indirect.
    # ameba:disable Naming/AccessorMethodName
    def set_direct(direct : Bool) : Nil
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
  end

  # Marker module for numeric types (Integer and Float)
  module Number
  end

  # Integer value in PDF document
  class Integer < Base
    include Number
    @value : Int64

    def initialize(@value : Int64)
    end

    def value : Int64
      @value
    end

    def value_as_object : Int64
      @value
    end

    # Check if integer is within valid PDF range (signed 32-bit)
    def valid? : Bool
      @value >= Int32::MIN.to_i64 && @value <= Int32::MAX.to_i64
    end

    # Write this integer in PDF format to the given IO
    def write_pdf(io : ::IO) : Nil
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

  # String value in PDF document
  class String < Base
    @bytes : Bytes
    @force_hex_form : Bool

    # Creates a new PDF string from a String (text string)
    def initialize(string : ::String, @force_hex_form : Bool = false)
      @bytes = string.to_slice
    end

    # Creates a new PDF string from raw bytes
    def initialize(@bytes : Bytes, @force_hex_form : Bool = false)
    end

    # Gets the string value (decoded as UTF-8)
    def value : ::String
      ::String.new(@bytes)
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
      Pdfbox::Pdfwriter::PDFIO.write_string(io, ::String.new(@bytes), @force_hex_form)
    end

    # Equality comparison
    def ==(other : self) : Bool
      return false unless @force_hex_form == other.@force_hex_form
      @bytes == other.@bytes
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

    def initialize(items : Enumerable(Base) = [] of Base)
      @items = items.to_a
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

    def []=(index : Int, value : Base) : Base
      @items[index] = value
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

    def [](key : Name) : Base?
      @entries[key]?
    end

    def has_key?(key : Name) : Bool
      @entries.has_key?(key)
    end

    def delete(key : Name) : Base?
      @entries.delete(key)
    end

    def size : Int32
      @entries.size
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
end

require "string_scanner"

# PDF Parser module for PDFBox Crystal
#
# This module contains PDF parsing functionality,
# corresponding to the pdfparser package in Apache PDFBox.
module Pdfbox::Pdfparser
  # Base class for PDF parsing errors
  class ParseError < Pdfbox::PDFError; end

  # Raised when PDF syntax is invalid
  class SyntaxError < ParseError; end

  # Raised when PDF is encrypted and password is required
  class EncryptedPDFError < ParseError; end

  # Raised when PDF version is not supported
  class UnsupportedVersionError < ParseError; end

  # Main PDF parser class
  class Parser
    @source : Pdfbox::IO::RandomAccessRead

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      @source = source
    end

    # Parse PDF header and return version string (e.g., "1.4")
    def parse_header : String
      # Read first line (up to newline)
      line = read_line
      unless line.starts_with?("%PDF-")
        raise SyntaxError.new("Invalid PDF header: #{line.inspect}")
      end
      # Extract version: %PDF-1.4
      version = line[5..]
      # Optional: read binary comment line (second line starting with %)
      # Check if next byte is '%' (binary comment)
      if @source.peek == '%'.ord
        read_line # skip binary comment line
      end
      version
    end

    private def read_line : String
      builder = String::Builder.new
      while byte = @source.read
        ch = byte.chr
        break if ch == '\n'
        builder << ch
      end
      builder.to_s
    end

    # Parse the PDF document
    def parse : Pdfbox::Pdmodel::Document
      # TODO: Implement PDF parsing
      Pdfbox::Pdmodel::Document.new
    end

    # Parse with password for encrypted PDFs
    def parse(password : String) : Pdfbox::Pdmodel::Document
      # TODO: Implement encrypted PDF parsing
      Pdfbox::Pdmodel::Document.new
    end

    # Check if PDF is encrypted
    def encrypted? : Bool
      # TODO: Implement encryption detection
      false
    end

    # Get PDF version
    def version : String
      # TODO: Implement version detection
      "1.4"
    end

    # Get document information dictionary
    def document_information : Pdfbox::Cos::Dictionary?
      # TODO: Implement document info retrieval
      nil
    end

    # Get document catalog
    def catalog : Pdfbox::Cos::Dictionary?
      # TODO: Implement catalog retrieval
      nil
    end

    # Get cross-reference table
    def xref : XRef?
      # TODO: Implement xref retrieval
      nil
    end

    # Get trailer dictionary
    def trailer : Pdfbox::Cos::Dictionary?
      # TODO: Implement trailer retrieval
      nil
    end
  end

  # Cross-reference table entry
  class XRefEntry
    @offset : Int64
    @generation : Int64
    @type : Symbol

    def initialize(@offset : Int64, @generation : Int64, @type : Symbol)
    end

    def offset : Int64
      @offset
    end

    def generation : Int64
      @generation
    end

    def type : Symbol
      @type
    end

    def free? : Bool
      @type == :free
    end

    def in_use? : Bool
      @type == :in_use
    end
  end

  # Cross-reference table
  class XRef
    @entries = {} of Int64 => XRefEntry

    def initialize(@entries : Hash(Int64, XRefEntry) = {} of Int64 => XRefEntry)
    end

    def entries : Hash(Int64, XRefEntry)
      @entries
    end

    def [](object_number : Int64) : XRefEntry?
      @entries[object_number]?
    end

    def []=(object_number : Int64, entry : XRefEntry) : XRefEntry
      @entries[object_number] = entry
    end

    def size : Int32
      @entries.size
    end
  end

  # PDF object parser for individual COS objects
  class ObjectParser
    @scanner : PDFScanner

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      @scanner = PDFScanner.new(source)
    end

    # Parse a COS object from the stream
    def parse_object : Pdfbox::Cos::Base?
      @scanner.skip_whitespace

      case @scanner.peek
      when '/'
        parse_name
      when '('
        parse_string
      when '<'
        # Could be string (<...>) or dictionary (<<...>>)
        if @scanner.rest.starts_with?("<<")
          parse_dictionary
        else
          parse_string
        end
      when '['
        parse_array
      when '>'
        # Could be end of dictionary or malformed
        nil
      when '0'..'9', '+', '-', '.'
        parse_number
      when 't', 'f'
        parse_boolean
      when 'n'
        parse_null
      else
        nil
      end
    end

    # Parse a COS dictionary
    def parse_dictionary : Pdfbox::Cos::Dictionary?
      @scanner.skip_whitespace

      # Dictionary starts with '<<'
      unless @scanner.rest.starts_with?("<<")
        return
      end

      @scanner.scanner.scan("<<") rescue nil
      dict = Pdfbox::Cos::Dictionary.new

      loop do
        @scanner.skip_whitespace
        break if @scanner.rest.starts_with?(">>")

        # Parse key (must be a name)
        key = parse_name
        break unless key

        # Parse value
        value = parse_object
        break unless value

        dict[key.value] = value
      end

      @scanner.scanner.scan(">>") rescue nil
      dict
    end

    # Parse a COS array
    def parse_array : Pdfbox::Cos::Array?
      @scanner.skip_whitespace

      # Array starts with '['
      unless @scanner.scanner.scan('[')
        return
      end

      array = Pdfbox::Cos::Array.new

      loop do
        @scanner.skip_whitespace
        break if @scanner.scanner.check(']')

        value = parse_object
        break unless value

        array << value

        @scanner.skip_whitespace
        break if @scanner.scanner.check(']')

        # Arrays can have spaces between elements
      end

      @scanner.scanner.scan(']') rescue nil
      array
    end

    # Parse a COS string
    def parse_string : Pdfbox::Cos::String?
      @scanner.skip_whitespace

      string = @scanner.read_string rescue nil
      return unless string

      Pdfbox::Cos::String.new(string)
    end

    # Parse a COS name
    def parse_name : Pdfbox::Cos::Name?
      @scanner.skip_whitespace

      name = @scanner.read_name rescue nil
      return unless name

      Pdfbox::Cos::Name.new(name)
    end

    # Parse a COS number (integer or float)
    def parse_number : Pdfbox::Cos::Base?
      @scanner.skip_whitespace

      number = @scanner.read_number rescue nil
      return unless number

      case number
      when Int64
        Pdfbox::Cos::Integer.new(number)
      when Float64
        Pdfbox::Cos::Float.new(number)
      else
        nil
      end
    end

    # Parse a COS boolean
    def parse_boolean : Pdfbox::Cos::Boolean?
      @scanner.skip_whitespace

      if @scanner.scanner.scan("true")
        Pdfbox::Cos::Boolean::TRUE
      elsif @scanner.scanner.scan("false")
        Pdfbox::Cos::Boolean::FALSE
      end
    end

    # Parse a COS null
    def parse_null : Pdfbox::Cos::Null?
      @scanner.skip_whitespace

      if @scanner.scanner.scan("null")
        Pdfbox::Cos::Null.instance
      end
    end

    # Get underlying scanner
    def scanner : PDFScanner
      @scanner
    end
  end

  # PDF scanner using StringScanner for parsing PDF tokens
  class PDFScanner
    @scanner : StringScanner
    @source : Pdfbox::IO::RandomAccessRead
    @buffer_pos : Int64 = 0

    getter scanner : StringScanner

    def initialize(@source : Pdfbox::IO::RandomAccessRead)
      # Read remaining data as string for scanning
      @scanner = StringScanner.new(read_remaining_as_string)
    end

    # Read remaining data from source as ASCII string
    private def read_remaining_as_string : String
      data = Bytes.new(@source.length - @source.position)
      @source.read(data)
      @buffer_pos = @source.position - data.size
      String.new(data)
    end

    # Get current absolute position in source
    def position : Int64
      @buffer_pos + @scanner.offset
    end

    # Set absolute position in source
    def position=(pos : Int64)
      if pos >= @buffer_pos && pos < @buffer_pos + @scanner.string.bytesize
        @scanner.offset = (pos - @buffer_pos).to_i32
      else
        # Need to reload buffer from new position
        @source.seek(pos)
        @scanner = StringScanner.new(read_remaining_as_string)
      end
    end

    # Skip whitespace and comments
    def skip_whitespace : Nil
      loop do
        @scanner.skip(/\s+/)
        if @scanner.check('%')
          @scanner.skip_until(/\r?\n/)
        else
          break
        end
      end
    end

    # Peek next non-whitespace character
    def peek : Char?
      skip_whitespace
      @scanner.peek(1).try(&.chars.first?)
    end

    # Read a PDF number
    def read_number : Float64 | Int64
      skip_whitespace

      # Match optional sign, digits, optional decimal point
      if match = @scanner.scan(/[+-]?\d+(?:\.\d+)?/)
        if match.includes?('.')
          match.to_f64
        else
          match.to_i64
        end
      else
        raise SyntaxError.new("Expected number at position #{position}")
      end
    end

    # Read a PDF name
    def read_name : String
      skip_whitespace

      # Names start with '/'
      unless @scanner.scan('/')
        raise SyntaxError.new("Expected name starting with '/' at position #{position}")
      end

      # Read name characters
      # PDF name grammar: /[^#0-9\s()<>\[\]{}/%]*[#0-9]*
      # Actually names can contain any characters except delimiters
      # We'll read until whitespace or delimiter
      buffer = String::Builder.new

      loop do
        char = @scanner.peek(1)
        break unless char
        break if char =~ /\s|\(|\)|<|>|\[|\]|\{|\}|\/|%/

        buffer << @scanner.scan(/./)
      end

      buffer.to_s
    end

    # Read a PDF string (literal or hexadecimal)
    def read_string : String
      skip_whitespace

      # Check for literal string '(' or hexadecimal string '<'
      case @scanner.peek(1)
      when "("
        read_literal_string
      when "<"
        read_hexadecimal_string
      else
        raise SyntaxError.new("Expected string at position #{position}")
      end
    end

    # Check if we've reached end of string based on lookahead
    private def check_for_end_of_string(braces : Int32) : Int32
      return 0 if braces == 0

      # Peek next 3 bytes
      peeked = @scanner.peek(3)
      return braces if peeked.empty?

      bytes = peeked.bytes
      # Check patterns:
      # 1. CR or LF followed by '/' or '>'
      # 2. CR followed by LF followed by '/' or '>'
      if bytes.size >= 2 && (bytes[0] == '\r'.ord || bytes[0] == '\n'.ord) && (bytes[1] == '/'.ord || bytes[1] == '>'.ord)
        return 0
      elsif bytes.size >= 3 && bytes[0] == '\r'.ord && bytes[1] == '\n'.ord && (bytes[2] == '/'.ord || bytes[2] == '>'.ord)
        return 0
      end

      braces
    end

    # Read literal string (parentheses)
    def read_literal_string : String
      @scanner.scan('(') || raise SyntaxError.new("Expected '(' for literal string")

      buffer = String::Builder.new
      braces = 1

      while braces > 0
        char = @scanner.scan(/./)
        break unless char

        case char
        when "("
          braces += 1
          buffer << char
        when ")"
          braces -= 1
          braces = check_for_end_of_string(braces)
          buffer << char unless braces == 0
        when '\\'
          # Escape sequence
          esc_str = @scanner.scan(/./)
          if esc_str.nil?
            # Invalid escape, treat as literal backslash?
            buffer << '\\'
            next
          end
          str = esc_str.as(String)
          esc_char = str[0]

          case esc_char
          when 'n'
            buffer << '\n'
          when 'r'
            buffer << '\r'
          when 't'
            buffer << '\t'
          when 'b'
            buffer << '\b'
          when 'f'
            buffer << '\f'
          when '(', ')', '\\'
            buffer << str
          when '\n', '\r'
            # Line continuation - skip
            @scanner.skip(/\s*/)
          when '0'..'7'
            # Octal sequence
            digits = String.build do |dig|
              dig << str
              2.times do
                next_char = @scanner.check(/[0-7]/)
                break unless next_char
                scanned = @scanner.scan(/./).as(String)
                dig << scanned
              end
            end
            buffer << digits.to_i(8).chr
          else
            buffer << str
          end
        else
          buffer << char
        end
      end

      buffer.to_s
    end

    # Read hexadecimal string <...>
    private def read_hexadecimal_string : String
      @scanner.scan('<') || raise SyntaxError.new("Expected '<' for hexadecimal string")

      buffer = String::Builder.new
      hex_chars = ""

      loop do
        @scanner.skip(/\s*/)
        char = @scanner.peek(1)
        break unless char

        if char == ">"
          @scanner.scan('>')
          break
        elsif char =~ /[0-9A-Fa-f]/
          hex_chars << @scanner.scan(/./)
          if hex_chars.size == 2
            buffer << hex_chars.to_i(16).chr
            hex_chars.clear
          end
        else
          # Invalid hex character
          @scanner.scan(/./)
        end
      end

      # Handle leftover single hex digit
      if hex_chars.size == 1
        buffer << (hex_chars + "0").to_i(16).chr
      end

      buffer.to_s
    end

    # Read PDF date string
    def read_date : Time?
      skip_whitespace

      # PDF dates start with "D:"
      unless @scanner.scan("D:")
        return
      end

      # Parse date format: YYYYMMDDHHmmSSOHH'mm'
      date_str = @scanner.scan(/\d{14}/)
      return unless date_str

      # TODO: Parse timezone offset
      # For now, return current time
      Time.utc
    end

    # Check if at end of stream
    def eos? : Bool
      @scanner.eos?
    end

    # Get remaining string
    def rest : String
      @scanner.rest
    end
  end

  # Utility for reading PDF-specific data types
  module PDFIO
    # Read a PDF string (literal or hexadecimal)
    def self.read_string(io : ::IO) : String
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.read_string
      else
        # Fallback for generic IO
        # TODO: Implement basic string reading
        ""
      end
    end

    # Read a PDF name
    def self.read_name(io : ::IO) : String
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.read_name
      else
        # Fallback for generic IO
        ""
      end
    end

    # Read a PDF number
    def self.read_number(io : ::IO) : Float64 | Int64
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.read_number
      else
        # Fallback for generic IO
        skip_whitespace(io)
        buffer = String::Builder.new

        # Optional sign
        char = io.read_char rescue nil
        if char == '+' || char == '-'
          buffer << char
          char = io.read_char rescue nil
        end

        # Read digits before decimal point
        while char && char.ascii_number?
          buffer << char
          char = io.read_char rescue nil
        end

        # Check for decimal point
        if char == '.'
          buffer << char
          char = io.read_char rescue nil

          # Read digits after decimal point
          while char && char.ascii_number?
            buffer << char
            char = io.read_char rescue nil
          end
        end

        # Put back the last character if not whitespace
        if char && !char.ascii_whitespace? && char != '%' && io.responds_to?(:seek)
          io.seek(-1, IO::Seek::Current)
        end

        str = buffer.to_s
        if str.includes?('.')
          str.to_f64
        else
          str.to_i64
        end
      end
    end

    # Skip whitespace and comments
    def self.skip_whitespace(io : ::IO) : Nil
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.skip_whitespace
      else
        # Fallback for generic IO
        loop do
          char = io.read_char rescue nil
          break unless char

          case char
          when ' ', '\t', '\n', '\r', '\f'
            # Skip whitespace
            next
          when '%'
            # Skip comment until end of line
            loop do
              next_char = io.read_char rescue nil
              break unless next_char
              break if next_char == '\n' || next_char == '\r'
            end
          else
            # Not whitespace or comment - put back the character
            io.seek(-1, IO::Seek::Current) if io.responds_to?(:seek)
            break
          end
        end
      end
    end

    # Peek next non-whitespace character
    def self.peek(io : ::IO) : Char?
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.peek
      else
        # Fallback for generic IO
        skip_whitespace(io)
        pos = io.pos rescue nil
        return unless pos

        char = io.read_char rescue nil
        if char && io.responds_to?(:seek)
          io.seek(pos, IO::Seek::Set)
        end
        char
      end
    end

    # Read PDF date string
    def self.read_date(io : ::IO) : Time?
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.read_date
      end
    end
  end

  # Parser for COS objects
  class COSParser
    @scanner : PDFScanner

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      @scanner = PDFScanner.new(source)
    end

    # Parse a COS literal string from the input
    def parse_cos_literal_string : Pdfbox::Cos::String
      Pdfbox::Cos::String.new(@scanner.read_literal_string)
    end
  end
end

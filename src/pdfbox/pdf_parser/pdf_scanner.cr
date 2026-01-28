require "string_scanner"

module Pdfbox::Pdfparser
  # PDF scanner using StringScanner for parsing PDF tokens
  class PDFScanner
    @scanner : StringScanner
    @source : Pdfbox::IO::RandomAccessRead
    @buffer_pos : Int64 = 0
    @raw_buffer : Bytes = Bytes.empty

    getter scanner : StringScanner
    getter buffer_pos : Int64
    getter raw_buffer : Bytes

    def initialize(@source : Pdfbox::IO::RandomAccessRead)
      # Read remaining data as string for scanning
      @scanner = StringScanner.new(read_remaining_as_string)
    end

    # Read remaining data from source as ASCII string
    private def read_remaining_as_string : String
      bytes_to_read = @source.length - @source.position
      # puts "PDFScanner DEBUG: source.length=#{@source.length}, source.position=#{@source.position}, bytes_to_read=#{bytes_to_read}"
      Log.debug { "PDFScanner.read_remaining_as_string: source.length=#{@source.length}, source.position=#{@source.position}, bytes_to_read=#{bytes_to_read}" }
      @raw_buffer = Bytes.new(bytes_to_read)
      @source.read(@raw_buffer)
      @buffer_pos = @source.position - @raw_buffer.size
      # puts "PDFScanner DEBUG: read #{@raw_buffer.size} bytes, buffer_pos=#{@buffer_pos}"
      Log.debug { "PDFScanner.read_remaining_as_string: read #{@raw_buffer.size} bytes, buffer_pos=#{@buffer_pos}" }
      String.new(@raw_buffer, "ISO-8859-1")
    end

    # Get current absolute position in source
    def position : Int64
      @buffer_pos + @scanner.offset
    end

    # Read raw bytes from buffer at current position
    def read_raw_bytes(length : Int64) : Bytes
      offset_in_buffer = @scanner.offset
      if offset_in_buffer + length > @raw_buffer.size
        raise SyntaxError.new("Requested #{length} bytes at offset #{offset_in_buffer} but buffer only has #{@raw_buffer.size} bytes")
      end

      # Get slice of raw buffer
      slice = @raw_buffer[offset_in_buffer, length]

      # Advance scanner position
      @scanner.offset = (offset_in_buffer + length).to_i32

      slice
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
      max_iterations = 1000
      iteration = 0
      loop do
        iteration += 1
        if iteration > max_iterations
          # puts "PDFScanner WARNING: skip_whitespace stuck in infinite loop at offset #{@scanner.offset}, string size #{@scanner.string.bytesize}"
          break
        end

        @scanner.skip(/\s+/)
        if @scanner.check('%')
          # Skip comment to end of line
          if @scanner.skip_until(/\r?\n/).nil?
            # No newline found, skip to end of string
            @scanner.offset = @scanner.string.bytesize
            break
          end
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
      check_end_of_string_pattern ? 0 : braces
    end

    private def check_end_of_string_pattern : Bool
      # Peek next 3 bytes
      peeked = @scanner.peek(3)
      return false if peeked.empty?

      bytes = peeked.to_slice
      # Check patterns:
      # 1. CR or LF followed by '/' or '>'
      # 2. CR followed by LF followed by '/' or '>'
      check_pattern_1(bytes) || check_pattern_2(bytes)
    end

    private def check_pattern_1(bytes : Bytes) : Bool
      bytes.size >= 2 && (bytes[0] == '\r'.ord || bytes[0] == '\n'.ord) && (bytes[1] == '/'.ord || bytes[1] == '>'.ord)
    end

    private def check_pattern_2(bytes : Bytes) : Bool
      bytes.size >= 3 && bytes[0] == '\r'.ord && bytes[1] == '\n'.ord && (bytes[2] == '/'.ord || bytes[2] == '>'.ord)
    end

    # Read literal string (parentheses)
    def read_literal_string : String
      @scanner.scan('(') || raise SyntaxError.new("Expected '(' for literal string")

      buffer = String::Builder.new
      braces = 1

      while braces > 0
        char = @scanner.scan(/./)
        break unless char

        braces = process_literal_char(char, braces, buffer)
      end

      buffer.to_s
    end

    private def process_literal_char(char : String, braces : Int32, buffer : String::Builder) : Int32
      case char
      when "("
        braces += 1
        buffer << char
      when ")"
        braces -= 1
        braces = check_for_end_of_string(braces)
        buffer << char unless braces == 0
      when '\\'
        handle_escape_sequence(buffer)
      else
        buffer << char
      end
      braces
    end

    private def handle_escape_sequence(buffer : String::Builder) : Nil
      esc_str = @scanner.scan(/./)
      if esc_str.nil?
        # Invalid escape, treat as literal backslash?
        buffer << '\\'
        return
      end

      str = esc_str.as(String)
      esc_char = str[0]
      handle_escape_char(esc_char, str, buffer)
    end

    private def handle_escape_char(esc_char : Char, str : String, buffer : String::Builder) : Nil
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
        handle_octal_sequence(str, buffer)
      else
        buffer << str
      end
    end

    private def handle_octal_sequence(str : String, buffer : String::Builder) : Nil
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
          if scanned = @scanner.scan(/./)
            hex_chars += scanned
          end
          if hex_chars.size == 2
            buffer << hex_chars.to_i(16).chr
            hex_chars = ""
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
end

module Pdfbox::Pdfparser
  # Base parser module providing low-level parsing methods on RandomAccessRead
  # Similar to Apache PDFBox BaseParser
  module BaseParser
    macro included
      @source : Pdfbox::IO::RandomAccessRead
      @recursion_depth : Int32 = 0
      MAX_RECURSION_DEPTH = 1000
    end

    def initialize_base_parser(@source : Pdfbox::IO::RandomAccessRead)
    end

    # Check if character is whitespace (space, tab, CR, LF, FF)
    def space?(c : Int32) : Bool
      c == 32 || c == 9 || c == 10 || c == 12 || c == 13 || c == 0
    end

    # Check if character is end of line (CR or LF)
    def eol?(c : Int32) : Bool
      c == 10 || c == 13
    end

    # Check if character is digit
    def digit?(c : Int32) : Bool
      '0'.ord <= c <= '9'.ord
    end

    # Skip whitespace and comments
    def skip_spaces : Nil
      loop do
        c = @source.peek
        break unless c

        if c == '%'.ord
          # Skip comment until end of line
          while c = @source.read
            break if eol?(c)
          end
        elsif space?(c)
          @source.read # consume whitespace
        else
          break
        end
      end
    end

    # Read next character without consuming it
    def peek_char : Char?
      c = @source.peek
      c ? c.chr : nil
    end

    # Read next character and consume it
    def read_char : Char?
      c = @source.read
      c ? c.chr : nil
    end

    # Read a string until whitespace or delimiter
    def read_string : String
      skip_spaces
      buffer = String::Builder.new

      loop do
        c = @source.peek
        break unless c
        break if space?(c.not_nil!.to_i32) || delimiter?(c.not_nil!.chr)

        byte = c.not_nil!
        @source.read # consume
        buffer.write_byte(byte.to_u8)
      end

      buffer.to_s
    end

    # Check if character is a delimiter
    private def delimiter?(c : Char) : Bool
      case c
      when '(', ')', '<', '>', '[', ']', '{', '}', '/', '%'
        true
      else
        false
      end
    end

    # Read a PDF number (integer or float)
    def read_number : Float64 | Int64
      skip_spaces

      buffer = String::Builder.new
      c = @source.peek
      return 0_i64 unless c

      # Optional sign
      if c.not_nil!.chr == '+' || c.not_nil!.chr == '-'
        buffer.write_byte(c.not_nil!)
        @source.read # consume
        c = @source.peek
      end

      # Digits before decimal
      while c && digit?(c)
        buffer.write_byte(c.not_nil!)
        @source.read # consume
        c = @source.peek
      end

      # Optional decimal point and digits
      if c && c.not_nil!.chr == '.'
        buffer.write_byte(c.not_nil!)
        @source.read # consume
        c = @source.peek

        while c && digit?(c)
          buffer.write_byte(c.not_nil!)
          @source.read # consume
          c = @source.peek
        end
      end

      str = buffer.to_s
      if str.includes?('.')
        str.to_f64
      else
        str.to_i64
      end
    end

    # Read a PDF name
    def read_name : String
      skip_spaces

      # Names start with '/'
      c = @source.read
      unless c && c.chr == '/'
        raise SyntaxError.new("Expected '/' for name")
      end

      buffer = String::Builder.new
      loop do
        c = @source.peek
        break unless c

        ch = c.not_nil!.chr
        # Names can contain any characters except delimiters and whitespace
        break if space?(c.not_nil!.to_i32) || delimiter?(ch)

        buffer.write_byte(c.not_nil!)
        @source.read # consume
      end

      buffer.to_s
    end

    # Read a PDF literal string
    def read_literal_string : String
      skip_spaces

      c = @source.read
      unless c && c.chr == '('
        raise SyntaxError.new("Expected '(' for literal string")
      end

      buffer = String::Builder.new
      braces = 1

      while braces > 0
        c = @source.read
        break unless c

        ch = c.chr
        case ch
        when '('
          braces += 1
          buffer << ch
        when ')'
          braces -= 1
          braces = check_for_end_of_string(braces)
          buffer << ch unless braces == 0
        when '\\'
          handle_escape_sequence(buffer)
        else
          buffer << ch
        end
      end

      buffer.to_s
    end

    # Check if we've reached end of string based on lookahead
    private def check_for_end_of_string(braces : Int32) : Int32
      return 0 if braces == 0

      # Save position
      saved_pos = @source.position

      # Peek next bytes
      bytes = [] of UInt8
      3.times do
        c = @source.read
        break unless c
        bytes << c
      end

      # Restore position
      @source.seek(saved_pos)

      # Check patterns:
      # 1. CR or LF followed by '/' or '>'
      # 2. CR followed by LF followed by '/' or '>'
      if bytes.size >= 2
        if (bytes[0] == '\r'.ord || bytes[0] == '\n'.ord) && (bytes[1] == '/'.ord || bytes[1] == '>'.ord)
          return 0
        end
      end

      if bytes.size >= 3
        if bytes[0] == '\r'.ord && bytes[1] == '\n'.ord && (bytes[2] == '/'.ord || bytes[2] == '>'.ord)
          return 0
        end
      end

      braces
    end

    private def handle_escape_sequence(buffer : String::Builder) : Nil
      c = @source.read
      return unless c

      case c.chr
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
        buffer.write_byte(c.to_u8)
      when '\n', '\r'
        # Line continuation - skip
        skip_spaces
      when '0'..'7'
        # Octal sequence
        handle_octal_sequence(c.chr, buffer)
      else
        buffer.write_byte(c.to_u8)
      end
    end

    private def handle_octal_sequence(first_digit : Char, buffer : String::Builder) : Nil
      digits = String::Builder.new
      digits << first_digit

      2.times do
        c = @source.peek
        break unless c && '0' <= c.not_nil!.chr <= '7'
        digits.write_byte(c.not_nil!)
        @source.read # consume
      end

      buffer << digits.to_s.to_i(8).chr
    end

    # Read a PDF hexadecimal string
    def read_hexadecimal_string : String
      skip_spaces

      c = @source.read
      unless c && c.chr == '<'
        raise SyntaxError.new("Expected '<' for hexadecimal string")
      end

      buffer = String::Builder.new
      hex_chars = ""

      loop do
        skip_spaces
        c = @source.peek
        break unless c

        if c.not_nil!.chr == '>'
          @source.read # consume '>'
          break
        elsif c.not_nil!.chr =~ /[0-9A-Fa-f]/
          hex_chars += c.not_nil!.chr
          @source.read # consume
          if hex_chars.size == 2
            buffer << hex_chars.to_i(16).chr
            hex_chars = ""
          end
        else
          @source.read # skip invalid character
        end
      end

      # Handle leftover single hex digit
      if hex_chars.size == 1
        buffer << (hex_chars + "0").to_i(16).chr
      end

      buffer.to_s
    end

    # Read expected string
    def read_expected_string(expected : String, case_sensitive : Bool = true) : Nil
      expected.each_char do |char|
        c = @source.read
        unless c && (case_sensitive ? c.chr == char : c.chr.downcase == char.downcase)
          raise SyntaxError.new("Expected '#{expected}'")
        end
      end
    end

    # Read expected character
    def read_expected_char(expected : Char) : Nil
      c = @source.read
      unless c && c.chr == expected
        raise SyntaxError.new("Expected '#{expected}'")
      end
    end

    # Get current position
    def position : Int64
      @source.position
    end

    # Seek to position
    def seek(position : Int64) : Nil
      @source.seek(position)
    end
  end
end

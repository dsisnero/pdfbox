require "../io"

module Pdfbox::Pdfparser
  # This class is used to contain parsing logic that will be used by all parsers.
  # Similar to Apache PDFBox BaseParser
  abstract class BaseParser
    MAX_LENGTH_LONG = Long::MAX.to_s.size

    # ASCII code for Null.
    ASCII_NULL = 0_u8
    # ASCII code for horizontal tab.
    ASCII_TAB = 9_u8
    # ASCII code for line feed.
    ASCII_LF = 10_u8
    # ASCII code for form feed.
    ASCII_FF = 12_u8
    # ASCII code for carriage return.
    ASCII_CR    = 13_u8
    ASCII_ZERO  = 48_u8
    ASCII_NINE  = 57_u8
    ASCII_SPACE = 32_u8

    # This is the stream that will be read from.
    protected getter source : Pdfbox::IO::RandomAccessRead

    # Default constructor.
    def initialize(@source : Pdfbox::IO::RandomAccessRead)
    end

    # Skip the upcoming CRLF or LF which are supposed to follow a stream. Trailing spaces are removed as well.
    protected def skip_white_spaces : Nil
      # PDF Ref 3.2.7 A stream must be followed by either
      # a CRLF or LF but nothing else.
      whitespace = source.read
      return unless whitespace

      # see brother_scan_cover.pdf, it adds whitespaces
      # after the stream but before the start of the
      # data, so just read those first
      while whitespace && space?(whitespace)
        whitespace = source.read
      end

      return unless whitespace

      unless skip_linebreak_byte(whitespace)
        source.rewind(1)
      end
    end

    # Skip one line break, such as CR, LF or CRLF.
    protected def skip_linebreak : Bool
      # a line break is a CR, or LF or CRLF
      linebreak = source.read
      return false unless linebreak

      unless skip_linebreak_byte(linebreak)
        source.rewind(1)
        return false
      end
      true
    end

    # Skip one line break, such as CR, LF or CRLF.
    private def skip_linebreak_byte(linebreak : Int32) : Bool
      # a line break is a CR, or LF or CRLF
      if cr?(linebreak)
        next_byte = source.read
        unless lf?(next_byte)
          source.rewind(1) if next_byte
        end
      elsif !lf?(linebreak)
        return false
      end
      true
    end

    # This is really a bug in the Document creators code, but it caused a crash in PDFBox, the first bug was in this
    # format: /Title ( (5) /Creator which was patched in 1 place.
    # However it missed the case where the number of opening and closing parenthesis isn't balanced
    # The second bug was in this format /Title (c:\) /Producer
    private def check_for_end_of_string(braces_parameter : Int32) : Int32
      return 0 if braces_parameter == 0

      # Check the next 3 bytes if available
      next_three_bytes = Bytes.new(3)
      amount_read = source.read(next_three_bytes)
      if amount_read > 0
        source.rewind(amount_read)
      end

      if amount_read < 3
        return braces_parameter
      end

      # The following cases are valid indicators for the end of the string
      # 1. Next line contains another COSObject: CR + LF + '/'
      # 2. COSDictionary ends in the next line: CR + LF + '>'
      # 3. Next line contains another COSObject: LF + '/'
      # 4. COSDictionary ends in the next line: LF + '>'
      # 5. Next line contains another COSObject: CR + '/'
      # 6. COSDictionary ends in the next line: CR + '>'
      if ((cr?(next_three_bytes[0]) || lf?(next_three_bytes[0])) &&
         (next_three_bytes[1] == '/'.ord || next_three_bytes[1] == '>'.ord)) ||
         (cr?(next_three_bytes[0]) && lf?(next_three_bytes[1]) &&
         (next_three_bytes[2] == '/'.ord || next_three_bytes[2] == '>'.ord))
        return 0
      end

      braces_parameter
    end

    # Determine if a character terminates a PDF name.
    # ameba:disable Metrics/CyclomaticComplexity
    protected def end_of_name?(ch : Int32) : Bool
      case ch
      when ASCII_SPACE
        true
      when ASCII_CR
        true
      when ASCII_LF
        true
      when ASCII_TAB
        true
      when '>'.ord
        true
      when '<'.ord
        true
      when '['.ord
        true
      when '/'.ord
        true
      when ']'.ord
        true
      when ')'.ord
        true
      when '('.ord
        true
      when ASCII_NULL
        true
      when '\f'.ord
        true
      when '%'.ord
        true
      when -1
        true
      else
        false
      end
    end

    # This will read the next string from the stream.
    protected def read_string : String
      skip_spaces
      buffer = String::Builder.new

      c = source.read
      while c && !end_of_name?(c)
        buffer << c.chr
        c = source.read
      end

      if c
        source.rewind(1)
      end

      buffer.to_s
    end

    # This will parse a PDF string.
    # ameba:disable Metrics/CyclomaticComplexity
    protected def read_literal_string : Bytes
      read_expected_char('(')

      out = ::IO::Memory.new
      # This is the number of braces read
      braces = 1

      c = source.read
      while braces > 0 && c
        ch = c.chr
        nextc = -2 # not yet read

        if ch == ')'
          braces -= 1
          braces = check_for_end_of_string(braces)
          if braces != 0
            out.write_byte(ch.ord.to_u8)
          end
        elsif ch == '('
          braces += 1
          out.write_byte(ch.ord.to_u8)
        elsif ch == '\\'
          # patched by ram
          next_byte = source.read
          break unless next_byte
          next_char = next_byte.chr

          case next_char
          when 'n'
            out.write_byte('\n'.ord.to_u8)
          when 'r'
            out.write_byte('\r'.ord.to_u8)
          when 't'
            out.write_byte('\t'.ord.to_u8)
          when 'b'
            out.write_byte('\b'.ord.to_u8)
          when 'f'
            out.write_byte('\f'.ord.to_u8)
          when ')'
            # PDFBox 276 /Title (c:\)
            braces = check_for_end_of_string(braces)
            if braces != 0
              out.write_byte(next_char.ord.to_u8)
            else
              out.write_byte('\\'.ord.to_u8)
            end
          when '('
          when '\\'
            out.write_byte(next_char.ord.to_u8)
          when ASCII_LF.chr
          when ASCII_CR.chr
            # this is a break in the line so ignore it and the newline and continue
            c = source.read
            while c && eol?(c)
              c = source.read
            end
            nextc = c || -2
          when '0', '1', '2', '3', '4', '5', '6', '7'
            octal = String::Builder.new
            octal << next_char

            c = source.read
            if c
              digit = c.chr
              if digit >= '0' && digit <= '7'
                octal << digit
                c = source.read
                if c
                  digit = c.chr
                  if digit >= '0' && digit <= '7'
                    octal << digit
                  else
                    nextc = c
                  end
                end
              else
                nextc = c
              end
            end

            character = 0
            begin
              character = octal.to_s.to_i(8)
            rescue
              raise SyntaxError.new("Error: Expected octal character, actual='#{octal}'")
            end

            out.write_byte(character.to_u8)
          else
            # dropping the backslash
            # see 7.3.4.2 Literal Strings for further information
            out.write_byte(next_char.ord.to_u8)
          end
        else
          out.write_byte(ch.ord.to_u8)
        end

        if nextc != -2
          c = nextc
        else
          c = source.read
        end
      end

      if c
        source.rewind(1)
      end

      out.to_slice
    end

    # Reads given pattern from source. Skipping whitespace at start and end if wanted.
    protected def read_expected_string(expected_string : Array(Char), skip_spaces : Bool = true) : Nil
      self.skip_spaces if skip_spaces

      expected_string.each do |char|
        read_byte = source.read
        unless read_byte && read_byte.chr == char
          raise SyntaxError.new("Expected string '#{expected_string}' but missed at character '#{char}' at offset #{source.position}")
        end
      end

      self.skip_spaces if skip_spaces
    end

    # Overload for String parameter
    protected def read_expected_string(expected_string : String, skip_spaces : Bool = true, case_sensitive : Bool = true) : Nil
      self.skip_spaces if skip_spaces

      expected_string.each_char do |char|
        read_byte = source.read
        unless read_byte && (case_sensitive ? read_byte.chr == char : read_byte.chr.downcase == char.downcase)
          raise SyntaxError.new("Expected string '#{expected_string}' but missed at character '#{char}' at offset #{source.position}")
        end
      end

      self.skip_spaces if skip_spaces
    end

    # Read one char and throw an exception if it is not the expected value.
    protected def read_expected_char(ec : Char) : Nil
      c = source.read
      if c.nil? || c.chr != ec
        actual_char = c ? c.chr : '\uffff'
        raise SyntaxError.new("expected='#{ec}' actual='#{actual_char}' at offset #{source.position}")
      end
    end

    # Read next character without consuming it
    protected def peek_char : Char?
      c = source.peek
      c ? c.chr : nil
    end

    # Peek character at offset (0 = next character)
    protected def peek_char(offset : Int32 = 0) : Char?
      saved_pos = source.position
      offset.times do
        c = source.read
        break unless c
      end
      c = source.peek
      source.seek(saved_pos)
      c ? c.chr : nil
    end

    # Read next character and consume it
    protected def read_char : Char?
      c = source.read
      c ? c.chr : nil
    end

    # This will tell if the end of the data is reached.
    protected def eof? : Bool
      source.eof?
    end

    # This will tell if the next byte to be read is an end of line byte.
    protected def eol?(c : Int32) : Bool
      lf?(c) || cr?(c)
    end

    # This will tell if the next byte to be read is a line feed.
    protected def lf?(c : Int32) : Bool
      ASCII_LF == c
    end

    # This will tell if the next byte to be read is a carriage return.
    protected def cr?(c : Int32) : Bool
      ASCII_CR == c
    end

    # This will tell if the next byte is whitespace or not.
    protected def whitespace? : Bool
      c = source.peek
      c ? whitespace?(c) : false
    end

    # This will tell if a character is whitespace or not. These values are
    # specified in table 1 (page 12) of ISO 32000-1:2008.
    protected def whitespace?(c : Int32) : Bool
      case c
      when ASCII_NULL
        true
      when ASCII_TAB
        true
      when ASCII_FF
        true
      when ASCII_LF
        true
      when ASCII_CR
        true
      when ASCII_SPACE
        true
      else
        false
      end
    end

    # This will tell if the next byte is a space or not.
    protected def space? : Bool
      c = source.peek
      c ? space?(c) : false
    end

    # This will tell if the given value is a space or not.
    private def space?(c : Int32) : Bool
      ASCII_SPACE == c
    end

    # This will tell if the next byte is a digit or not.
    protected def digit? : Bool
      c = source.peek
      c ? digit?(c) : false
    end

    # This will tell if the given value is a digit or not.
    protected def digit?(c : Int32) : Bool
      ASCII_ZERO <= c <= ASCII_NINE
    end

    # This will tell if the given value is a hex digit (0-9, A-F, a-f) or not.
    protected def hex_digit?(c : Int32) : Bool
      digit?(c) || ('A'.ord <= c <= 'F'.ord) || ('a'.ord <= c <= 'f'.ord)
    end

    # This will skip all spaces and comments that are present.
    protected def skip_spaces : Nil
      c = source.read
      # 37 is the % character, a comment
      while c && (whitespace?(c) || c == 37)
        if c == 37
          # skip past the comment section
          c = source.read
          while c && !eol?(c)
            c = source.read
          end
        else
          c = source.read
        end
      end

      if c
        source.rewind(1)
      end
    end

    # This will read an integer from the stream.
    protected def read_int : Int32
      skip_spaces
      int_buffer = read_string_number

      begin
        int_buffer.to_s.to_i32
      rescue
        source.rewind(int_buffer.to_s.bytesize)
        raise SyntaxError.new("Error: Expected an integer type at offset #{source.position}, instead got '#{int_buffer}'")
      end
    end

    # This will read a long from the stream.
    protected def read_long : Int64
      skip_spaces
      long_buffer = read_string_number

      begin
        long_buffer.to_s.to_i64
      rescue
        source.rewind(long_buffer.to_s.bytesize)
        raise SyntaxError.new("Error: Expected a long type at offset #{source.position}, instead got '#{long_buffer}'")
      end
    end

    # Read a PDF number (integer or float)
    protected def read_number : Float64 | Int64
      skip_spaces

      buffer = String::Builder.new

      # Read first character
      c = source.read
      return 0_i64 unless c

      ch = c.chr
      # Check if first character could be part of number
      unless digit?(c) || ch == '-' || ch == '+' || ch == '.' || ch == 'E' || ch == 'e'
        source.rewind(1)
        raise SyntaxError.new("Expected number at position #{source.position}")
      end

      buffer.write_byte(c)

      # Continue reading while character is part of number
      loop do
        c = source.peek
        break unless c
        ch = c.chr
        unless digit?(c) || ch == '-' || ch == '+' || ch == '.' || ch == 'E' || ch == 'e'
          break
        end
        buffer.write_byte(c)
        source.read # consume
      end

      # PDFBOX-5025: catch "74191endobj" - if last character is 'e' or 'E', remove it
      str = buffer.to_s
      last_char = str[-1] if str.size > 0
      if last_char == 'e' || last_char == 'E'
        # Remove trailing 'e'/'E' and rewind source by 1 byte
        str = str[0...-1]
        source.rewind(1)
      end

      if str.empty?
        raise SyntaxError.new("Expected number at position #{source.position}")
      elsif str.includes?('.') || str.downcase.includes?('e')
        # Handle scientific notation: "1.23e+4" or "1.23E-4"
        # Crystal's to_f handles scientific notation
        str.to_f64
      else
        str.to_i64
      end
    end

    # Read a PDF name
    protected def read_name : String
      skip_spaces

      # Names start with '/'
      c = source.read
      unless c && c.chr == '/'
        raise SyntaxError.new("Expected '/' for name")
      end

      buffer = String::Builder.new
      while c = source.peek
        # Names can contain any characters except delimiters and whitespace
        break if whitespace?(c) || end_of_name?(c)

        buffer.write_byte(c)
        source.read # consume
      end

      buffer.to_s
    end

    # Read a PDF literal string as String (convenience method)
    protected def read_literal_string_as_string : String
      bytes = read_literal_string
      String.new(bytes, "ISO-8859-1")
    end

    # Read a PDF hexadecimal string
    # ameba:disable Metrics/CyclomaticComplexity
    protected def read_hexadecimal_string : String
      skip_spaces

      c = source.read
      unless c && c.chr == '<'
        raise SyntaxError.new("Expected '<' for hexadecimal string")
      end

      hex_digits = ""

      loop do
        c = source.read
        break unless c

        if hex_digit?(c)
          hex_digits += c.chr
        elsif c.chr == '>'
          break
        elsif whitespace?(c) || c == '\b'.ord || c == '\f'.ord
          # skip whitespace
          next
        else
          # invalid character - discard incomplete hex pair
          # Keep only complete pairs before the invalid character
          if hex_digits.size > 0
            # Discard last digit if odd, last two digits if even
            if hex_digits.size.even?
              hex_digits = hex_digits[0...-2]
            else
              hex_digits = hex_digits[0...-1]
            end
          end
          # read until closing bracket or EOF
          while c && c.chr != '>'
            c = source.read
          end
          break
        end
      end

      # Convert hex string to actual string
      result = String::Builder.new
      i = 0
      while i + 1 < hex_digits.size
        byte = hex_digits[i, 2].to_i(16)
        result << byte.chr
        i += 2
      end
      # Handle leftover single hex digit (pad with '0' per spec)
      if i < hex_digits.size
        byte = (hex_digits[i].to_s + "0").to_i(16)
        result << byte.chr
      end

      result.to_s
    end

    # This method is used to read a token by the read_int and the read_long method. Valid
    # delimiters are any non digit values.
    protected def read_string_number : String
      last_byte = source.read
      buffer = String::Builder.new

      while last_byte && digit?(last_byte)
        buffer << last_byte.chr
        if buffer.size > MAX_LENGTH_LONG
          raise SyntaxError.new("Number '#{buffer}' is getting too long, stop reading at offset #{source.position}")
        end
        last_byte = source.read
      end

      if last_byte
        source.rewind(1)
      end

      buffer.to_s
    end

    # Get current position
    def position : Int64
      source.position
    end

    # Seek to position
    def seek(position : Int64) : Nil
      source.seek(position)
    end
  end
end

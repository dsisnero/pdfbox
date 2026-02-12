# Lexer for the ASCII portions of an Adobe Type 1 font.
# Port of Apache PDFBox Type1Lexer.java
require "log"

module Fontbox::Type1
  class Type1Lexer
    Log = ::Log.for(self)

    @buffer : Bytes
    @pos : Int32
    @ahead_token : Token?
    @open_parens : Int32

    # Constructs a new Type1Lexer given a header-less .pfb segment
    def initialize(bytes : Bytes)
      @buffer = bytes
      @pos = 0
      @open_parens = 0
      @ahead_token = read_token(nil)
    end

    # Returns the next token and consumes it
    def next_token : Token?
      cur_token = @ahead_token
      # puts cur_token # for debugging
      @ahead_token = read_token(cur_token)
      cur_token
    end

    # Returns the next token without consuming it
    def peek_token : Token?
      @ahead_token
    end

    # Checks if the kind of the next token equals the given one without consuming it
    def peek_kind(kind : Kind) : Bool
      token = @ahead_token
      token && token.kind == kind
    end

    private def char : Char
      if @pos < @buffer.size
        c = @buffer[@pos].unsafe_chr
        @pos += 1
        c
      else
        raise IO::Error.new("Premature end of buffer reached")
      end
    end

    private def peek_char : Char?
      if @pos < @buffer.size
        @buffer[@pos].unsafe_chr
      end
    end

    private def unget_char : Nil
      @pos -= 1 if @pos > 0
    end

    # Reads a single token
    private def read_token(prev_token : Token?) : Token?
      skip = false
      loop do
        skip = false
        while @pos < @buffer.size
          c = char

          # delimiters
          case c
          when '%'
            # comment
            read_comment
          when '('
            return read_string
          when ')'
            # not allowed outside a string context
            raise IO::Error.new("unexpected closing parenthesis")
          when '['
            return Token.new(c, Kind::START_ARRAY)
          when '{'
            return Token.new(c, Kind::START_PROC)
          when ']'
            return Token.new(c, Kind::END_ARRAY)
          when '}'
            return Token.new(c, Kind::END_PROC)
          when '/'
            regular = read_regular
            if regular.nil?
              # the stream is corrupt
              raise DamagedFontException.new("Could not read token at position #{@pos}")
            end
            return Token.new(regular, Kind::LITERAL)
          when '<'
            c2 = peek_char
            if c2 == '<'
              char # consume second '<'
              return Token.new("<<", Kind::START_DICT)
            else
              # code may have to be changed in something better, maybe new token type
              unget_char
              return Token.new(c, Kind::NAME)
            end
          when '>'
            c2 = peek_char
            if c2 == '>'
              char # consume second '>'
              return Token.new(">>", Kind::END_DICT)
            else
              unget_char
              return Token.new(c, Kind::NAME)
            end
          else
            if c.whitespace?
              skip = true
            elsif c == '\0'
              Log.warn { "NULL byte in font, skipped" }
              skip = true
            else
              @pos -= 1 # put back character

              # regular character: try parse as number
              number = try_read_number
              if number
                return number
              else
                # otherwise this must be a name
                name = read_regular
                if name.nil?
                  raise DamagedFontException.new("Could not read token at position #{@pos}")
                end

                if name == "RD" || name == "-|"
                  # return the next CharString instead
                  if prev_token && prev_token.kind == Kind::INTEGER
                    return read_char_string(prev_token.int_value)
                  else
                    raise IO::Error.new("expected INTEGER before -| or RD")
                  end
                else
                  return Token.new(name, Kind::NAME)
                end
              end
            end
          end
        end
        break unless skip
      end
      nil
    end

    # Reads a number or returns nil
    private def try_read_number : Token?
      saved_pos = @pos
      sb = String::Builder.new
      radix = nil
      c = char
      has_digit = false

      # optional + or -
      if c == '+' || c == '-'
        sb << c
        c = char
      end

      # optional digits
      while c.ascii_number?
        sb << c
        c = char
        has_digit = true
      end

      # optional .
      if c == '.'
        sb << c
        c = char
      elsif c == '#'
        # PostScript radix number takes the form base#number
        radix = sb.to_s
        sb = String::Builder.new
        c = char
      elsif sb.empty? || !has_digit
        # failure
        @pos = saved_pos
        return
      elsif c != 'e' && c != 'E'
        # integer
        @pos -= 1
        return Token.new(sb.to_s, Kind::INTEGER)
      end

      # required digit
      if c.ascii_number?
        sb << c
        c = char
      elsif c != 'e' && c != 'E'
        # failure
        @pos = saved_pos
        return
      end

      # optional digits
      while c.ascii_number?
        sb << c
        c = char
      end

      # optional E
      if c == 'E' || c == 'e'
        sb << c
        c = char

        # optional minus
        if c == '-'
          sb << c
          c = char
        end

        # required digit
        if c.ascii_number?
          sb << c
          c = char
        else
          # failure
          @pos = saved_pos
          return
        end

        # optional digits
        while c.ascii_number?
          sb << c
          c = char
        end
      end

      @pos -= 1
      if radix
        begin
          val = sb.to_s.to_i32(radix.to_i32)
          return Token.new(val.to_s, Kind::INTEGER)
        rescue
          raise IO::Error.new("Invalid number '#{sb}'")
        end
      end
      Token.new(sb.to_s, Kind::REAL)
    end

    # Reads a sequence of regular characters, i.e. not delimiters or whitespace
    private def read_regular : String?
      sb = String::Builder.new
      while @pos < @buffer.size
        saved_pos = @pos
        c = char
        if c.whitespace? ||
           c == '(' || c == ')' ||
           c == '<' || c == '>' ||
           c == '[' || c == ']' ||
           c == '{' || c == '}' ||
           c == '/' || c == '%'
          @pos = saved_pos
          break
        else
          sb << c
        end
      end
      result = sb.to_s
      result.empty? ? nil : result
    end

    # Reads a line comment
    private def read_comment : String
      sb = String::Builder.new
      while @pos < @buffer.size
        c = char
        if c == '\r' || c == '\n'
          break
        else
          sb << c
        end
      end
      sb.to_s
    end

    # Reads a (string)
    private def read_string : Token?
      sb = String::Builder.new

      while @pos < @buffer.size
        c = char

        # string context
        case c
        when '('
          @open_parens += 1
          sb << '('
        when ')'
          if @open_parens == 0
            # end of string
            return Token.new(sb.to_s, Kind::STRING)
          end
          sb << ')'
          @open_parens -= 1
        when '\\'
          # escapes: \n \r \t \b \f \\ \( \)
          c1 = char
          case c1
          when 'n', 'r'
            sb << '\n'
          when 't'
            sb << '\t'
          when 'b'
            sb << '\b'
          when 'f'
            sb << '\f'
          when '\\'
            sb << '\\'
          when '('
            sb << '('
          when ')'
            sb << ')'
          else
            # octal \ddd
            if c1.ascii_number?
              # read two more digits
              c2 = char
              c3 = char
              num = String.build { |s| s << c1 << c2 << c3 }
              begin
                code = num.to_i32(8)
                sb << code.chr
              rescue
                raise IO::Error.new("Invalid octal escape: #{num}")
              end
            else
              # unknown escape, keep as is? Java default branch does nothing
            end
          end
        when '\r', '\n'
          sb << '\n'
        else
          sb << c
        end
      end
      # EOF before closing parenthesis
      nil
    end

    # Reads a binary CharString
    private def read_char_string(length : Int32) : Token
      if length > @buffer.size - @pos
        raise IO::Error.new("String length #{length} is larger than input")
      end
      # consume space
      char if peek_char == ' '
      data = @buffer[@pos, length]
      @pos += length
      Token.new(data, Kind::CHARSTRING)
    end
  end
end

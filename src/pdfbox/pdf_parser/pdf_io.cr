module Pdfbox::Pdfparser
  # Utility for reading PDF-specific data types
  module PDFIO
    # Read a PDF string (literal or hexadecimal)
    def self.read_string(io : ::IO) : String
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        parser = COSParser.new(io)
        parser.parse_string.try(&.value) || ""
      else
        # Fallback for generic IO
        # TODO: Implement basic string reading
        ""
      end
    end

    # Read a PDF name
    def self.read_name(io : ::IO) : String
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        parser = COSParser.new(io)
        parser.parse_name.try(&.value) || ""
      else
        # Fallback for generic IO
        ""
      end
    end

    # Read a PDF number
    def self.read_number(io : ::IO) : Float64 | Int64
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        parser = COSParser.new(io)
        case num = parser.parse_number
        when Pdfbox::Cos::Integer
          num.value
        when Pdfbox::Cos::Float
          num.value
        else
          read_number_generic_io(io)
        end
      else
        # Fallback for generic IO
        read_number_generic_io(io)
      end
    end

    private def self.read_number_generic_io(io : ::IO) : Float64 | Int64
      skip_whitespace(io)
      buffer = String::Builder.new
      char = read_number_sign(io, buffer)
      char = read_digits_before_decimal(char, io, buffer)
      char = read_decimal_part(char, io, buffer)
      unread_non_whitespace(char, io)

      str = buffer.to_s
      str.includes?('.') ? str.to_f64 : str.to_i64
    end

    private def self.read_number_sign(io : ::IO, buffer : String::Builder) : Char?
      char = io.read_char rescue nil
      if char == '+' || char == '-'
        buffer << char
        char = io.read_char rescue nil
      end
      char
    end

    private def self.read_digits_before_decimal(char : Char?, io : ::IO, buffer : String::Builder) : Char?
      while char && char.ascii_number?
        buffer << char
        char = io.read_char rescue nil
      end
      char
    end

    private def self.read_decimal_part(char : Char?, io : ::IO, buffer : String::Builder) : Char?
      if char == '.'
        buffer << char
        char = io.read_char rescue nil
        while char && char.ascii_number?
          buffer << char
          char = io.read_char rescue nil
        end
      end
      char
    end

    private def self.unread_non_whitespace(char : Char?, io : ::IO) : Nil
      if char && !char.ascii_whitespace? && char != '%' && io.responds_to?(:seek)
        io.seek(-1, IO::Seek::Current)
      end
    end

    private def self.parse_date_from_random_access_read(io : Pdfbox::IO::RandomAccessRead) : Time?
      parser = COSParser.new(io)
      parser.skip_spaces

      # Check for "D:" prefix
      saved_pos = parser.position
      begin
        parser.read_expected_string("D:")
      rescue
        parser.seek(saved_pos)
        return
      end

      # Read year (4 digits)
      year_str = ""
      4.times do
        c = parser.source.peek
        break unless c && parser.digit?(c)
        year_str << parser.source.read.chr
      end
      return if year_str.empty?
      year = year_str.to_i

      # Read month (2 digits, optional)
      month_str = ""
      2.times do
        c = parser.source.peek
        break unless c && parser.digit?(c)
        month_str << parser.source.read.chr
      end
      month = month_str.empty? ? 1 : month_str.to_i

      # Read day (2 digits, optional)
      day_str = ""
      2.times do
        c = parser.source.peek
        break unless c && parser.digit?(c)
        day_str << parser.source.read.chr
      end
      day = day_str.empty? ? 1 : day_str.to_i

      # Read hour (2 digits, optional)
      hour_str = ""
      2.times do
        c = parser.source.peek
        break unless c && parser.digit?(c)
        hour_str << parser.source.read.chr
      end
      hour = hour_str.empty? ? 0 : hour_str.to_i

      # Read minute (2 digits, optional)
      minute_str = ""
      2.times do
        c = parser.source.peek
        break unless c && parser.digit?(c)
        minute_str << parser.source.read.chr
      end
      minute = minute_str.empty? ? 0 : minute_str.to_i

      # Read second (2 digits, optional)
      second_str = ""
      2.times do
        c = parser.source.peek
        break unless c && parser.digit?(c)
        second_str << parser.source.read.chr
      end
      second = second_str.empty? ? 0 : second_str.to_i

      # Read timezone (O HH ' mm ')
      c = parser.source.peek
      return Time.utc(year, month, day, hour, minute, second) unless c

      tz_char = parser.source.read.chr
      case tz_char
      when 'Z', 'z'
        # UTC
        Time.utc(year, month, day, hour, minute, second)
      when '+', '-'
        # Timezone offset
        # Read HH (2 digits)
        tz_hour_str = ""
        2.times do
          c = parser.source.peek
          break unless c && parser.digit?(c)
          tz_hour_str << parser.source.read.chr
        end
        return Time.utc(year, month, day, hour, minute, second) if tz_hour_str.empty?
        tz_hour = tz_hour_str.to_i

        # Check for "'" separator
        c = parser.source.peek
        if c && c.chr == '\''
          parser.source.read # consume '
        else
          return Time.utc(year, month, day, hour, minute, second)
        end

        # Read mm (2 digits)
        tz_minute_str = ""
        2.times do
          c = parser.source.peek
          break unless c && parser.digit?(c)
          tz_minute_str << parser.source.read.chr
        end
        tz_minute = tz_minute_str.empty? ? 0 : tz_minute_str.to_i

        # Check for "'" separator
        c = parser.source.peek
        if c && c.chr == '\''
          parser.source.read # consume '
        end

        # Calculate offset in seconds
        offset_seconds = tz_hour * 3600 + tz_minute * 60
        offset_seconds = -offset_seconds if tz_char == '-'

        # Return time with offset (PDF times are local times)
        # We'll convert to UTC
        Time.local(year, month, day, hour, minute, second, nanosecond: 0).shift(seconds: -offset_seconds)
      else
        # Unknown timezone marker, treat as local time
        parser.source.rewind(1) # put back char
        Time.local(year, month, day, hour, minute, second)
      end
    end

    # Skip whitespace and comments
    def self.skip_whitespace(io : ::IO) : Nil
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        parser = COSParser.new(io)
        parser.skip_spaces
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
        parser = COSParser.new(io)
        parser.skip_spaces
        parser.peek_char
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
        parse_date_from_random_access_read(io)
      end
    end
  end
end

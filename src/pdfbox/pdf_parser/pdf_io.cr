module Pdfbox::Pdfparser
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
end

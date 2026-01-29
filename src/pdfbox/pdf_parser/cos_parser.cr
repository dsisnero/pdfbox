require "./base_parser"
require "../io"

module Pdfbox::Pdfparser
  # PDF object parser for individual COS objects using incremental byte reading
  # Similar to Apache PDFBox COSParser
  class COSParser < BaseParser
    # Maximum recursion depth for parsing nested objects
    MAX_RECURSION_DEPTH = 500

    @parser : Pdfbox::Pdfparser::Parser?

    def initialize(source : Pdfbox::IO::RandomAccessRead, parser : Pdfbox::Pdfparser::Parser? = nil)
      super(source)
      @parser = parser
      @recursion_depth = 0
    end

    # Parse a COS object from the stream (similar to Apache PDFBox parseDirObject)
    # ameba:disable Metrics/CyclomaticComplexity
    def parse_dir_object : Pdfbox::Cos::Base?
      @recursion_depth += 1
      if @recursion_depth > MAX_RECURSION_DEPTH
        raise SyntaxError.new("Maximum recursion depth #{MAX_RECURSION_DEPTH} exceeded")
      end

      skip_spaces
      char = peek_char
      return if char.nil?

      case char
      when '<'
        # Could be dictionary (<<) or hex string (<)
        saved_pos = position
        read_char # consume '<'
        next_char = peek_char
        seek(saved_pos) # restore

        if next_char == '<'
          parse_dictionary
        else
          parse_string
        end
      when '['
        parse_array
      when '('
        parse_string
      when '/'
        parse_name
      when 'n'
        # null
        read_expected_string("null", case_sensitive: false)
        Pdfbox::Cos::Null.instance
      when 't'
        # true
        read_expected_string("true", case_sensitive: false)
        Pdfbox::Cos::Boolean::TRUE
      when 'f'
        # false
        read_expected_string("false", case_sensitive: false)
        Pdfbox::Cos::Boolean::FALSE
      when 'R'
        # Indirect object reference in content stream
        read_char                     # consume 'R'
        Pdfbox::Cos::Object.new(0, 0) # placeholder, will be resolved later
      when '0'..'9', '+', '-', '.'
        # Try to parse as indirect reference first (obj gen R)
        ref = parse_reference
        ref ? ref : parse_number
      else
        # Unknown token - read string and check for endobj/endstream
        saved_pos = position
        str = read_string rescue ""
        if str.empty?
          # EOF or error
          return
        end

        # If it's endobj or endstream, rewind so caller can see it
        if str == "endobj" || str == "endstream"
          seek(saved_pos)
        else
          # Skip unexpected token in lenient mode
          # Return null like Apache PDFBox does
          Pdfbox::Cos::Null.instance
        end
      end
    ensure
      @recursion_depth -= 1
    end

    # Alias for backward compatibility
    def parse_object : Pdfbox::Cos::Base?
      parse_dir_object
    end

    # Parse a COS dictionary
    def parse_dictionary : Pdfbox::Cos::Dictionary?
      skip_spaces

      # Dictionary starts with '<<'
      saved_pos = position
      begin
        read_expected_char('<')
        read_expected_char('<')
      rescue ex
        seek(saved_pos)
        return
      end

      dict = Pdfbox::Cos::Dictionary.new

      loop do
        skip_spaces
        # Check for '>>' using peek
        c1 = peek_char
        c2 = peek_char(1)
        if c1 == '>' && c2 == '>'
          # Consume both '>>'
          read_char
          read_char
          break
        end

        # Parse key (must be a name)
        key = parse_name
        unless key
          break
        end

        # Parse value
        value = parse_object
        unless value
          break
        end

        dict[key] = value
      end

      dict
    end

    # Parse a COS array
    def parse_array : Pdfbox::Cos::Array?
      skip_spaces

      # Array starts with '['
      saved_pos = position
      begin
        read_expected_char('[')
      rescue ex
        seek(saved_pos)
        return
      end

      array = Pdfbox::Cos::Array.new

      loop do
        skip_spaces

        # Check for ']'
        saved_pos2 = position
        begin
          if peek_char == ']'
            read_char # consume ']'
            break
          end
        rescue
          seek(saved_pos2)
        end

        value = parse_object
        break unless value

        array.add(value)

        skip_spaces
        # Check for ']' again
        saved_pos3 = position
        begin
          if peek_char == ']'
            read_char # consume ']'
            break
          end
        rescue
          seek(saved_pos3)
        end
        # Arrays can have spaces between elements
      end

      array
    end

    # Parse a COS literal string (for testing compatibility)
    def parse_cos_literal_string : Pdfbox::Cos::String
      skip_spaces
      string = read_literal_string_as_string
      Pdfbox::Cos::String.new(string)
    end

    # Parse a COS string
    def parse_string : Pdfbox::Cos::String?
      skip_spaces

      # Check for literal string '(' or hexadecimal string '<'
      char = peek_char
      return unless char

      string =
        case char
        when '('
          read_literal_string_as_string rescue nil
        when '<'
          read_hexadecimal_string rescue nil
        end

      return unless string

      Pdfbox::Cos::String.new(string)
    end

    # Parse a COS name
    def parse_name : Pdfbox::Cos::Name?
      skip_spaces

      name = read_name rescue nil
      return unless name

      Pdfbox::Cos::Name.new(name)
    end

    # Parse a COS number (integer or float)
    def parse_number : Pdfbox::Cos::Base?
      skip_spaces

      number = read_number rescue nil
      return unless number

      case number
      when Int64
        Pdfbox::Cos::Integer.new(number)
      when Float64
        Pdfbox::Cos::Float.new(number)
      end
    end

    # Parse a COS indirect object reference (obj gen R)
    def parse_reference : Pdfbox::Cos::Object?
      skip_spaces

      # Save position in case we need to rollback
      saved_pos = position

      # Try to read first integer
      begin
        # Read number using custom logic since read_number reads floats too
        # We need to read integer only
        first_num = read_reference_number
        return unless first_num
      rescue
        seek(saved_pos)
        return
      end

      # Must have whitespace after first integer
      skip_spaces

      # Try to read second integer
      begin
        second_num = read_reference_number
        unless second_num
          seek(saved_pos)
          return
        end
      rescue
        seek(saved_pos)
        return
      end

      # Must have whitespace before 'R'
      skip_spaces

      # Try to read 'R'
      begin
        c = read_char
        unless c == 'R'
          seek(saved_pos)
          return
        end
      rescue
        seek(saved_pos)
        return
      end

      # Success - create reference object
      obj_num = first_num
      gen_num = second_num
      if parser = @parser
        parser.get_object_from_pool(obj_num, gen_num)
      else
        Pdfbox::Cos::Object.new(obj_num, gen_num)
      end
    end

    # Helper to read integer for reference (similar to read_number but integer only)
    private def read_reference_number : Int64?
      skip_spaces

      buffer = String::Builder.new
      c = source.peek
      return unless c

      # Optional sign
      c_val = c.as(UInt8).to_i32
      if c_val.chr == '+' || c_val.chr == '-'
        buffer.write_byte(c_val.to_u8)
        source.read # consume
        c = source.peek
      end

      # Digits
      while c && digit?(c.as(UInt8).to_i32)
        buffer.write_byte(c.as(UInt8))
        source.read # consume
        c = source.peek
      end

      str = buffer.to_s
      return if str.empty?

      str.to_i64
    end

    # Parse a COS boolean
    def parse_boolean : Pdfbox::Cos::Boolean?
      skip_spaces

      saved_pos = position

      # Try "true"
      begin
        read_expected_string("true", case_sensitive: false)
        return Pdfbox::Cos::Boolean::TRUE
      rescue
        seek(saved_pos)
      end

      # Try "false"
      begin
        read_expected_string("false", case_sensitive: false)
        Pdfbox::Cos::Boolean::FALSE
      rescue
        seek(saved_pos)
        return
      end
    end

    # Parse a COS null
    def parse_null : Pdfbox::Cos::Null?
      skip_spaces

      saved_pos = position
      begin
        read_expected_string("null", case_sensitive: false)
        Pdfbox::Cos::Null.instance
      rescue
        seek(saved_pos)
        return
      end
    end
  end
end

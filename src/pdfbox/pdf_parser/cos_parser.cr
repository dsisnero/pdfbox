require "log"
require "./base_parser"
require "../io"

module Pdfbox::Pdfparser
  # PDF object parser for individual COS objects using incremental byte reading
  # Similar to Apache PDFBox COSParser
  class COSParser < BaseParser
    Log = ::Log.for(self)

    # Constants matching Apache PDFBox COSParser
    ENDOBJ_STRING           = "endobj"
    ENDSTREAM_STRING        = "endstream"
    STREAM_STRING           = "stream"
    NULL                    = ['n', 'u', 'l', 'l']
    TRUE                    = ['t', 'r', 'u', 'e']
    FALSE                   = ['f', 'a', 'l', 's', 'e']
    MAX_RECURSION_DEPTH_MSG = "Reached maximum recursion depth #{MAX_RECURSION_DEPTH}"

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
        raise SyntaxError.new(MAX_RECURSION_DEPTH_MSG)
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
          parse_dictionary(true)
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
        read_expected_string(NULL, skip_spaces: false)
        Pdfbox::Cos::Null.instance
      when 't'
        # true
        read_expected_string(TRUE, skip_spaces: false)
        Pdfbox::Cos::Boolean::TRUE
      when 'f'
        # false
        read_expected_string(FALSE, skip_spaces: false)
        Pdfbox::Cos::Boolean::FALSE
      when 'R'
        # Indirect object reference in content stream
        read_char                          # consume 'R'
        Pdfbox::Cos::Object.new(0, 0, nil) # placeholder, will be resolved later
      when '0'..'9', '+', '-', '.'
        # Java line 1102: if (isDigit(c) || c == '-' || c == '+' || c == '.') return parseCOSNumber()
        parse_number
      else
        # This is not suppose to happen, but we will allow for it
        # so we are more compatible with POS writers that don't follow the spec
        start_offset = position
        bad_string = read_string
        if bad_string.empty?
          # we can end up in an infinite loop otherwise
          peek = source.peek
          raise SyntaxError.new("Unknown dir object c='#{char}' cInt=#{char.ord} peek='#{peek ? peek.chr : "EOF"}' peekInt=#{peek || -1} at offset #{position} (start offset: #{start_offset})")
        end

        # if it's an endstream/endobj, we want to put it back so the caller will see it
        if bad_string == ENDOBJ_STRING || bad_string == ENDSTREAM_STRING
          source.rewind(bad_string.bytesize)
        else
          Log.warn { "Skipped unexpected dir object = '#{bad_string}' at offset #{position} (start offset: #{start_offset})" }
          # Return null like Apache PDFBox does (we're not PDFStreamParser)
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
    def parse_dictionary(is_direct : Bool = true) : Pdfbox::Cos::Dictionary
      @recursion_depth += 1
      if @recursion_depth > MAX_RECURSION_DEPTH
        raise SyntaxError.new(MAX_RECURSION_DEPTH_MSG)
      end

      read_expected_char('<')
      read_expected_char('<')
      skip_spaces
      dict = Pdfbox::Cos::Dictionary.new
      # TODO: setDirect(is_direct) when Cos::Dictionary supports it

      loop do
        skip_spaces
        c = peek_char
        break if c == '>'

        if c == '/'
          # something went wrong, most likely the dictionary is corrupted
          # stop immediately and return everything read so far
          unless parse_cos_dictionary_name_value_pair(dict)
            return dict
          end
        else
          # invalid dictionary, we were expecting a /Name, read until the end or until we can recover
          Log.warn { "Invalid dictionary, found: '#{c}' but expected: '/' at offset #{position}" }
          if read_until_end_of_cos_dictionary
            # we couldn't recover
            return dict
          end
        end
      end

      begin
        read_expected_char('>')
        read_expected_char('>')
      rescue ex
        Log.warn { "Invalid dictionary, can't find end of dictionary at offset #{position}" }
      end
      dict
    ensure
      @recursion_depth -= 1
    end

    private def parse_cos_dictionary_name_value_pair(dict : Pdfbox::Cos::Dictionary) : Bool
      key = parse_name
      if key.nil? || key.value.empty?
        Log.warn { "Empty COSName at offset #{position}" }
      end
      value = parse_cos_dictionary_value
      skip_spaces
      if value.nil?
        Log.warn { "Bad dictionary declaration at offset #{position}" }
        return false
      elsif value.is_a?(Pdfbox::Cos::Integer) && !value.valid?
        Log.warn { "Skipped out of range number value at offset #{position}" }
      else
        # label this item as direct, to avoid signature problems.
        # value.setDirect(true) when supported
        if key
          dict[key] = value
        end
      end
      true
    end

    private def parse_cos_dictionary_value : Pdfbox::Cos::Base?
      num_offset = position
      value = parse_dir_object
      skip_spaces
      # proceed if the given object is a number and the following is a number as well
      return value unless value.is_a?(Pdfbox::Cos::Number) && digit?

      # read the remaining information of the object number
      gen_offset = position
      generation_number = parse_dir_object
      skip_spaces
      read_expected_char('R')
      unless value.is_a?(Pdfbox::Cos::Integer)
        Log.error { "expected number, actual=#{value} at offset #{num_offset}" }
        return Pdfbox::Cos::Null.instance
      end
      unless generation_number.is_a?(Pdfbox::Cos::Integer)
        Log.error { "expected number, actual=#{generation_number} at offset #{gen_offset}" }
        return Pdfbox::Cos::Null.instance
      end
      obj_number = value.as(Pdfbox::Cos::Integer).value.to_i64
      if obj_number <= 0
        Log.warn { "invalid object number value =#{obj_number} at offset #{num_offset}" }
        return Pdfbox::Cos::Null.instance
      end
      gen_number = generation_number.as(Pdfbox::Cos::Integer).value.to_i64
      if gen_number < 0
        Log.error { "invalid generation number value =#{gen_number} at offset #{num_offset}" }
        return Pdfbox::Cos::Null.instance
      end
      # dereference the object
      get_object_from_pool(get_object_key(obj_number, gen_number))
    end

    private def read_until_end_of_cos_dictionary : Bool
      c = read_char
      while c && c != '/' && c != '>'
        # in addition to stopping when we find / or >, we also want
        # to stop when we find endstream or endobj.
        if c == 'E'
          c = read_char
          if c == 'N'
            c = read_char
            if c == 'D'
              c = read_char
              is_stream = c == 'S' && read_char == 'T' && read_char == 'R' && read_char == 'E' && read_char == 'A' && read_char == 'M'
              is_obj = !is_stream && c == 'O' && read_char == 'B' && read_char == 'J'
              if is_stream || is_obj
                # we're done reading this object!
                return true
              end
            end
          end
        end
        c = read_char
      end
      if c.nil?
        return true
      end
      source.rewind(1)
      false
    end

    # Parse a COS array
    def parse_array : Pdfbox::Cos::Array
      @recursion_depth += 1
      if @recursion_depth > MAX_RECURSION_DEPTH
        raise SyntaxError.new(MAX_RECURSION_DEPTH_MSG)
      end

      start_position = position
      read_expected_char('[')
      array = Pdfbox::Cos::Array.new

      loop do
        skip_spaces
        break if peek_char == ']'

        value = parse_dir_object
        if value.is_a?(Pdfbox::Cos::Object)
          # the current empty COSObject is replaced with the correct one
          value = nil
          # We have to check if the expected values are there or not PDFBOX-385
          if array.size > 1 && array[array.size - 1].is_a?(Pdfbox::Cos::Integer)
            gen_number = array.delete_at(array.size - 1).as(Pdfbox::Cos::Integer)
            if array.size > 0 && array[array.size - 1].is_a?(Pdfbox::Cos::Integer)
              number = array.delete_at(array.size - 1).as(Pdfbox::Cos::Integer)
              if number.value >= 0 && gen_number.value >= 0
                key = get_object_key(number.value.to_i64, gen_number.value.to_i64)
                value = get_object_from_pool(key)
              else
                Log.warn { "Invalid value(s) for an object key #{number.value} #{gen_number.value}" }
              end
            end
          end
        end

        # something went wrong
        if value.nil?
          # it could be a bad object in the array which is just skipped
          Log.warn { "Corrupt array element at offset #{position}, start offset: #{start_position}" }
          is_this_the_end = read_string
          # return immediately if a corrupt element is followed by another array
          # to avoid a possible infinite recursion as most likely the whole array is corrupted
          if is_this_the_end.empty? && peek_char == '['
            return array
          end
          source.rewind(is_this_the_end.bytesize)
          # This could also be an "endobj" or "endstream" which means we can assume that
          # the array has ended.
          if is_this_the_end == ENDOBJ_STRING || is_this_the_end == ENDSTREAM_STRING
            return array
          end
        else
          array.add(value)
        end

        skip_spaces
      end

      # read ']'
      read_char
      skip_spaces
      array
    ensure
      @recursion_depth -= 1
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

    # Get object key for given number and generation
    protected def get_object_key(num : Int64, gen : Int64) : Pdfbox::Cos::ObjectKey
      # TODO: Implement proper caching like Java version
      Pdfbox::Cos::ObjectKey.new(num, gen)
    end

    # Get object from pool by object key
    protected def get_object_from_pool(key : Pdfbox::Cos::ObjectKey) : Pdfbox::Cos::Base?
      parser = @parser
      if parser.nil?
        raise SyntaxError.new("object reference #{key} at offset #{position} in content stream")
      end
      parser.get_object_from_pool(key)
    end

    # Read a line from the source stream (similar to Apache PDFBox readLine)
    # Reads until CR or LF, handles CR+LF
    protected def read_line : String
      if source.eof?
        raise SyntaxError.new("Error: End-of-File, expected line at offset #{source.position}")
      end

      buffer = String::Builder.new

      c = source.read
      while c && !eol?(c)
        buffer << c.chr
        c = source.read
      end

      # CR+LF is also a valid EOL
      if c && cr?(c) && lf?(source.peek)
        source.read # consume the LF
      end

      buffer.to_s
    end
  end
end

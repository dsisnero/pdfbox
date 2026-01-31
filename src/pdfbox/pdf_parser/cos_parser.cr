require "log"
require "./base_parser"
require "./endstream_filter_stream"
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

    # Byte array constants for keyword matching (similar to Apache PDFBox)
    ENDSTREAM  = Bytes[0x65, 0x6E, 0x64, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D] # 'endstream'
    ENDOBJ     = Bytes[0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A]                   # 'endobj'
    STRMBUFLEN = 2048

    # Header constants (similar to Apache PDFBox COSParser)
    PDF_HEADER                  = "%PDF-"
    FDF_HEADER                  = "%FDF-"
    PDF_DEFAULT_VERSION         = "1.4"
    FDF_DEFAULT_VERSION         = "1.0"
    EOF_MARKER                  = Bytes[0x25, 0x25, 0x45, 0x4F, 0x46] # '%%EOF'
    OBJ_MARKER                  = Bytes[0x6F, 0x62, 0x6A]             # 'obj'
    OBJECT_NUMBER_THRESHOLD     = 10_000_000_000_i64                  # 10 digits
    GENERATION_NUMBER_THRESHOLD =         65_535_i64                  # 5 digits

    # ASCII byte values for keyword matching
    private E = 0x65_u8
    private N = 0x6E_u8
    private D = 0x64_u8
    private S = 0x73_u8
    private T = 0x74_u8
    private R = 0x72_u8
    private A = 0x61_u8
    private M = 0x6D_u8
    private O = 0x6F_u8
    private B = 0x62_u8
    private J = 0x6A_u8

    # Maximum recursion depth for parsing nested objects
    MAX_RECURSION_DEPTH = 500

    @parser : Pdfbox::Pdfparser::Parser?
    @file_len : Int64
    @strm_buf : Bytes
    @recursion_depth : Int32
    @key_cache : Hash(Int64, Pdfbox::Cos::ObjectKey)

    def initialize(source : Pdfbox::IO::RandomAccessRead, parser : Pdfbox::Pdfparser::Parser? = nil)
      super(source)
      @parser = parser
      @recursion_depth = 0
      @file_len = source.length
      @strm_buf = Bytes.new(STRMBUFLEN)
      @key_cache = Hash(Int64, Pdfbox::Cos::ObjectKey).new
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
      dict.set_direct(is_direct)

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
        value.try(&.set_direct(true))
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
    def parse_name : Pdfbox::Cos::Name
      read_expected_char('/')

      buffer = Array(UInt8).new
      c = source.read

      while c && !end_of_name?(c)
        ch = c
        if ch.chr == '#'
          # Read two hex digits for escape sequence
          ch1 = source.read
          ch2 = source.read

          # Check for premature EOF
          if ch1.nil? || ch2.nil?
            Log.error { "Premature EOF in BaseParser#parseCOSName" }
            c = nil
            break
          end

          # Check if both are valid hex digits
          if hex_digit?(ch1) && hex_digit?(ch2)
            hex = ch1.chr.to_s + ch2.chr.to_s
            begin
              byte_val = hex.to_i(16).to_u8
              buffer << byte_val
            rescue
              raise SyntaxError.new("Error: expected hex digit, actual='#{hex}'")
            end
            c = source.read
          else
            # Not valid hex digits, treat '#' as literal
            source.rewind(1) # put back ch2
            c = ch1
            buffer << '#'.ord.to_u8
            # Continue loop with c = ch1
          end
        else
          buffer << ch.to_u8
          c = source.read
        end
      end

      # Rewind the last character if not EOF (nil)
      if c
        source.rewind(1)
      end

      name_str = decode_buffer(Slice.new(buffer.to_unsafe, buffer.size))
      Pdfbox::Cos::Name.new(name_str)
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

    # Parse a number or indirect reference (obj gen R)
    # Similar to Apache PDFBox parseCOSNumberOrReference
    def parse_number_or_reference : Pdfbox::Cos::Base?
      skip_spaces

      # Save position in case we need to rollback
      saved_pos = position

      # Try to parse as reference first
      ref = parse_reference
      if ref
        return ref
      end

      # Not a reference, parse as regular number
      seek(saved_pos)
      parse_number
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

    # Decode buffer with UTF-8, fallback to ISO-8859-1
    private def decode_buffer(bytes : Bytes) : String
      # Try UTF-8 first
      String.new(bytes, "UTF-8")
    rescue
      # Fallback to ISO-8859-1 (Latin-1)
      Log.debug { "Buffer could not be decoded using UTF-8 - trying ISO-8859-1" }
      String.new(bytes, "ISO-8859-1")
    end

    # Get object key for given number and generation
    protected def get_object_key(num : Int64, gen : Int64) : Pdfbox::Cos::ObjectKey
      parser = @parser
      return Pdfbox::Cos::ObjectKey.new(num, gen) if parser.nil?

      xref = parser.xref
      return Pdfbox::Cos::ObjectKey.new(num, gen) if xref.nil?

      # use a cache to get the COSObjectKey as iterating over the xref-table-map gets slow for big pdfs
      # in the long run we have to overhaul the object pool or even better remove it
      if xref.size > @key_cache.size
        xref.entries.each_key do |key|
          internal_hash = key.internal_hash
          @key_cache[internal_hash] = key unless @key_cache.has_key?(internal_hash)
        end
      end

      internal_hash = Pdfbox::Cos::ObjectKey.compute_internal_hash(num, gen)
      found_key = @key_cache[internal_hash]?
      return found_key if found_key

      Pdfbox::Cos::ObjectKey.new(num, gen)
    end

    # Get object from pool by object key
    protected def get_object_from_pool(key : Pdfbox::Cos::ObjectKey) : Pdfbox::Cos::Object
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

    # Returns length value referred to or defined in given object.
    private def get_length(length_base_obj : Pdfbox::Cos::Base?) : Pdfbox::Cos::Base?
      return if length_base_obj.nil?
      # maybe length was given directly
      if length_base_obj.is_a?(Pdfbox::Cos::Number)
        return length_base_obj
      end
      # length in referenced object
      if length_base_obj.is_a?(Pdfbox::Cos::Object)
        length_obj = length_base_obj.as(Pdfbox::Cos::Object)
        length = length_obj.object
        if length.nil?
          raise ::IO::Error.new("Length object content was not read.")
        end
        if length.is_a?(Pdfbox::Cos::Null)
          Log.warn { "Length object (#{length_obj.key}) not found" }
          return
        end
        if length.is_a?(Pdfbox::Cos::Number)
          return length
        end
        raise ::IO::Error.new("Wrong type of referenced length object #{length_obj}: #{length.class}")
      end
      raise ::IO::Error.new("Wrong type of length object: #{length_base_obj.class}")
    end

    private def string?(bytes : Bytes) : Bool
      saved_pos = position
      bytes.each do |byte|
        read_byte = source.read
        if read_byte.nil? || read_byte != byte
          seek(saved_pos)
          return false
        end
      end
      seek(saved_pos)
      true
    end

    private def validate_stream_length(stream_length : Int64) : Bool
      origin_offset = position
      if stream_length == 0
        # This may be valid (PDFBOX-5954), or not (PDFBOX-5880)
        Log.debug { "Suspicious stream length 0, start position: #{origin_offset}" }
        return false
      elsif stream_length < 0
        Log.warn { "Invalid stream length: #{stream_length}, start position: #{origin_offset}" }
        return false
      end
      expected_end_of_stream = origin_offset + stream_length
      if expected_end_of_stream > @file_len
        Log.warn do
          "The end of the stream is out of range, using workaround to read the stream, " \
          "stream start position: #{origin_offset}, length: #{stream_length}, " \
          "expected end position: #{expected_end_of_stream}"
        end
        return false
      end
      seek(expected_end_of_stream)
      skip_spaces
      end_stream_found = string?(ENDSTREAM)
      seek(origin_offset)
      unless end_stream_found
        Log.warn do
          "The end of the stream doesn't point to the correct offset, using workaround to read the stream, " \
          "stream start position: #{origin_offset}, length: #{stream_length}, " \
          "expected end position: #{expected_end_of_stream}"
        end
        return false
      end
      true
    end

    private def read_until_end_stream(filter_stream : EndstreamFilterStream) : Int64
      buf_size = 0
      char_match_count = 0
      keyw = ENDSTREAM
      # last character position of shortest keyword ('endobj')
      quick_test_offset = 5
      # read next chunk into buffer; already matched chars are added to beginning of buffer
      while (buf_size = source.read(@strm_buf[char_match_count, STRMBUFLEN - char_match_count])) > 0
        buf_size += char_match_count
        b_idx = char_match_count
        max_quicktest_idx = buf_size - quick_test_offset
        # iterate over buffer, trying to find keyword match
        while b_idx < buf_size
          # reduce compare operations by first test last character we would have to
          # match if current one matches; if it is not a character from keywords
          # we can move behind the test character; this shortcut is inspired by the
          # Boyer-Moore string search algorithm and can reduce parsing time by approx. 20%
          quick_test_idx = b_idx + quick_test_offset
          if char_match_count == 0 && quick_test_idx < max_quicktest_idx
            ch = @strm_buf[quick_test_idx]
            if (ch > 't'.ord.to_u8) || (ch < 'a'.ord.to_u8)
              # last character we would have to match if current character would match
              # is not a character from keywords -> jump behind and start over
              b_idx = quick_test_idx
              next
            end
          end
          ch = @strm_buf[b_idx]
          if ch == keyw[char_match_count]
            char_match_count += 1
            if char_match_count == keyw.size
              # match found
              b_idx += 1
              break
            end
          else
            if char_match_count == 3 && ch == ENDOBJ[char_match_count]
              # maybe ENDSTREAM is missing but we could have ENDOBJ
              keyw = ENDOBJ
              char_match_count += 1
            else
              # no match; incrementing match start by 1 would be dumb since we already know
              # matched chars depending on current char read we may already have beginning
              # of a new match: 'e': first char matched; 'n': if we are at match position
              # idx 7 we already read 'e' thus 2 chars matched for each other char we have
              # to start matching first keyword char beginning with next read position
              char_match_count = if ch == E
                                   1
                                 elsif (ch == N) && (char_match_count == 7)
                                   2
                                 else
                                   0
                                 end
              # search again for 'endstream'
              keyw = ENDSTREAM
            end
          end
          b_idx += 1
        end
        content_bytes = Math.max(0, b_idx - char_match_count)
        # write buffer content until first matched char to output stream
        if content_bytes > 0
          filter_stream.filter(@strm_buf, 0, content_bytes)
        end
        if char_match_count == keyw.size
          # keyword matched; unread matched keyword (endstream/endobj) and following buffered content
          source.rewind(buf_size - content_bytes)
          break
        else
          # copy matched chars at start of buffer
          keyw[0, char_match_count].copy_to(@strm_buf[0, char_match_count])
        end
      end
      # this writes a lonely CR or drops trailing CR LF and LF
      filter_stream.calculate_length
    end

    protected def parse_cos_stream(dic : Pdfbox::Cos::Dictionary) : Pdfbox::Cos::Stream
      # read 'stream'; this was already tested in parseObjectsDynamically()
      read_string
      skip_spaces
      # This needs to be dic.getItem because when we are parsing, the underlying object might still be null.
      stream_length_obj = get_length(dic[Pdfbox::Cos::Name.new("Length")])
      if stream_length_obj.nil?
        if lenient?
          Log.warn do
            "The stream doesn't provide any stream length, using fallback readUntilEnd, at offset #{position}"
          end
        else
          raise ::IO::Error.new("Missing length for stream.")
        end
      end
      stream_start_position = position
      stream_length = 0_i64
      if !stream_length_obj.nil? && validate_stream_length(stream_length_obj.as(Pdfbox::Cos::Number).value.to_i64)
        stream_length = stream_length_obj.as(Pdfbox::Cos::Number).value.to_i64
        # skip stream
        seek(position + stream_length_obj.as(Pdfbox::Cos::Number).value.to_i64)
      else
        stream_length = read_until_end_stream(EndstreamFilterStream.new)
        if stream_length_obj.nil? || stream_length_obj.as(Pdfbox::Cos::Number).value.to_i64 != stream_length
          # Update length in dictionary
          dic[Pdfbox::Cos::Name.new("Length")] = Pdfbox::Cos::Integer.new(stream_length)
        end
      end
      end_stream = read_string
      if end_stream == ENDOBJ_STRING && lenient?
        Log.warn { "stream ends with 'endobj' instead of 'endstream' at offset #{position}" }
        # avoid follow-up warning about missing endobj
        source.rewind(ENDOBJ.size)
      elsif end_stream.size > 9 && lenient? && end_stream.starts_with?(ENDSTREAM_STRING)
        Log.warn { "stream ends with '#{end_stream}' instead of 'endstream' at offset #{position}" }
        # unread the "extra" bytes
        source.rewind(end_stream[9..-1].bytesize)
      elsif end_stream != ENDSTREAM_STRING
        raise ::IO::Error.new("Error reading stream, expected='endstream' actual='#{end_stream}' at offset #{position}")
      end
      # TODO: create COSStream with dictionary and position/length
      # For now, read the data and create a stream with bytes
      data_start = stream_start_position
      saved_pos = position
      seek(data_start)
      data = Bytes.new(stream_length)
      source.read(data)
      seek(saved_pos)
      Pdfbox::Cos::Stream.new(dic.entries, data)
    end

    # Parse the header of a PDF.
    # @return true if a PDF header was found
    protected def parse_pdf_header : Bool
      parse_header(PDF_HEADER, PDF_DEFAULT_VERSION)
    end

    # Parse the header of a FDF.
    # @return true if a FDF header was found
    protected def parse_fdf_header : Bool
      parse_header(FDF_HEADER, FDF_DEFAULT_VERSION)
    end

    private def parse_header(header_marker : String, default_version : String) : Bool
      # read first line
      header = read_line
      # some pdf-documents are broken and the pdf-version is in one of the following lines
      unless header.includes?(header_marker)
        header = read_line
        while !header.includes?(header_marker)
          # if a line starts with a digit, it has to be the first one with data in it
          if !header.empty? && header[0].digit?
            break
          end
          header = read_line
        end
      end

      # nothing found
      unless header.includes?(header_marker)
        source.seek(0)
        return false
      end

      # sometimes there is some garbage in the header before the header
      # actually starts, so lets try to find the header first.
      header_start = header.index(header_marker)

      # greater than zero because if it is zero then there is no point of trimming
      if header_start && header_start > 0
        # trim off any leading characters
        header = header[header_start..-1]
      end

      # This is used if there is garbage after the header on the same line
      if header.starts_with?(header_marker) && !header.matches?(/#{Regex.escape(header_marker)}\\d\\.\\d/)
        if header.size < header_marker.size + 3
          # No version number at all, set to 1.4 as default
          header = header_marker + default_version
          Log.debug { "No version found, set to #{default_version} as default." }
        else
          header_garbage = header[header_marker.size + 3..-1] + "\n"
          # put the garbage back
          source.rewind(header_garbage.bytesize)
        end
      end

      true
    end

    protected def read_object_number : Int64
      retval = read_long
      if retval < 0 || retval >= OBJECT_NUMBER_THRESHOLD
        raise ::IO::Error.new("Object Number '#{retval}' has more than 10 digits or is negative")
      end
      retval
    end

    protected def read_generation_number : Int64
      retval = read_int.to_i64
      if retval < 0 || retval > GENERATION_NUMBER_THRESHOLD
        raise ::IO::Error.new("Generation Number '#{retval}' has more than 5 digits or is negative")
      end
      retval
    end

    protected def parse_object_stream_object(objstm_obj_nr : Int64, key : Cos::ObjectKey) : Cos::Base?
      parser = @parser
      if parser
        parser.parse_object_stream_object(objstm_obj_nr, key)
      else
        raise "No parser available to parse object stream"
      end
    end

    # Get offset or object stream number for given object key
    # Returns positive value for file offset, negative for object stream number, nil if not found
    # Similar to Apache PDFBox COSParser.getObjectOffset
    private def get_object_offset(key : Cos::ObjectKey, require_existing_not_compressed_obj : Bool) : Int64?
      parser = @parser
      return unless parser

      xref = parser.xref
      return unless xref

      # Get offset for object key (new XRef structure uses ObjectKey as key)
      offset_or_objstm = xref[key]?

      # If not found with exact key, try to find entry with matching number and generation
      # but different stream_index (for backward compatibility)
      if offset_or_objstm.nil?
        xref.entries.each do |xref_key, offset|
          if xref_key.number == key.number && xref_key.generation == key.generation
            offset_or_objstm = offset
            break
          end
        end
      end

      # Try brute force search if not found and lenient
      if offset_or_objstm.nil? && parser.lenient
        bf_parser = parser.get_brute_force_parser
        bf_offsets = bf_parser.bf_cos_object_offsets
        if bf_offset = bf_offsets[key]?
          Log.debug { "Set missing offset #{bf_offset} for object #{key}" }
          # Update xref table
          xref[key] = bf_offset
          offset_or_objstm = bf_offset
        end
      end

      # Test to circumvent loops with broken documents
      if require_existing_not_compressed_obj && (offset_or_objstm.nil? || offset_or_objstm <= 0)
        raise ::IO::Error.new("Object must be defined and must not be compressed object: #{key.number}:#{key.generation}")
      end

      offset_or_objstm
    end

    # Parse file object at given offset
    # Similar to Apache PDFBox COSParser.parseFileObject
    private def parse_file_object(obj_offset : Int64, key : Cos::ObjectKey) : Cos::Base?
      # jump to the object start
      seek(obj_offset)

      # an indirect object starts with the object number/generation number
      read_obj_nr = read_object_number
      read_obj_gen = read_generation_number
      read_object_marker

      # consistency check
      if read_obj_nr != key.number || read_obj_gen != key.generation
        raise ::IO::Error.new("XREF for #{key.number}:#{key.generation} points to wrong object: #{read_obj_nr}:#{read_obj_gen} at offset #{obj_offset}")
      end

      skip_spaces
      parsed_object = parse_dir_object
      if parsed_object
        parsed_object.set_direct(false)
        parsed_object.key = key
      end

      end_object_key = read_string

      if end_object_key == STREAM_STRING
        # object is a stream
        unless parsed_object.is_a?(Pdfbox::Cos::Dictionary)
          raise ::IO::Error.new("Expected dictionary for stream at offset #{obj_offset}")
        end
        parsed_object = parse_cos_stream(parsed_object.as(Pdfbox::Cos::Dictionary))
      elsif end_object_key != ENDOBJ_STRING
        if lenient?
          Log.warn { "Object (#{key.number}:#{key.generation}) at offset #{obj_offset} does not end with 'endobj' but with '#{end_object_key}'" }
        else
          raise ::IO::Error.new("Object (#{key.number}:#{key.generation}) at offset #{obj_offset} does not end with 'endobj' but with '#{end_object_key}'")
        end
      end

      parsed_object
    end

    # Parse object dynamically (similar to Apache PDFBox COSParser.parseObjectDynamically)
    # This is the main method for resolving indirect references
    protected def parse_object_dynamically(key : Cos::ObjectKey, require_existing_not_compressed_obj : Bool) : Cos::Base?
      # Get object from pool (creates proxy if not exists)
      pdf_object = get_object_from_pool(key)

      # Check if object is already resolved
      unless pdf_object.object.nil?
        return pdf_object.object
      end

      offset_or_objstm = get_object_offset(key, require_existing_not_compressed_obj)
      referenced_object = nil

      if offset_or_objstm
        if offset_or_objstm > 0
          referenced_object = parse_file_object(offset_or_objstm, key)
        else
          # xref value is object nr of object stream containing object to be parsed
          # since our object was not found it means object stream was not parsed so far
          referenced_object = parse_object_stream_object(-offset_or_objstm, key)
        end
      end

      if referenced_object.nil? || referenced_object.is_a?(Cos::Null)
        # not defined object -> NULL object (Spec. 1.7, chap. 3.2.9)
        # or some other issue with dereferencing
        # remove parser to avoid endless recursion
        pdf_object.object = Cos::Null.instance
      end

      referenced_object
    end

    # Read object marker ('obj')
    private def read_object_marker : Nil
      skip_spaces
      read_expected_char('o')
      read_expected_char('b')
      read_expected_char('j')
      skip_spaces
    end
  end
end

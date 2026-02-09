require "../../pdfbox/io"

module Fontbox
  module CMap
    class CMapParser
      private MARK_END_OF_DICTIONARY = ">>"
      private MARK_END_OF_ARRAY      = "]"

      private alias Token = String | Bytes | Int32 | Float64 | LiteralName | Operator | Array(Token) | Hash(String, Token)

      @strict_mode : Bool
      @token_parser_byte_buffer : Bytes

      def initialize(strict_mode : Bool = false)
        @strict_mode = strict_mode
        @token_parser_byte_buffer = Bytes.new(512)
      end

      # Forward declarations
      private def parse_next_token(random_access_read : Pdfbox::IO::RandomAccessRead) : Token?; end

      private def parse_integer(random_access_read : Pdfbox::IO::RandomAccessRead) : Int32; end

      private def parse_byte_array(random_access_read : Pdfbox::IO::RandomAccessRead) : Bytes; end

      private def read_array(random_access_read : Pdfbox::IO::RandomAccessRead) : Array(Token); end

      private def read_string(random_access_read : Pdfbox::IO::RandomAccessRead) : String; end

      private def read_line(random_access_read : Pdfbox::IO::RandomAccessRead, first_byte : UInt8) : String; end

      private def read_literal_name(random_access_read : Pdfbox::IO::RandomAccessRead) : LiteralName; end

      private def read_operator(random_access_read : Pdfbox::IO::RandomAccessRead, first_byte : UInt8) : Operator; end

      private def read_number(random_access_read : Pdfbox::IO::RandomAccessRead, first_byte : UInt8) : Number; end

      private def read_dictionary(random_access_read : Pdfbox::IO::RandomAccessRead) : Hash(String, Token) | Bytes; end

      private def read_until_end_of_line(random_access_read : Pdfbox::IO::RandomAccessRead, buf : String::Builder); end

      private def parse_usecmap(use_cmap_name : LiteralName, result : CMap); end

      private def parse_literal_name(literal : LiteralName, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap); end

      private def parse_begincodespacerange(cos_count : Number, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap); end

      private def parse_beginbfchar(cos_count : Number, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap); end

      private def parse_begincidrange(number_of_lines : Int32, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap); end

      private def parse_begincidchar(cos_count : Number, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap); end

      private def parse_beginbfrange(cos_count : Number, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap); end

      private def add_mapping_from_bfrange(cmap : CMap, start_code : Bytes, token_bytes_list : Array); end

      private def add_mapping_from_bfrange(cmap : CMap, start_code : Bytes, values : Int32, token_bytes : Bytes); end

      private def get_external_cmap(name : String) : Pdfbox::IO::RandomAccessRead; end

      private def check_expected_operator(operator : Operator, expected_operator_name : String, range_name : String); end

      private def create_string_from_bytes(bytes : Bytes) : String; end

      private def increment(data : Bytes, position : Int32, use_strict_mode : Bool) : Bool; end

      private def is_whitespace_or_eof(a_byte : UInt8?) : Bool; end

      private def is_delimiter(a_byte : UInt8?) : Bool; end

      def parse_predefined(name : String) : CMap
        random_access_read = get_external_cmap(name)
        # deactivate strict mode
        strict_mode = @strict_mode
        @strict_mode = false
        begin
          parse(random_access_read)
        ensure
          @strict_mode = strict_mode
          random_access_read.close
        end
      end

      def parse(random_access_read : Pdfbox::IO::RandomAccessRead) : CMap
        result = CMap.new
        previous_token = nil
        token = parse_next_token(random_access_read)
        while token
          if token.is_a?(Operator)
            op = token.as(Operator)
            if op.op == "endcmap"
              break
            end

            if op.op == "usecmap" && previous_token.is_a?(LiteralName)
              parse_usecmap(previous_token.as(LiteralName), result)
            elsif previous_token.is_a?(Number)
              number = previous_token.as(Number)
              if op.op == "begincodespacerange"
                parse_begincodespacerange(number, random_access_read, result)
              elsif op.op == "beginbfchar"
                parse_beginbfchar(number, random_access_read, result)
              elsif op.op == "beginbfrange"
                parse_beginbfrange(number, random_access_read, result)
              elsif op.op == "begincidchar"
                parse_begincidchar(number, random_access_read, result)
              elsif op.op == "begincidrange" && previous_token.is_a?(Int32)
                parse_begincidrange(previous_token.as(Int32), random_access_read, result)
              end
            end
          elsif token.is_a?(LiteralName)
            parse_literal_name(token.as(LiteralName), random_access_read, result)
          end
          previous_token = token
          token = parse_next_token(random_access_read)
        end
        result
      end

      private def parse_usecmap(use_cmap_name : LiteralName, result : CMap)
        random_access_read = get_external_cmap(use_cmap_name.name)
        use_cmap = parse(random_access_read)
        result.use_cmap(use_cmap)
        random_access_read.close
      end

      private def parse_literal_name(literal : LiteralName, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap)
        case literal.name
        when "WMode"
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Int32)
            result.wmode = next_token
          end
        when "CMapName"
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(LiteralName)
            result.name = next_token.as(LiteralName).name
          end
        when "CMapVersion"
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Number)
            result.version = next_token.to_s
          elsif next_token.is_a?(String)
            result.version = next_token.as(String)
          end
        when "CMapType"
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Int32)
            result.type = next_token
          end
        when "Registry"
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(String)
            result.registry = next_token
          end
        when "Ordering"
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(String)
            result.ordering = next_token
          end
        when "Supplement"
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Int32)
            result.supplement = next_token
          end
        end
      end

      private def check_expected_operator(operator : Operator, expected_operator_name : String, range_name : String)
        unless operator.op == expected_operator_name
          raise "Error : ~#{range_name} contains an unexpected operator : #{operator.op}"
        end
      end

      private def parse_begincodespacerange(cos_count : Number, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap)
        cos_count.to_i.times do |_|
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Operator)
            check_expected_operator(next_token.as(Operator), "endcodespacerange", "codespacerange")
            break
          end
          unless next_token.is_a?(Bytes)
            raise "start range missing"
          end
          start_range = next_token.as(Bytes)
          end_range = parse_byte_array(random_access_read)
          begin
            result.add_codespace_range(CodespaceRange.new(start_range, end_range))
          rescue ex : ArgumentError
            raise ex
          end
        end
      end

      private def parse_beginbfchar(cos_count : Number, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap)
        cos_count.to_i.times do |_|
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Operator)
            check_expected_operator(next_token.as(Operator), "endbfchar", "bfchar")
            break
          end
          unless next_token.is_a?(Bytes)
            raise "input code missing"
          end
          input_code = next_token.as(Bytes)
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Bytes)
            bytes = next_token.as(Bytes)
            value = create_string_from_bytes(bytes)
            result.add_char_mapping(input_code, value)
          elsif next_token.is_a?(LiteralName)
            result.add_char_mapping(input_code, next_token.as(LiteralName).name)
          else
            raise "Error parsing CMap beginbfchar, expected{Bytes or LiteralName} and not #{next_token.class}"
          end
        end
      end

      private def parse_begincidrange(number_of_lines : Int32, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap)
        number_of_lines.times do |_|
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Operator)
            check_expected_operator(next_token.as(Operator), "endcidrange", "cidrange")
            break
          end
          unless next_token.is_a?(Bytes)
            raise "start code missing"
          end
          start_code = next_token.as(Bytes)
          end_code = parse_byte_array(random_access_read)
          mapped_code = parse_integer(random_access_read)
          if start_code.size == end_code.size
            if start_code == end_code
              result.add_cid_mapping(start_code, mapped_code)
            else
              result.add_cid_range(start_code, end_code, mapped_code)
            end
          else
            raise "Error : ~cidrange values must not have different byte lengths"
          end
        end
      end

      private def parse_begincidchar(cos_count : Number, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap)
        cos_count.to_i.times do |_|
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Operator)
            check_expected_operator(next_token.as(Operator), "endcidchar", "cidchar")
            break
          end
          unless next_token.is_a?(Bytes)
            raise "input code missing"
          end
          input_code = next_token.as(Bytes)
          mapped_cid = parse_integer(random_access_read)
          result.add_cid_mapping(input_code, mapped_cid)
        end
      end

      private def parse_beginbfrange(cos_count : Number, random_access_read : Pdfbox::IO::RandomAccessRead, result : CMap)
        cos_count.to_i.times do |_|
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Operator)
            check_expected_operator(next_token.as(Operator), "endbfrange", "bfrange")
            break
          end
          unless next_token.is_a?(Bytes)
            raise "start code missing"
          end
          start_code = next_token.as(Bytes)
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Operator)
            check_expected_operator(next_token.as(Operator), "endbfrange", "bfrange")
            break
          end
          unless next_token.is_a?(Bytes)
            raise "end code missing"
          end
          end_code = next_token.as(Bytes)
          start = CMap.to_int(start_code)
          ending = CMap.to_int(end_code)
          # end has to be bigger than start or equal
          if ending < start
            # PDFBOX-4550: likely corrupt stream
            break
          end
          next_token = parse_next_token(random_access_read)
          if next_token.is_a?(Array)
            array = next_token.as(Array)
            # ignore empty and malformed arrays
            if !array.empty? && array.size >= ending - start
              add_mapping_from_bfrange(result, start_code, array)
            end
          elsif next_token.is_a?(Bytes)
            token_bytes = next_token.as(Bytes)
            if token_bytes.size > 0
              # PDFBOX-4720:
              # some pdfs use the malformed bfrange <0000> <FFFF> <0000>. Add support by adding a identity
              # mapping for the whole range instead of cutting it after 255 entries
              # TODO find a more efficient method to represent all values for a identity mapping
              if token_bytes.size == 2 && start == 0 && ending == 0xffff && token_bytes[0] == 0 && token_bytes[1] == 0
                256.times do |i|
                  start_code[0] = i.to_u8
                  start_code[1] = 0_u8
                  token_bytes[0] = i.to_u8
                  token_bytes[1] = 0_u8
                  add_mapping_from_bfrange(result, start_code, 256, token_bytes)
                end
              else
                add_mapping_from_bfrange(result, start_code, ending - start + 1, token_bytes)
              end
            end
          end
        end
      end

      private def add_mapping_from_bfrange(cmap : CMap, start_code : Bytes, token_bytes_list : Array)
        token_bytes_list.each do |token_bytes|
          value = create_string_from_bytes(token_bytes.as(Bytes))
          cmap.add_char_mapping(start_code, value)
          increment(start_code, start_code.size - 1, false)
        end
      end

      private def add_mapping_from_bfrange(cmap : CMap, start_code : Bytes, values : Int32, token_bytes : Bytes)
        values.times do |_|
          value = create_string_from_bytes(token_bytes)
          cmap.add_char_mapping(start_code, value)
          unless increment(token_bytes, token_bytes.size - 1, @strict_mode)
            # overflow detected -> stop adding further mappings
            break
          end
          increment(start_code, start_code.size - 1, false)
        end
      end

      private def get_external_cmap(name : String) : Pdfbox::IO::RandomAccessRead
        # Try to load from resources directory relative to project root
        resource_path = File.join(Dir.current, "resources", "org", "apache", "fontbox", "cmap", name)
        unless File.exists?(resource_path)
          # Try relative to source file
          resource_path = File.join(__DIR__, "../../../../resources/org/apache/fontbox/cmap", name)
        end
        unless File.exists?(resource_path)
          raise "Error: Could not find referenced cmap stream #{name}"
        end
        data = File.read(resource_path).to_slice
        Pdfbox::IO::MemoryRandomAccessRead.new(data)
      end

      private def parse_next_token(random_access_read : Pdfbox::IO::RandomAccessRead)
        next_byte = random_access_read.read
        # skip whitespace
        while next_byte == 0x09 || next_byte == 0x20 || next_byte == 0x0D || next_byte == 0x0A
          next_byte = random_access_read.read
        end
        case next_byte
        when nil
          # EOF returning nil
          nil
        when '%'.ord
          read_line(random_access_read, next_byte.as(UInt8))
        when '('.ord
          read_string(random_access_read)
        when '>'.ord
          if random_access_read.read == '>'.ord
            MARK_END_OF_DICTIONARY
          else
            raise "Error: expected the end of a dictionary."
          end
        when ']'.ord
          MARK_END_OF_ARRAY
        when '['.ord
          read_array(random_access_read)
        when '<'.ord
          read_dictionary(random_access_read)
        when '/'.ord
          read_literal_name(random_access_read)
        when '0'.ord, '1'.ord, '2'.ord, '3'.ord, '4'.ord, '5'.ord, '6'.ord, '7'.ord, '8'.ord, '9'.ord
          read_number(random_access_read, next_byte.as(UInt8))
        else
          read_operator(random_access_read, next_byte.as(UInt8))
        end
      end

      private def parse_integer(random_access_read : Pdfbox::IO::RandomAccessRead) : Int32
        next_token = parse_next_token(random_access_read)
        raise "expected integer value is missing" if next_token.nil?
        if next_token.is_a?(Int32)
          return next_token
        end
        raise "invalid type for next token"
      end

      private def parse_byte_array(random_access_read : Pdfbox::IO::RandomAccessRead) : Bytes
        next_token = parse_next_token(random_access_read)
        raise "expected byte[] value is missing" if next_token.nil?
        if next_token.is_a?(Bytes)
          return next_token
        end
        raise "invalid type for next token"
      end

      private def read_array(random_access_read : Pdfbox::IO::RandomAccessRead) : Array(Token)
        list = [] of Token
        next_token = parse_next_token(random_access_read)
        while next_token && next_token != MARK_END_OF_ARRAY
          list << next_token.as(Token)
          next_token = parse_next_token(random_access_read)
        end
        list
      end

      private def read_string(random_access_read : Pdfbox::IO::RandomAccessRead) : String
        buffer = String::Builder.new
        string_byte = random_access_read.read
        while !string_byte.nil? && string_byte != ')'.ord
          buffer << string_byte.chr
          string_byte = random_access_read.read
        end
        buffer.to_s
      end

      private def read_line(random_access_read : Pdfbox::IO::RandomAccessRead, first_byte : UInt8) : String
        next_byte = first_byte
        buffer = String::Builder.new
        buffer << next_byte.chr
        read_until_end_of_line(random_access_read, buffer)
        buffer.to_s
      end

      private def read_literal_name(random_access_read : Pdfbox::IO::RandomAccessRead) : LiteralName
        buffer = String::Builder.new
        string_byte = random_access_read.read
        while !is_whitespace_or_eof(string_byte) && !is_delimiter(string_byte)
          buffer << string_byte.as(UInt8).chr
          string_byte = random_access_read.read
        end
        if is_delimiter(string_byte)
          random_access_read.rewind(1)
        end
        LiteralName.new(buffer.to_s)
      end

      private def read_operator(random_access_read : Pdfbox::IO::RandomAccessRead, first_byte : UInt8) : Operator
        next_byte = first_byte
        buffer = String::Builder.new
        buffer << next_byte.chr
        next_byte = random_access_read.read
        # newline separator may be missing in malformed CMap files
        # see PDFBOX-2035
        while !is_whitespace_or_eof(next_byte) && !is_delimiter(next_byte) && (!next_byte.nil? && !next_byte.as(UInt8).chr.ascii_number?)
          buffer << next_byte.as(UInt8).chr
          next_byte = random_access_read.read
        end
        if !next_byte.nil? && (is_delimiter(next_byte) || next_byte.chr.ascii_number?)
          random_access_read.rewind(1)
        end
        Operator.new(buffer.to_s)
      end

      private def read_number(random_access_read : Pdfbox::IO::RandomAccessRead, first_byte : UInt8) : Number
        next_byte = first_byte
        buffer = String::Builder.new
        buffer << next_byte.chr
        next_byte = random_access_read.read
        while !is_whitespace_or_eof(next_byte) && (!next_byte.nil? && (next_byte.as(UInt8).chr.ascii_number? || next_byte == '.'.ord))
          buffer << next_byte.as(UInt8).chr
          next_byte = random_access_read.read
        end
        unless next_byte.nil?
          random_access_read.rewind(1)
        end
        value = buffer.to_s
        if value.includes?('.')
          value.to_f
        else
          value.to_i
        end
      rescue ex : ArgumentError
        raise "Invalid number '#{value}'"
      end

      private def read_dictionary(random_access_read : Pdfbox::IO::RandomAccessRead)
        the_next_byte = random_access_read.read
        if the_next_byte == '<'.ord
          result = {} of String => Token
          key = parse_next_token(random_access_read)
          while key.is_a?(LiteralName) && key.as(LiteralName).name != MARK_END_OF_DICTIONARY
            value = parse_next_token(random_access_read)
            raise "Unexpected EOF" if value.nil?
            result[key.as(LiteralName).name] = value.as(Token)
            key = parse_next_token(random_access_read)
          end
          result
        else
          multiplier = 16
          buffer_index = -1
          while !the_next_byte.nil? && the_next_byte != '>'.ord
            # all kind of whitespaces may occur in malformed CMap files
            # see PDFBOX-2035
            if is_whitespace_or_eof(the_next_byte)
              # skipping whitespaces
              the_next_byte = random_access_read.read
              next
            end
            int_value = 0
            if the_next_byte >= '0'.ord && the_next_byte <= '9'.ord
              int_value = the_next_byte - '0'.ord
            elsif the_next_byte >= 'A'.ord && the_next_byte <= 'F'.ord
              int_value = 10 + the_next_byte - 'A'.ord
            elsif the_next_byte >= 'a'.ord && the_next_byte <= 'f'.ord
              int_value = 10 + the_next_byte - 'a'.ord
            else
              raise "Error: expected hex character and not #{the_next_byte.chr}:#{the_next_byte}"
            end
            int_value *= multiplier
            if multiplier == 16
              buffer_index += 1
              if buffer_index >= @token_parser_byte_buffer.size
                raise "cmap token is larger than buffer size #{@token_parser_byte_buffer.size}"
              end
              @token_parser_byte_buffer[buffer_index] = 0_u8
              multiplier = 1
            else
              multiplier = 16
            end
            @token_parser_byte_buffer[buffer_index] += int_value.to_u8
            the_next_byte = random_access_read.read
          end
          final_result = Bytes.new(buffer_index + 1)
          final_result.copy_from(@token_parser_byte_buffer[0, buffer_index + 1])
          final_result
        end
      end

      private def read_until_end_of_line(random_access_read : Pdfbox::IO::RandomAccessRead, buf : String::Builder)
        next_byte = random_access_read.read
        while !next_byte.nil? && next_byte != 0x0D && next_byte != 0x0A
          buf << next_byte.chr
          next_byte = random_access_read.read
        end
      end

      private def is_whitespace_or_eof(a_byte : UInt8?) : Bool
        case a_byte
        when nil, 0x20, 0x0D, 0x0A
          true
        else
          false
        end
      end

      private def is_delimiter(a_byte : UInt8?) : Bool
        case a_byte
        when '('.ord, ')'.ord, '<'.ord, '>'.ord, '['.ord, ']'.ord, '{'.ord, '}'.ord, '/'.ord, '%'.ord
          true
        else
          false
        end
      end

      private def increment(data : Bytes, position : Int32, use_strict_mode : Bool) : Bool
        if position > 0 && (data[position] & 0xFF) == 255
          # PDFBOX-4661: avoid overflow of the last byte, all following values are undefined
          # PDFBOX-5090: strict mode has to be used for CMaps within pdfs
          if use_strict_mode
            return false
          end
          data[position] = 0_u8
          increment(data, position - 1, use_strict_mode)
        else
          data[position] = (data[position] + 1).to_u8
        end
        true
      end

      private def create_string_from_bytes(bytes : Bytes) : String
        if bytes.size <= 2
          CMapStrings.get_mapping(bytes) || ""
        else
          String.new(bytes, "UTF-16BE")
        end
      end

      # Internal classes
      private class LiteralName
        getter name : String

        def initialize(@name : String)
        end
      end

      private class Operator
        getter op : String

        def initialize(@op : String)
        end
      end

      # Union type for Number
      alias Number = Int32 | Float64
    end
  end
end

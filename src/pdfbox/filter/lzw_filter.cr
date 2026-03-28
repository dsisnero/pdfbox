module Pdfbox::Filter
  class LZWFilter < Filter
    CLEAR_TABLE = 256
    EOD         = 257

    def decode(encoded : Bytes) : Bytes
      code_table = create_code_table
      chunk = 9
      reader = BitReader.new(encoded)
      prev = nil.as(Bytes?)
      output = ::IO::Memory.new

      begin
        while (next_command = reader.read_bits(chunk)) != EOD
          if next_command == CLEAR_TABLE
            chunk = 9
            code_table = create_code_table
            prev = nil
            next
          end

          curr = nil.as(Bytes?)
          if next_command < code_table.size
            curr = code_table[next_command]
            raise ::IO::EOFError.new("Invalid LZW code: #{next_command}") unless curr
            output.write(curr)

            if previous = prev
              entry = Bytes.new(previous.size + 1)
              entry.copy_from(previous)
              entry[previous.size] = curr[0]
              code_table << entry
            end
          elsif next_command == code_table.size && (previous = prev)
            entry = Bytes.new(previous.size + 1)
            entry.copy_from(previous)
            entry[previous.size] = previous[0]
            output.write(entry)
            code_table << entry
            curr = entry
          else
            raise ::IO::EOFError.new("Invalid LZW code: #{next_command}")
          end

          prev = curr
          chunk = calculate_chunk(code_table.size, true)
        end
      rescue ::IO::EOFError
        # Java parity: tolerate premature EOF and return decoded prefix.
      end

      output.to_slice
    end

    def encode(input : Bytes) : Bytes
      code_table = create_code_table
      code_lookup = create_code_lookup
      chunk = 9
      writer = BitWriter.new

      writer.write_bits(CLEAR_TABLE, chunk)
      found_code = -1
      pattern = [] of UInt8

      input.each do |byte|
        if pattern.empty?
          pattern << byte
          found_code = byte.to_i
        else
          pattern << byte
          new_found_code = find_pattern_code(code_lookup, pattern)
          if new_found_code == -1
            chunk = calculate_chunk(code_table.size - 1, true)
            writer.write_bits(found_code, chunk)
            bytes_pattern = bytes_from(pattern)
            code_table << bytes_pattern
            code_lookup[bytes_pattern] = code_table.size - 1

            if code_table.size == 4096
              writer.write_bits(CLEAR_TABLE, chunk)
              code_table = create_code_table
              code_lookup = create_code_lookup
            end

            pattern = [byte]
            found_code = byte.to_i
          else
            found_code = new_found_code
          end
        end
      end

      if found_code != -1
        chunk = calculate_chunk(code_table.size - 1, true)
        writer.write_bits(found_code, chunk)
      end

      # Java parity (PDFBOX-1977): behave as if table had just grown before EOD.
      chunk = calculate_chunk(code_table.size, true)
      writer.write_bits(EOD, chunk)
      writer.write_bits(0, 7) # pad with 0

      writer.to_slice
    end

    private def create_code_table : Array(Bytes?)
      code_table = Array(Bytes?).new(258)
      256.times do |i|
        code_table << Bytes[i.to_u8]
      end
      code_table << nil # 256
      code_table << nil # 257
      code_table
    end

    private def create_code_lookup : Hash(Bytes, Int32)
      code_lookup = {} of Bytes => Int32
      256.times do |i|
        key = Bytes[i.to_u8]
        code_lookup[key] = i
      end
      code_lookup
    end

    private def find_pattern_code(code_lookup : Hash(Bytes, Int32), pattern : Array(UInt8)) : Int32
      return pattern[0].to_i if pattern.size == 1

      bytes_pattern = bytes_from(pattern)
      code_lookup[bytes_pattern]? || -1
    end

    private def calculate_chunk(tab_size : Int32, early_change : Bool) : Int32
      i = tab_size + (early_change ? 1 : 0)
      return 12 if i >= 2048
      return 11 if i >= 1024
      return 10 if i >= 512
      9
    end

    private def bytes_from(array : Array(UInt8)) : Bytes
      Bytes.new(array.size) { |i| array[i] }
    end

    private class BitReader
      @data : Bytes
      @index = 0
      @bit_buffer = 0_u64
      @buffer_bits = 0

      def initialize(@data : Bytes)
      end

      def read_bits(count : Int32) : Int32
        while @buffer_bits < count
          raise ::IO::EOFError.new("Unexpected EOF in bit stream") if @index >= @data.size
          @bit_buffer = (@bit_buffer << 8) | @data[@index].to_u64
          @index += 1
          @buffer_bits += 8
        end

        shift = @buffer_bits - count
        result = ((@bit_buffer >> shift) & ((1_u64 << count) - 1)).to_i32
        @bit_buffer &= ((1_u64 << shift) - 1)
        @buffer_bits = shift
        result
      end
    end

    private class BitWriter
      @bytes = [] of UInt8
      @bit_buffer = 0_u64
      @buffer_bits = 0

      def write_bits(value : Int32, count : Int32) : Nil
        @bit_buffer = (@bit_buffer << count) | (value.to_u64 & ((1_u64 << count) - 1))
        @buffer_bits += count
        while @buffer_bits >= 8
          shift = @buffer_bits - 8
          @bytes << ((@bit_buffer >> shift) & 0xFF).to_u8
          @bit_buffer &= ((1_u64 << shift) - 1)
          @buffer_bits = shift
        end
      end

      def to_slice : Bytes
        if @buffer_bits > 0
          @bytes << ((@bit_buffer << (8 - @buffer_bits)) & 0xFF).to_u8
          @bit_buffer = 0_u64
          @buffer_bits = 0
        end
        Bytes.new(@bytes.size) { |i| @bytes[i] }
      end
    end
  end
end

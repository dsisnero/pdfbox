# CCITT Modified Huffman RLE, Group 3 (T4) and Group 4 (T6) fax decoding.
# Java: org.apache.pdfbox.filter.CCITTFaxDecoderStream
module Pdfbox::Filter
  class CCITTFaxDecoderStream
    VALUE_EOL      = -2000
    VALUE_FILL     = -1000
    VALUE_PASSMODE = -3000
    VALUE_HMODE    = -4000

    @columns : Int32
    @decoded_row : Bytes
    @option_g32d : Bool
    @option_g3_fill : Bool
    @option_uncompressed : Bool
    @option_byte_aligned : Bool
    @type : Int32

    @decoded_length : Int32
    @decoded_pos : Int32

    @changes_reference_row : Array(Int32)
    @changes_current_row : Array(Int32)
    @changes_reference_row_count : Int32
    @changes_current_row_count : Int32
    @last_changing_element : Int32

    @buffer : Int32
    @buffer_pos : Int32

    @source : ::IO

    def initialize(source : ::IO, columns : Int32, type : Int32, options : Int64, byte_aligned : Bool)
      @source = source
      @columns = columns
      @type = type
      @buffer = -1
      @buffer_pos = -1

      @decoded_row = Bytes.new((columns + 7) // 8)
      @changes_reference_row = Array.new(columns + 2, 0)
      @changes_current_row = Array.new(columns + 2, 0)
      @last_changing_element = 0
      @decoded_length = 0
      @decoded_pos = 0
      @changes_reference_row_count = 0
      @changes_current_row_count = 0

      case type
      when TIFFExtension::COMPRESSION_CCITT_MODIFIED_HUFFMAN_RLE
        @option_byte_aligned = byte_aligned
        @option_g32d = false
        @option_g3_fill = false
        @option_uncompressed = false
      when TIFFExtension::COMPRESSION_CCITT_T4
        @option_byte_aligned = byte_aligned
        @option_g32d = (options & TIFFExtension::GROUP3OPT_2DENCODING) != 0
        @option_g3_fill = (options & TIFFExtension::GROUP3OPT_FILLBITS) != 0
        @option_uncompressed = (options & TIFFExtension::GROUP3OPT_UNCOMPRESSED) != 0
      when TIFFExtension::COMPRESSION_CCITT_T6
        @option_byte_aligned = byte_aligned
        @option_g32d = false
        @option_g3_fill = false
        @option_uncompressed = (options & TIFFExtension::GROUP4OPT_UNCOMPRESSED) != 0
      else
        raise ::ArgumentError.new("Illegal parameter: #{type}")
      end
    end

    # Reads the next decoded byte, or 0 when the stream is exhausted.
    def read_byte : Int32
      return 0 if @decoded_length < 0

      if @decoded_pos >= @decoded_length
        fetch
        return 0 if @decoded_length < 0
      end

      result = @decoded_row[@decoded_pos].to_i32 & 0xff
      @decoded_pos += 1
      result
    end

    private def fetch : Nil
      if @decoded_pos >= @decoded_length
        @decoded_length = 0

        begin
          decode_row
        rescue ex : ::IO::EOFError
          if @decoded_length != 0
            raise ex
          end
          @decoded_length = -1
        end

        @decoded_pos = 0
      end
    end

    private def decode_1d : Nil
      index = 0
      white = true
      @changes_current_row_count = 0

      loop do
        complete_run = if white
                         decode_run(WHITE_RUN_TREE)
                       else
                         decode_run(BLACK_RUN_TREE)
                       end

        index += complete_run
        @changes_current_row[@changes_current_row_count] = index
        @changes_current_row_count += 1

        white = !white
        break if index >= @columns
      end
    end

    private def decode_2d : Nil
      @changes_reference_row_count = @changes_current_row_count
      tmp = @changes_current_row
      @changes_current_row = @changes_reference_row
      @changes_reference_row = tmp

      white = true
      index = 0
      @changes_current_row_count = 0

      while index < @columns
        n = CODE_TREE.root

        loop do
          n = n.walk(read_bit)

          if n.nil?
            break
          elsif n.leaf?
            case n.value
            when VALUE_HMODE
              run_length = decode_run(white ? WHITE_RUN_TREE : BLACK_RUN_TREE)
              index += run_length
              @changes_current_row[@changes_current_row_count] = index
              @changes_current_row_count += 1

              run_length = decode_run(white ? BLACK_RUN_TREE : WHITE_RUN_TREE)
              index += run_length
              @changes_current_row[@changes_current_row_count] = index
              @changes_current_row_count += 1
            when VALUE_PASSMODE
              p_changing_element = get_next_changing_element(index, white) + 1

              if p_changing_element >= @changes_reference_row_count
                index = @columns
              else
                index = @changes_reference_row[p_changing_element]
              end
            else
              # Vertical mode (-3 to 3)
              v_changing_element = get_next_changing_element(index, white)

              if v_changing_element >= @changes_reference_row_count || v_changing_element == -1
                index = @columns + n.value
              else
                index = @changes_reference_row[v_changing_element] + n.value
              end

              @changes_current_row[@changes_current_row_count] = index
              @changes_current_row_count += 1
              white = !white
            end
            break
          end
        end
      end
    end

    private def get_next_changing_element(a0 : Int32, white : Bool) : Int32
      start = (@last_changing_element & 0xFFFF_FFFE) + (white ? 0 : 1)
      start -= 2 if start > 2

      return start if a0 == 0

      i = start
      while i < @changes_reference_row_count
        if a0 < @changes_reference_row[i]
          @last_changing_element = i
          return i
        end
        i += 2
      end

      -1
    end

    private def decode_row_type_2 : Nil
      reset_buffer if @option_byte_aligned
      decode_1d
    end

    private def decode_row_type_4 : Nil
      reset_buffer if @option_byte_aligned

      # read till next EOL code
      loop do
        n = EOL_ONLY_TREE.root
        loop do
          n = n.walk(read_bit)
          break if n.nil?
          break if n.leaf?
        end
        break if n.try(&.leaf?)
      end

      if !@option_g32d || read_bit
        decode_1d
      else
        decode_2d
      end
    end

    private def decode_row_type_6 : Nil
      reset_buffer if @option_byte_aligned
      decode_2d
    end

    private def decode_row : Nil
      case @type
      when TIFFExtension::COMPRESSION_CCITT_MODIFIED_HUFFMAN_RLE
        decode_row_type_2
      when TIFFExtension::COMPRESSION_CCITT_T4
        decode_row_type_4
      when TIFFExtension::COMPRESSION_CCITT_T6
        decode_row_type_6
      else
        raise ::ArgumentError.new("Illegal parameter: #{@type}")
      end

      @decoded_row.fill(0_u8)

      index = 0
      white = true
      @last_changing_element = 0

      i = 0
      while i <= @changes_current_row_count
        next_change = @columns
        if i != @changes_current_row_count
          next_change = @changes_current_row[i]
        end

        next_change = @columns if next_change > @columns

        byte_index = index // 8

        while index % 8 != 0 && (next_change - index) > 0
          @decoded_row[byte_index] |= (white ? 0_u8 : (1_u8 << (7 - (index % 8))))
          index += 1
        end

        if index % 8 == 0
          byte_index = index // 8
          value = (white ? 0x00_u8 : 0xff_u8)

          while (next_change - index) > 7
            @decoded_row[byte_index] = value
            index += 8
            byte_index += 1
          end
        end

        while (next_change - index) > 0
          @decoded_row[byte_index] = 0_u8 if index % 8 == 0
          @decoded_row[byte_index] |= (white ? 0_u8 : (1_u8 << (7 - (index % 8))))
          index += 1
        end

        white = !white
        i += 1
      end

      raise ::IO::Error.new("Sum of run-lengths does not equal scan line width: #{index} > #{@columns}") if index != @columns

      @decoded_length = (index + 7) // 8
    end

    private def decode_run(tree : Tree) : Int32
      total = 0
      n = tree.root

      loop do
        bit = read_bit
        n = n.walk(bit)

        raise ::IO::Error.new("Unknown code in Huffman RLE stream") if n.nil?

        if n.leaf?
          total += n.value
          if n.value >= 64
            n = tree.root
          elsif n.value >= 0
            return total
          else
            return @columns
          end
        end
      end
    end

    private def reset_buffer : Nil
      @buffer_pos = -1
    end

    private def read_bit : Bool
      if @buffer_pos < 0 || @buffer_pos > 7
        byte = @source.read_byte
        @buffer = byte ? byte.to_i32 : -1

        raise ::IO::EOFError.new("Unexpected end of Huffman RLE stream") if @buffer == -1

        @buffer_pos = 0
      end

      is_set = (@buffer & 0x80) != 0
      @buffer <<= 1
      @buffer_pos += 1

      is_set
    end

    # Huffman tree node.
    private class Node
      property left : Node?
      property right : Node?
      property value : Int32
      property? can_be_fill : Bool
      property? leaf : Bool

      def initialize
        @left = nil
        @right = nil
        @value = 0
        @can_be_fill = false
        @leaf = false
      end

      def set(next_ : Bool, node : Node) : Nil
        if !next_
          @left = node
        else
          @right = node
        end
      end

      def walk(next_ : Bool) : Node?
        next_ ? @right : @left
      end

      def leaf? : Bool
        @leaf
      end
    end

    # Huffman decode tree.
    private class Tree
      getter root : Node

      def initialize
        @root = Node.new
      end

      def fill(depth : Int32, path : Int32, value : Int32) : Nil
        current = @root

        depth.times do |i|
          bit_pos = depth - 1 - i
          is_set = ((path >> bit_pos) & 1) == 1
          next_ = current.walk(is_set)

          if next_.nil?
            next_ = Node.new

            if i == depth - 1
              next_.value = value
              next_.leaf = true
            end

            if path == 0
              next_.can_be_fill = true
            end

            current.set(is_set, next_)
          else
            raise ::IO::Error.new("node is leaf, no other following") if next_.leaf?
          end

          current = next_
        end
      end

      def fill(depth : Int32, path : Int32, node : Node) : Nil
        current = @root

        depth.times do |i|
          bit_pos = depth - 1 - i
          is_set = ((path >> bit_pos) & 1) == 1
          next_ = current.walk(is_set)

          if next_.nil?
            if i == depth - 1
              next_ = node
            else
              next_ = Node.new
            end

            if path == 0
              next_.can_be_fill = true
            end

            current.set(is_set, next_)
          else
            raise ::IO::Error.new("node is leaf, no other following") if next_.leaf?
          end

          current = next_
        end
      end
    end
  end
end

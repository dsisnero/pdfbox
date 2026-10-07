# CCITT Modified Group 4 (T.6) fax encoding.
# Java: org.apache.pdfbox.filter.CCITTFaxEncoderStream
#
# A faithful port of the T.6 2D encoder: each input row is run-length analysed
# into changing elements, then coded relative to the previous reference row with
# pass / horizontal / vertical modes. The Huffman run-length codes are derived
# from the decoder tables (WHITE_CODES/BLACK_CODES) exactly as Java does.
module Pdfbox::Filter
  class CCITTFaxEncoderStream
    record Code, code : Int32, length : Int32

    WHITE_TERMINATING_CODES = begin
      codes = Array(Code).new(64) { Code.new(0, 0) }
      CCITTFaxDecoderStream::WHITE_CODES.each_with_index do |row, i|
        bit_length = i + 4
        row.each_with_index do |code, j|
          value = CCITTFaxDecoderStream::WHITE_RUN_LENGTHS[i][j]
          codes[value] = Code.new(code, bit_length) if value < 64
        end
      end
      codes
    end

    WHITE_NONTERMINATING_CODES = begin
      codes = Array(Code).new(40) { Code.new(0, 0) }
      CCITTFaxDecoderStream::WHITE_CODES.each_with_index do |row, i|
        bit_length = i + 4
        row.each_with_index do |code, j|
          value = CCITTFaxDecoderStream::WHITE_RUN_LENGTHS[i][j]
          codes[(value // 64) - 1] = Code.new(code, bit_length) if value >= 64
        end
      end
      codes
    end

    BLACK_TERMINATING_CODES = begin
      codes = Array(Code).new(64) { Code.new(0, 0) }
      CCITTFaxDecoderStream::BLACK_CODES.each_with_index do |row, i|
        bit_length = i + 2
        row.each_with_index do |code, j|
          value = CCITTFaxDecoderStream::BLACK_RUN_LENGTHS[i][j]
          codes[value] = Code.new(code, bit_length) if value < 64
        end
      end
      codes
    end

    BLACK_NONTERMINATING_CODES = begin
      codes = Array(Code).new(40) { Code.new(0, 0) }
      CCITTFaxDecoderStream::BLACK_CODES.each_with_index do |row, i|
        bit_length = i + 2
        row.each_with_index do |code, j|
          value = CCITTFaxDecoderStream::BLACK_RUN_LENGTHS[i][j]
          codes[(value // 64) - 1] = Code.new(code, bit_length) if value >= 64
        end
      end
      codes
    end

    @input_buffer : Bytes
    @current_buffer_length = 0
    @current_row = 0
    @changes_current_row : Array(Int32)
    @changes_reference_row : Array(Int32)
    @changes_current_row_length = 0
    @changes_reference_row_length = 0
    @output_buffer = 0_u8
    @output_buffer_bit_length = 0

    def initialize(@stream : ::IO, @columns : Int32, @rows : Int32, @fill_order : Int32)
      @input_buffer = Bytes.new((@columns + 7) // 8)
      @changes_current_row = Array(Int32).new(@columns, 0)
      @changes_reference_row = Array(Int32).new(@columns, 0)
    end

    def write(byte : UInt8) : Nil
      @input_buffer[@current_buffer_length] = byte
      @current_buffer_length += 1

      if @current_buffer_length == @input_buffer.size
        encode_row
        @current_buffer_length = 0
      end
    end

    def write(bytes : Bytes) : Nil
      bytes.each { |byte| write(byte) }
    end

    private def encode_row : Nil
      @current_row += 1
      tmp = @changes_reference_row
      @changes_reference_row = @changes_current_row
      @changes_current_row = tmp
      @changes_reference_row_length = @changes_current_row_length
      @changes_current_row_length = 0

      index = 0
      white = true
      while index < @columns
        byte_index = index // 8
        bit = index % 8
        pixel_is_one = ((@input_buffer[byte_index] >> (7 - bit)) & 1) == 1
        if pixel_is_one == white
          @changes_current_row[@changes_current_row_length] = index
          @changes_current_row_length += 1
          white = !white
        end
        index += 1
      end

      encode_2d

      if @current_row == @rows
        write_eol
        write_eol
        fill
      end
    end

    private def get_next_changes(pos : Int32, white : Bool) : Array(Int32)
      result = [@columns, @columns]
      i = 0
      while i < @changes_current_row_length
        if pos < @changes_current_row[i] || (pos == 0 && white)
          result[0] = @changes_current_row[i]
          result[1] = @changes_current_row[i + 1] if (i + 1) < @changes_current_row_length
          break
        end
        i += 1
      end
      result
    end

    private def get_next_ref_changes(a0 : Int32, white : Bool) : Array(Int32)
      result = [@columns, @columns]
      i = white ? 0 : 1
      while i < @changes_reference_row_length
        if @changes_reference_row[i] > a0 || (a0 == 0 && i == 0)
          result[0] = @changes_reference_row[i]
          result[1] = @changes_reference_row[i + 1] if (i + 1) < @changes_reference_row_length
          break
        end
        i += 2
      end
      result
    end

    private def write_run(run_length : Int32, white : Bool) : Nil
      nonterm = run_length // 64
      codes = white ? WHITE_NONTERMINATING_CODES : BLACK_NONTERMINATING_CODES
      while nonterm > 0
        if nonterm >= codes.size
          write(codes[codes.size - 1].code, codes[codes.size - 1].length)
          nonterm -= codes.size
        else
          write(codes[nonterm - 1].code, codes[nonterm - 1].length)
          nonterm = 0
        end
      end

      c = white ? WHITE_TERMINATING_CODES[run_length % 64] : BLACK_TERMINATING_CODES[run_length % 64]
      write(c.code, c.length)
    end

    private def encode_2d : Nil
      white = true
      index = 0
      while index < @columns
        next_changes = get_next_changes(index, white)
        next_refs = get_next_ref_changes(index, white)
        difference = next_changes[0] - next_refs[0]

        if next_changes[0] > next_refs[1]
          # Pass mode
          write(1, 4)
          index = next_refs[1]
        elsif difference > 3 || difference < -3
          # Horizontal mode
          write(1, 3)
          write_run(next_changes[0] - index, white)
          write_run(next_changes[1] - next_changes[0], !white)
          index = next_changes[1]
        else
          case difference
          when  0 then write(1, 1)
          when  1 then write(3, 3)
          when  2 then write(3, 6)
          when  3 then write(3, 7)
          when -1 then write(2, 3)
          when -2 then write(2, 6)
          when -3 then write(2, 7)
          end
          white = !white
          index = next_refs[0] + difference
        end
      end
    end

    private def write(code : Int32, code_length : Int32) : Nil
      i = 0
      while i < code_length
        code_bit = ((code >> (code_length - i - 1)) & 1) == 1
        if @fill_order == TIFFExtension::FILL_LEFT_TO_RIGHT
          @output_buffer |= (1_u8 << (7 - (@output_buffer_bit_length % 8))) if code_bit
        else
          @output_buffer |= (1_u8 << (@output_buffer_bit_length % 8)) if code_bit
        end
        @output_buffer_bit_length += 1

        if @output_buffer_bit_length == 8
          @stream.write_byte(@output_buffer)
          clear_output_buffer
        end
        i += 1
      end
    end

    private def write_eol : Nil
      write(1, 12)
    end

    private def fill : Nil
      @stream.write_byte(@output_buffer) if @output_buffer_bit_length != 0
      clear_output_buffer
    end

    private def clear_output_buffer : Nil
      @output_buffer = 0_u8
      @output_buffer_bit_length = 0
    end
  end
end

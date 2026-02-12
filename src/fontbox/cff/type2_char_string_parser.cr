# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Fontbox::CFF
  # This class represents a converter for a mapping into a Type2-sequence.
  class Type2CharStringParser
    # 1-byte commands
    CALLSUBR  = CharStringCommand::CALLSUBR.value
    CALLGSUBR = CharStringCommand::CALLGSUBR.value

    # not yet supported commands
    HINTMASK = CharStringCommand::HINTMASK.value
    CNTRMASK = CharStringCommand::CNTRMASK.value

    @font_name : String

    # Constructs a new Type1CharStringParser object for a Type 1-equivalent font.
    #
    # @param fontName font name
    def initialize(@font_name : String)
    end

    # The given byte array will be parsed and converted to a Type2 sequence.
    #
    # @param bytes the given mapping as byte array
    # @param global_subr_index array containing all global subroutines
    # @param local_subr_index array containing all local subroutines
    #
    # @return the Type2 sequence
    # @throws IO::Error if an error occurs during reading
    def parse(bytes : Bytes, global_subr_index : Array(Bytes)?, local_subr_index : Array(Bytes)?) : Array(CharStringCommand | Int32 | Float64)
      glyph_data = GlyphData.new
      parse_sequence(bytes, global_subr_index, local_subr_index, glyph_data)
      glyph_data.sequence
    end

    private class GlyphData
      property sequence = [] of CharStringCommand | Int32 | Float64
      property hstem_count = 0
      property vstem_count = 0

      def initialize
      end
    end

    private def parse_sequence(bytes : Bytes, global_subr_index : Array(Bytes)?, local_subr_index : Array(Bytes)?, glyph_data : GlyphData) : Nil
      input = DataInputByteArray.new(bytes)

      while input.has_remaining?
        b0 = input.read_unsigned_byte
        if b0 == CALLSUBR
          process_call_subr(global_subr_index, local_subr_index, glyph_data)
        elsif b0 == CALLGSUBR
          process_call_gsubr(global_subr_index, local_subr_index, glyph_data)
        elsif b0 == HINTMASK || b0 == CNTRMASK
          glyph_data.vstem_count += count_numbers(glyph_data.sequence) // 2
          mask_length = mask_length(glyph_data.hstem_count, glyph_data.vstem_count)
          # drop the following bytes representing the mask as long as we don't support HINTMASK and CNTRMASK
          mask_length.times do
            input.read_unsigned_byte
          end
          glyph_data.sequence << CharStringCommand.get_instance(b0)
        elsif (b0 >= 0 && b0 <= 18) || (b0 >= 21 && b0 <= 27) || (b0 >= 29 && b0 <= 31)
          glyph_data.sequence << read_command(b0, input, glyph_data)
        elsif b0 == 28 || (b0 >= 32 && b0 <= 255)
          glyph_data.sequence << read_number(b0, input)
        else
          raise ArgumentError.new("Invalid byte value: #{b0}")
        end
      end
    end

    private def subr_bytes(subr_index : Array(Bytes)?, glyph_data : GlyphData) : Bytes?
      return unless subr_index
      return if subr_index.empty?

      subr_number = calculate_subr_number(
        glyph_data.sequence.pop.as(Int32),
        subr_index.size
      )
      subr_number < subr_index.size ? subr_index[subr_number] : nil
    end

    private def process_call_subr(global_subr_index : Array(Bytes)?, local_subr_index : Array(Bytes)?, glyph_data : GlyphData) : Nil
      if !local_subr_index.nil? && !local_subr_index.empty?
        subr_bytes = subr_bytes(local_subr_index, glyph_data)
        process_subr(global_subr_index, local_subr_index, subr_bytes, glyph_data)
      end
    end

    private def process_call_gsubr(global_subr_index : Array(Bytes)?, local_subr_index : Array(Bytes)?, glyph_data : GlyphData) : Nil
      if !global_subr_index.nil? && !global_subr_index.empty?
        subr_bytes = subr_bytes(global_subr_index, glyph_data)
        process_subr(global_subr_index, local_subr_index, subr_bytes, glyph_data)
      end
    end

    private def process_subr(global_subr_index : Array(Bytes)?, local_subr_index : Array(Bytes)?, subr_bytes : Bytes?, glyph_data : GlyphData) : Nil
      return if subr_bytes.nil?

      parse_sequence(subr_bytes, global_subr_index, local_subr_index, glyph_data)
      last_item = glyph_data.sequence.last
      if last_item.is_a?(CharStringCommand) && last_item.type2_keyword == CharStringCommand::Type2KeyWord::RET
        # remove "return" command
        glyph_data.sequence.pop
      end
    end

    private def calculate_subr_number(operand : Int32, subr_index_length : Int32) : Int32
      if subr_index_length < 1240
        107 + operand
      elsif subr_index_length < 33900
        1131 + operand
      else
        32768 + operand
      end
    end

    private def read_command(b0 : Int32, input : DataInput, glyph_data : GlyphData) : CharStringCommand
      case b0
      when 1, 18
        glyph_data.hstem_count += count_numbers(glyph_data.sequence) // 2
        CharStringCommand.get_instance(b0)
      when 3, 23
        glyph_data.vstem_count += count_numbers(glyph_data.sequence) // 2
        CharStringCommand.get_instance(b0)
      when 12
        CharStringCommand.get_instance(b0, input.read_unsigned_byte)
      else
        CharStringCommand.get_instance(b0)
      end
    end

    private def read_number(b0 : Int32, input : DataInput) : Int32 | Float64
      if b0 == 28
        input.read_short.to_i32
      elsif b0 >= 32 && b0 <= 246
        b0 - 139
      elsif b0 >= 247 && b0 <= 250
        b1 = input.read_unsigned_byte
        (b0 - 247) * 256 + b1 + 108
      elsif b0 >= 251 && b0 <= 254
        b1 = input.read_unsigned_byte
        -(b0 - 251) * 256 - b1 - 108
      elsif b0 == 255
        value = input.read_short.to_i32
        # The lower bytes are representing the digits after the decimal point
        fraction = input.read_unsigned_short / 65535.0
        value + fraction
      else
        raise ArgumentError.new("Invalid byte value: #{b0}")
      end
    end

    private def mask_length(hstem_count : Int32, vstem_count : Int32) : Int32
      hint_count = hstem_count + vstem_count
      length = hint_count // 8
      if hint_count % 8 > 0
        length += 1
      end
      length
    end

    private def count_numbers(sequence : Array(CharStringCommand | Int32 | Float64)) : Int32
      count = 0
      (sequence.size - 1).downto(0) do |i|
        unless sequence[i].is_a?(Int32) || sequence[i].is_a?(Float64)
          return count
        end
        count += 1
      end
      count
    end

    def to_s(io : IO) : Nil
      io << @font_name
    end
  end
end

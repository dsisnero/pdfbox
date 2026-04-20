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

require "log"

module Fontbox::CFF
  class Type1CharStringParser
    Log = ::Log.for(self)

    CALLSUBR      = 10
    TWO_BYTE      = 12
    CALLOTHERSUBR = 16
    POP           = 17

    @font_name : String
    @current_glyph : String = ""

    def initialize(@font_name : String)
    end

    def parse(
      bytes : Bytes,
      subrs : Array(Bytes?),
      glyph_name : String,
    ) : Array(CharStringCommand | Int32 | Float64)
      @current_glyph = glyph_name
      parse_sequence(bytes, subrs, [] of CharStringCommand | Int32 | Float64)
    end

    private def parse_sequence(
      bytes : Bytes,
      subrs : Array(Bytes?),
      sequence : Array(CharStringCommand | Int32 | Float64),
    ) : Array(CharStringCommand | Int32 | Float64)
      input = DataInputByteArray.new(bytes)
      while input.has_remaining?
        b0 = input.read_unsigned_byte
        if b0 == CALLSUBR
          process_call_subr(subrs, sequence)
        elsif b0 == TWO_BYTE && input.peek_unsigned_byte(0) == CALLOTHERSUBR
          process_call_other_subr(input, sequence)
        elsif b0 >= 0 && b0 <= 31
          sequence << read_command(input, b0)
        elsif b0 >= 32 && b0 <= 255
          sequence << read_number(input, b0)
        else
          raise ArgumentError.new("Invalid byte value: #{b0}")
        end
      end
      sequence
    end

    private def process_call_subr(
      subrs : Array(Bytes?),
      sequence : Array(CharStringCommand | Int32 | Float64),
    ) : Nil
      obj = sequence.pop?
      return unless obj
      unless obj.is_a?(Int32)
        Log.warn { "Parameter #{obj} for CALLSUBR is ignored in glyph '#{@current_glyph}' of font #{@font_name}" }
        return
      end

      operand = obj
      if operand >= 0 && operand < subrs.size
        subr_bytes = subrs[operand]?
        return unless subr_bytes
        parse_sequence(subr_bytes, subrs, sequence)
        last_item = sequence.last?
        if last_item.is_a?(CharStringCommand) &&
           last_item.type1_keyword == CharStringCommand::Type1KeyWord::RET
          sequence.pop
        end
      else
        Log.warn { "CALLSUBR is ignored, operand: #{operand}, subrs.size(): #{subrs.size} in glyph '#{@current_glyph}' of font #{@font_name}" }
        while !sequence.empty? && sequence.last.is_a?(Int32)
          sequence.pop
        end
      end
    end

    private def process_call_other_subr(
      input : DataInputByteArray,
      sequence : Array(CharStringCommand | Int32 | Float64),
    ) : Nil
      input.read_byte

      othersubr_num = sequence.pop?.as(Int32)
      num_args = sequence.pop?.as(Int32)
      results = Deque(Int32).new

      case othersubr_num
      when 0
        results.push(remove_integer(sequence))
        results.push(remove_integer(sequence))
        sequence.pop?
        sequence << 0
        sequence << CharStringCommand::CALLOTHERSUBR
      when 1
        sequence << 1
        sequence << CharStringCommand::CALLOTHERSUBR
      when 3
        results.push(remove_integer(sequence))
      else
        num_args.times do
          results.push(remove_integer(sequence))
        end
      end

      while input.has_remaining? &&
            input.peek_unsigned_byte(0) == TWO_BYTE &&
            input.peek_unsigned_byte(1) == POP
        input.read_byte
        input.read_byte
        sequence << results.pop
      end

      unless results.empty?
        Log.warn { "Value left on the PostScript stack in glyph #{@current_glyph} of font #{@font_name}" }
      end
    end

    private def remove_integer(sequence : Array(CharStringCommand | Int32 | Float64)) : Int32
      item = sequence.pop
      case item
      when Int32
        item
      when CharStringCommand
        if item.type1_keyword == CharStringCommand::Type1KeyWord::DIV
          a = sequence.pop.as(Int32)
          b = sequence.pop.as(Int32)
          b // a
        else
          raise IO::Error.new("Unexpected char string command: #{item.type1_keyword}")
        end
      else
        raise IO::Error.new("Unexpected char string value: #{item}")
      end
    end

    private def read_command(input : DataInputByteArray, b0 : Int32) : CharStringCommand
      if b0 == TWO_BYTE
        CharStringCommand.get_instance(b0, input.read_unsigned_byte)
      else
        CharStringCommand.get_instance(b0)
      end
    end

    private def read_number(input : DataInputByteArray, b0 : Int32) : Int32
      if b0 >= 32 && b0 <= 246
        b0 - 139
      elsif b0 >= 247 && b0 <= 250
        b1 = input.read_unsigned_byte
        (b0 - 247) * 256 + b1 + 108
      elsif b0 >= 251 && b0 <= 254
        b1 = input.read_unsigned_byte
        -(b0 - 251) * 256 - b1 - 108
      elsif b0 == 255
        input.read_int
      else
        raise ArgumentError.new("Invalid byte value: #{b0}")
      end
    end
  end
end

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
  # Represents a Type 2 CharString by converting it into an equivalent Type 1 CharString.
  class Type2CharString < Type1CharString
    @def_width_x : Int32 = 0
    @nominal_width_x : Int32 = 0
    @path_count = 0
    @gid : Int32

    # Constructor.
    # @param font Parent CFF font
    # @param font_name font name
    # @param glyph_name glyph name (or CID as hex string)
    # @param gid GID
    # @param sequence Type 2 char string sequence
    # @param default_width_x default width
    # @param nom_width_x nominal width
    def initialize(font : Type1CharStringReader, font_name : String, glyph_name : String, @gid : Int32,
                   sequence : Array(CharStringCommand | Int32 | Float64), default_width_x : Int32, nom_width_x : Int32)
      super(font, font_name, glyph_name)
      @def_width_x = default_width_x
      @nominal_width_x = nom_width_x
      convert_type1_to_type2(sequence)
    end

    # Return the GID (glyph id) of this charstring.
    #
    # @return the GID of this charstring
    def gid : Int32
      @gid
    end

    # Converts a sequence of Type 2 commands into a sequence of Type 1 commands.
    # @param sequence the Type 2 char string sequence
    private def convert_type1_to_type2(sequence : Array(CharStringCommand | Int32 | Float64)) : Nil
      @path_count = 0

      # PDFBOX-5987: the sequence contains several "num denom DIV" sequences whose results are used
      # for further operations. However the converter only handles direct arguments properly,
      # not arguments that are created at runtime on the stack. It's not possible to fix this
      # by just copying the command codes because addAlternatingCurve / addCurve require
      # switching the sequence of arguments.
      # The solution below just replaces all "num denom DIV" sequences with its result.
      # If more files with even more complex sequences appear we will have to get rid of the
      # converter and implement a complete renderer like with type1 charstrings.
      new_sequence = [] of CharStringCommand | Int32 | Float64
      i = 0
      while i < sequence.size
        if sequence[i].is_a?(CharStringCommand) && sequence[i].as(CharStringCommand) == CharStringCommand::DIV && i >= 2
          num = sequence[i - 2]
          den = sequence[i - 1]
          if num.is_a?(Int32 | Float64) && den.is_a?(Int32 | Float64)
            num_f = num.is_a?(Int32) ? num.to_f32 : num.as(Float64).to_f32
            den_f = den.is_a?(Int32) ? den.to_f32 : den.as(Float64).to_f32
            f = num_f / den_f
            # Remove the last two elements from new_sequence (num and den)
            if new_sequence.size >= 2
              new_sequence.pop
              new_sequence.pop
            end
            new_sequence << f.to_f64
          else
            new_sequence << sequence[i]
          end
        else
          new_sequence << sequence[i]
        end
        i += 1
      end

      numbers = [] of Int32 | Float64
      new_sequence.each do |obj|
        if obj.is_a?(CharStringCommand)
          results = convert_type2_command(numbers, obj.as(CharStringCommand))
          numbers.clear
          numbers.concat(results)
        else
          numbers << obj.as(Int32 | Float64)
        end
      end
    end

    private def convert_type2_command(numbers : Array(Int32 | Float64), command : CharStringCommand) : Array(Int32 | Float64)
      type2_keyword = command.type2_keyword
      if type2_keyword.nil?
        add_command(numbers, command)
        return [] of Int32 | Float64
      end

      case type2_keyword
      when CharStringCommand::Type2KeyWord::HSTEM,
           CharStringCommand::Type2KeyWord::HSTEMHM,
           CharStringCommand::Type2KeyWord::VSTEM,
           CharStringCommand::Type2KeyWord::VSTEMHM,
           CharStringCommand::Type2KeyWord::HINTMASK,
           CharStringCommand::Type2KeyWord::CNTRMASK
        numbers = clear_stack(numbers, numbers.size % 2 != 0)
        expand_stem_hints(numbers,
          type2_keyword == CharStringCommand::Type2KeyWord::HSTEM ||
          type2_keyword == CharStringCommand::Type2KeyWord::HSTEMHM)
      when CharStringCommand::Type2KeyWord::HMOVETO,
           CharStringCommand::Type2KeyWord::VMOVETO
        numbers = clear_stack(numbers, numbers.size > 1)
        mark_path
        add_command(numbers, command)
      when CharStringCommand::Type2KeyWord::RLINETO
        add_command_list(split(numbers, 2), command)
      when CharStringCommand::Type2KeyWord::HLINETO,
           CharStringCommand::Type2KeyWord::VLINETO
        add_alternating_line(numbers, type2_keyword == CharStringCommand::Type2KeyWord::HLINETO)
      when CharStringCommand::Type2KeyWord::RRCURVETO
        add_command_list(split(numbers, 6), command)
      when CharStringCommand::Type2KeyWord::ENDCHAR
        numbers = clear_stack(numbers, numbers.size == 5 || numbers.size == 1)
        close_char_string2_path
        if numbers.size == 4
          # deprecated "seac" operator
          numbers.insert(0, 0)
          add_command(numbers, CharStringCommand.get_instance(12, 6))
        else
          add_command(numbers, command)
        end
      when CharStringCommand::Type2KeyWord::RMOVETO
        numbers = clear_stack(numbers, numbers.size > 2)
        mark_path
        add_command(numbers, command)
      when CharStringCommand::Type2KeyWord::HVCURVETO,
           CharStringCommand::Type2KeyWord::VHCURVETO
        add_alternating_curve(numbers, type2_keyword == CharStringCommand::Type2KeyWord::HVCURVETO)
      when CharStringCommand::Type2KeyWord::HFLEX
        if numbers.size >= 7
          first = [numbers[0], 0, numbers[1], numbers[2], numbers[3], 0]
          second = [numbers[4], 0, numbers[5], -numbers[2], numbers[6], 0]
          add_command_list([first, second], CharStringCommand::RRCURVETO)
        end
      when CharStringCommand::Type2KeyWord::FLEX
        if numbers.size >= 12
          first = numbers[0, 6]
          second = numbers[6, 6]
          add_command_list([first, second], CharStringCommand::RRCURVETO)
        end
      when CharStringCommand::Type2KeyWord::HFLEX1
        if numbers.size >= 9
          first = [numbers[0], numbers[1], numbers[2], numbers[3], numbers[4], 0]
          second = [numbers[5], 0, numbers[6], numbers[7], numbers[8], 0]
          add_command_list([first, second], CharStringCommand::RRCURVETO)
        end
      when CharStringCommand::Type2KeyWord::FLEX1
        if numbers.size >= 11
          dx = 0
          dy = 0
          5.times do |i|
            dx += numbers[i * 2].to_i
            dy += numbers[i * 2 + 1].to_i
          end
          first = numbers[0, 6]
          dx_is_bigger = dx.abs > dy.abs
          second = [
            numbers[6],
            numbers[7],
            numbers[8],
            numbers[9],
            dx_is_bigger ? numbers[10] : -dx,
            dx_is_bigger ? -dy : numbers[10],
          ]
          add_command_list([first, second], CharStringCommand::RRCURVETO)
        end
      when CharStringCommand::Type2KeyWord::RCURVELINE
        if numbers.size >= 2
          add_command_list(split(numbers[0, numbers.size - 2], 6), CharStringCommand::RRCURVETO)
          add_command(numbers[numbers.size - 2, 2], CharStringCommand::RLINETO)
        end
      when CharStringCommand::Type2KeyWord::RLINECURVE
        if numbers.size >= 6
          add_command_list(split(numbers[0, numbers.size - 6], 2), CharStringCommand::RLINETO)
          add_command(numbers[numbers.size - 6, 6], CharStringCommand::RRCURVETO)
        end
      when CharStringCommand::Type2KeyWord::HHCURVETO,
           CharStringCommand::Type2KeyWord::VVCURVETO
        add_curve(numbers, type2_keyword == CharStringCommand::Type2KeyWord::HHCURVETO)
      else
        add_command(numbers, command)
      end
      [] of Int32 | Float64
    end

    private def clear_stack(numbers : Array(Int32 | Float64), flag : Bool) : Array(Int32 | Float64)
      if sequence_empty?
        if flag
          add_command([0, numbers[0] + @nominal_width_x], CharStringCommand::HSBW)
          numbers = numbers[1, numbers.size - 1]
        else
          add_command([0, @def_width_x], CharStringCommand::HSBW)
        end
      end
      numbers
    end

    # @param numbers
    # @param horizontal
    private def expand_stem_hints(numbers : Array(Int32 | Float64), horizontal : Bool) : Nil
      # TODO
    end

    private def mark_path : Nil
      if @path_count > 0
        close_char_string2_path
      end
      @path_count += 1
    end

    private def close_char_string2_path : Nil
      command = last_sequence_entry
      if command.is_a?(CharStringCommand) && command.type1_keyword != CharStringCommand::Type1KeyWord::CLOSEPATH
        empty_arr = [] of (Int32 | Float64)
        add_command(empty_arr, CharStringCommand::CLOSEPATH)
      end
    end

    private def add_alternating_line(numbers : Array(Int32 | Float64), horizontal : Bool) : Nil
      while !numbers.empty?
        add_command(numbers[0, 1], horizontal ? CharStringCommand::HLINETO : CharStringCommand::VLINETO)
        numbers = numbers[1, numbers.size - 1]
        horizontal = !horizontal
      end
    end

    private def add_alternating_curve(numbers : Array(Int32 | Float64), horizontal : Bool) : Nil
      while numbers.size >= 4
        last = numbers.size == 5
        if horizontal
          add_command([
            numbers[0], 0,
            numbers[1], numbers[2],
            last ? numbers[4] : 0, numbers[3],
          ], CharStringCommand::RRCURVETO)
        else
          add_command([
            0, numbers[0],
            numbers[1], numbers[2],
            numbers[3], last ? numbers[4] : 0,
          ], CharStringCommand::RRCURVETO)
        end
        numbers = numbers[last ? 5 : 4, numbers.size - (last ? 5 : 4)]
        horizontal = !horizontal
      end
    end

    private def add_curve(numbers : Array(Int32 | Float64), horizontal : Bool) : Nil
      while numbers.size >= 4
        first = numbers.size % 4 == 1

        if horizontal
          add_command([
            first ? numbers[1] : numbers[0],
            first ? numbers[0] : 0,
            first ? numbers[2] : numbers[1],
            first ? numbers[3] : numbers[2],
            first ? numbers[4] : numbers[3],
            0,
          ], CharStringCommand::RRCURVETO)
        else
          add_command([
            first ? numbers[0] : 0,
            first ? numbers[1] : numbers[0],
            first ? numbers[2] : numbers[1],
            first ? numbers[3] : numbers[2],
            0,
            first ? numbers[4] : numbers[3],
          ], CharStringCommand::RRCURVETO)
        end
        numbers = numbers[first ? 5 : 4, numbers.size - (first ? 5 : 4)]
      end
    end

    private def add_command_list(numbers_list : Array(Array(Int32 | Float64)), command : CharStringCommand) : Nil
      numbers_list.each do |ns|
        add_command(ns, command)
      end
    end

    private def split(list : Array(Int32 | Float64), size : Int32) : Array(Array(Int32 | Float64))
      list_size = list.size // size
      result = Array(Array(Int32 | Float64)).new(list_size)
      list_size.times do |i|
        result << list[i * size, size]
      end
      result
    end
  end
end

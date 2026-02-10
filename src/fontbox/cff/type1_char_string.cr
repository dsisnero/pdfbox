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

require "../util"
require "log"

module Fontbox::CFF
  # This class represents and renders a Type 1 CharString.
  class Type1CharString
    Log = ::Log.for(self)
    @font : Type1CharStringReader
    @font_name : String
    @glyph_name : String
    @type1_sequence = [] of CharStringCommand | Int32 | Float64
    @path : Fontbox::Util::Path? = nil
    @width : Int32 = 0
    @left_side_bearing : Fontbox::Util::Point2D? = nil
    @current : Fontbox::Util::Point2D? = nil
    @is_flex = false
    @flex_points = [] of Fontbox::Util::Point2D
    @command_count = 0

    # Constructs a new Type1CharString object.
    #
    # @param font Parent Type 1 CharString font.
    # @param font_name Name of the font.
    # @param glyph_name Name of the glyph.
    # @param sequence Type 1 char string sequence
    def initialize(@font : Type1CharStringReader, @font_name : String, @glyph_name : String, sequence : Array(CharStringCommand | Int32 | Float64) = [] of CharStringCommand | Int32 | Float64)
      @type1_sequence.concat(sequence)
      @current = Fontbox::Util::Point2D.new(0.0, 0.0)
    end

    # Constructor for use in subclasses.
    #
    # @param font Parent Type 1 CharString font.
    # @param font_name Name of the font.
    # @param glyph_name Name of the glyph.
    protected def initialize(@font : Type1CharStringReader, @font_name : String, @glyph_name : String)
      @type1_sequence = [] of CharStringCommand | Int32 | Float64
      @current = Fontbox::Util::Point2D.new(0.0, 0.0)
    end

    def name : String
      @glyph_name
    end

    # Returns the advance width of the glyph.
    def width : Int32
      if @path.nil?
        render
      end
      @width
    end

    # Returns the path of the character.
    def path : Fontbox::Util::Path
      if @path.nil?
        render
      end
      @path.not_nil!
    end

    # Renders the Type 1 char string sequence to a Path.
    private def render : Nil
      @path = Fontbox::Util::Path.new
      @left_side_bearing = Fontbox::Util::Point2D.new(0.0, 0.0)
      @width = 0
      numbers = [] of Int32 | Float64
      @type1_sequence.each do |obj|
        case obj
        when CharStringCommand
          handle_type1_command(numbers, obj)
        else
          numbers << obj
        end
      end
    end

    private def handle_type1_command(numbers : Array(Int32 | Float64), command : CharStringCommand) : Nil
      @command_count += 1
      type1_keyword = command.type1_keyword
      if type1_keyword.nil?
        # indicates an invalid charstring
        Log.warn { "Unknown charstring command in glyph #{@glyph_name} of font #{@font_name}" }
        numbers.clear
        return
      end
      case type1_keyword
      when CharStringCommand::Type1KeyWord::RMOVETO
        if numbers.size >= 2
          if @is_flex
            @flex_points << Fontbox::Util::Point2D.new(numbers[0].to_f, numbers[1].to_f)
          else
            rmove_to(numbers[0], numbers[1])
          end
        end
      when CharStringCommand::Type1KeyWord::VMOVETO
        if !numbers.empty?
          if @is_flex
            # not in the Type 1 spec, but exists in some fonts
            @flex_points << Fontbox::Util::Point2D.new(0.0, numbers[0].to_f)
          else
            rmove_to(0, numbers[0])
          end
        end
      when CharStringCommand::Type1KeyWord::HMOVETO
        if !numbers.empty?
          if @is_flex
            # not in the Type 1 spec, but exists in some fonts
            @flex_points << Fontbox::Util::Point2D.new(numbers[0].to_f, 0.0)
          else
            rmove_to(numbers[0], 0)
          end
        end
      when CharStringCommand::Type1KeyWord::RLINETO
        if numbers.size >= 2
          rline_to(numbers[0], numbers[1])
        end
      when CharStringCommand::Type1KeyWord::HLINETO
        if !numbers.empty?
          rline_to(numbers[0], 0)
        end
      when CharStringCommand::Type1KeyWord::VLINETO
        if !numbers.empty?
          rline_to(0, numbers[0])
        end
      when CharStringCommand::Type1KeyWord::RRCURVETO
        if numbers.size >= 6
          rrcurve_to(numbers[0], numbers[1], numbers[2], numbers[3], numbers[4], numbers[5])
        end
      when CharStringCommand::Type1KeyWord::CLOSEPATH
        close_charstring1_path
      when CharStringCommand::Type1KeyWord::SBW
        if numbers.size >= 3
          @left_side_bearing = Fontbox::Util::Point2D.new(numbers[0].to_f, numbers[1].to_f)
          @width = numbers[2].to_i
          @current.not_nil!.set_location(@left_side_bearing.not_nil!.x, @left_side_bearing.not_nil!.y)
        end
      when CharStringCommand::Type1KeyWord::HSBW
        if numbers.size >= 2
          @left_side_bearing = Fontbox::Util::Point2D.new(numbers[0].to_f, 0.0)
          @width = numbers[1].to_i
          @current.not_nil!.set_location(@left_side_bearing.not_nil!.x, @left_side_bearing.not_nil!.y)
        end
      when CharStringCommand::Type1KeyWord::VHCURVETO
        if numbers.size >= 4
          rrcurve_to(0, numbers[0], numbers[1], numbers[2], numbers[3], 0)
        end
      when CharStringCommand::Type1KeyWord::HVCURVETO
        if numbers.size >= 4
          rrcurve_to(numbers[0], 0, numbers[1], numbers[2], 0, numbers[3])
        end
      when CharStringCommand::Type1KeyWord::SEAC
        if numbers.size >= 5
          seac(numbers[0], numbers[1], numbers[2], numbers[3], numbers[4])
        end
      when CharStringCommand::Type1KeyWord::SETCURRENTPOINT
        if numbers.size >= 2
          set_current_point(numbers[0], numbers[1])
        end
      when CharStringCommand::Type1KeyWord::CALLOTHERSUBR
        if !numbers.empty?
          call_other_subr(numbers[0].to_i)
        end
      when CharStringCommand::Type1KeyWord::DIV
        if numbers.size >= 2
          b = numbers[-1].to_f
          a = numbers[-2].to_f
          result = a / b
          numbers.pop
          numbers.pop
          numbers << result
          return
        end
      when CharStringCommand::Type1KeyWord::HSTEM,
           CharStringCommand::Type1KeyWord::VSTEM,
           CharStringCommand::Type1KeyWord::HSTEM3,
           CharStringCommand::Type1KeyWord::VSTEM3,
           CharStringCommand::Type1KeyWord::DOTSECTION
        # ignore hints
      when CharStringCommand::Type1KeyWord::ENDCHAR
        # end
      when CharStringCommand::Type1KeyWord::RET,
           CharStringCommand::Type1KeyWord::CALLSUBR
        # indicates an invalid charstring
        Log.warn { "Unexpected charstring command: #{type1_keyword} in glyph #{@glyph_name} of font #{@font_name}" }
      else
        # indicates a PDFBox bug
        raise "Unhandled command: #{type1_keyword}"
      end
      numbers.clear
    end

    private def set_current_point(x : Int32 | Float64, y : Int32 | Float64) : Nil
      @current.not_nil!.set_location(x.to_f, y.to_f)
    end

    # Flex (via OtherSubrs)
    private def call_other_subr(num : Int32) : Nil
      if num == 0
        # end flex
        @is_flex = false

        if @flex_points.size < 7
          Log.warn { "flex without moveTo in font #{@font_name}, glyph #{@glyph_name}, command #{@command_count}" }
          return
        end

        # reference point is relative to start point
        reference = @flex_points[0]
        reference.set_location(@current.not_nil!.x + reference.x, @current.not_nil!.y + reference.y)

        # first point is relative to reference point
        first = @flex_points[1]
        first.set_location(reference.x + first.x, reference.y + first.y)

        # make the first point relative to the start point
        first.set_location(first.x - @current.not_nil!.x, first.y - @current.not_nil!.y)

        p1 = @flex_points[1]
        p2 = @flex_points[2]
        p3 = @flex_points[3]
        rrcurve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y)

        p4 = @flex_points[4]
        p5 = @flex_points[5]
        p6 = @flex_points[6]
        rrcurve_to(p4.x, p4.y, p5.x, p5.y, p6.x, p6.y)

        @flex_points.clear
      elsif num == 1
        # begin flex
        @is_flex = true
      else
        Log.warn { "Invalid callothersubr parameter: #{num}" }
      end
    end

    # Relative moveto.
    private def rmove_to(dx : Int32 | Float64, dy : Int32 | Float64) : Nil
      x = @current.not_nil!.x + dx.to_f
      y = @current.not_nil!.y + dy.to_f
      @path.not_nil!.move_to(x, y)
      @current.not_nil!.set_location(x, y)
    end

    # Relative lineto.
    private def rline_to(dx : Int32 | Float64, dy : Int32 | Float64) : Nil
      x = @current.not_nil!.x + dx.to_f
      y = @current.not_nil!.y + dy.to_f
      if @path.not_nil!.current_point.nil?
        Log.warn { "rlineTo without initial moveTo in font #{@font_name}, glyph #{@glyph_name}" }
        @path.not_nil!.move_to(x, y)
      else
        @path.not_nil!.line_to(x, y)
      end
      @current.not_nil!.set_location(x, y)
    end

    # Relative curveto.
    private def rrcurve_to(dx1 : Int32 | Float64, dy1 : Int32 | Float64, dx2 : Int32 | Float64, dy2 : Int32 | Float64,
                           dx3 : Int32 | Float64, dy3 : Int32 | Float64) : Nil
      x1 = @current.not_nil!.x + dx1.to_f
      y1 = @current.not_nil!.y + dy1.to_f
      x2 = x1 + dx2.to_f
      y2 = y1 + dy2.to_f
      x3 = x2 + dx3.to_f
      y3 = y2 + dy3.to_f
      if @path.not_nil!.current_point.nil?
        Log.warn { "rrcurveTo without initial moveTo in font #{@font_name}, glyph #{@glyph_name}" }
        @path.not_nil!.move_to(x3, y3)
      else
        @path.not_nil!.curve_to(x1, y1, x2, y2, x3, y3)
      end
      @current.not_nil!.set_location(x3, y3)
    end

    # Close path.
    private def close_charstring1_path : Nil
      if @path.not_nil!.current_point.nil?
        Log.warn { "closepath without initial moveTo in font #{@font_name}, glyph #{@glyph_name}" }
      else
        @path.not_nil!.close_path
      end
      # In Java: path.moveTo(current.getX(), current.getY())
      # We'll keep current point unchanged
    end

    # Standard Encoding Accented Character
    private def seac(asb : Int32 | Float64, adx : Int32 | Float64, ady : Int32 | Float64,
                     bchar : Int32 | Float64, achar : Int32 | Float64) : Nil
      # TODO: Implement SEAC (requires StandardEncoding and font.getType1CharString)
      Log.warn { "SEAC not yet implemented for glyph #{@glyph_name} of font #{@font_name}" }
    end

    # Add a command to the type1 sequence.
    #
    # @param numbers the parameters of the command to be added
    # @param command the command to be added
    protected def add_command(numbers : Array(Int32 | Float64), command : CharStringCommand) : Nil
      numbers.each do |num|
        @type1_sequence << num
      end
      @type1_sequence << command
    end

    # Indicates if the underlying type1 sequence is empty.
    #
    # @return true if the sequence is empty
    protected def sequence_empty? : Bool
      @type1_sequence.empty?
    end

    # Returns the last entry of the underlying type1 sequence.
    #
    # @return the last entry of the type 1 sequence or nil if empty
    protected def last_sequence_entry : CharStringCommand | Int32 | Float64 | Nil
      @type1_sequence.last?
    end

    # Returns the type1 sequence (for debugging/testing)
    protected def type1_sequence : Array(CharStringCommand | Int32 | Float64)
      @type1_sequence
    end

    def to_s(io : IO) : Nil
      io << @type1_sequence.to_s.gsub("|", "\n").gsub(",", " ")
    end
  end
end

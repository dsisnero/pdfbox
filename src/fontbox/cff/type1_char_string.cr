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
  # This class represents and renders a Type 1 CharString.
  class Type1CharString
    @font : Type1CharStringReader
    @font_name : String
    @glyph_name : String
    @type1_sequence = [] of CharStringCommand | Int32 | Float64

    # Constructs a new Type1CharString object.
    #
    # @param font Parent Type 1 CharString font.
    # @param font_name Name of the font.
    # @param glyph_name Name of the glyph.
    # @param sequence Type 1 char string sequence
    def initialize(@font : Type1CharStringReader, @font_name : String, @glyph_name : String, sequence : Array(CharStringCommand | Int32 | Float64) = [] of CharStringCommand | Int32 | Float64)
      @type1_sequence.concat(sequence)
    end

    # Constructor for use in subclasses.
    #
    # @param font Parent Type 1 CharString font.
    # @param font_name Name of the font.
    # @param glyph_name Name of the glyph.
    protected def initialize(@font : Type1CharStringReader, @font_name : String, @glyph_name : String)
      @type1_sequence = [] of CharStringCommand | Int32 | Float64
    end

    def name : String
      @glyph_name
    end

    # Returns the width of the glyph.
    # TODO: Implement actual width calculation from rendering
    def width : Int32
      0
    end

    # Returns the path of the character.
    # TODO: Implement actual path rendering
    def path
      nil
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

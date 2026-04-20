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

require "../font_box_font"
require "../encoding"
require "../pfb/pfb_parser"
require "../cff/type1_char_string"
require "../cff/type1_char_string_parser"

module Fontbox::Type1
  class Type1Font < Fontbox::FontBoxFont
    property font_name = ""
    property encoding : Fontbox::Encoding?
    property paint_type = 0
    property font_type = 0
    property unique_id = 0
    property stroke_width = 0.0_f32
    property font_id = ""
    property version = ""
    property notice = ""
    property full_name = ""
    property family_name = ""
    property weight = ""
    property italic_angle = 0.0_f32
    property? fixed_pitch = false
    property underline_position = 0.0_f32
    property underline_thickness = 0.0_f32
    property blue_scale = 0.0_f32
    property blue_shift = 0
    property blue_fuzz = 0
    property? force_bold = false
    property language_group = 0
    getter ascii_segment : Bytes
    getter binary_segment : Bytes
    property font_matrix_values = [] of Float32
    property font_bbox_values = [] of Float32
    property blue_values = [] of Float32
    property other_blues = [] of Float32
    property family_blues = [] of Float32
    property family_other_blues = [] of Float32
    property std_hw = [] of Float32
    property std_vw = [] of Float32
    property stem_snap_h = [] of Float32
    property stem_snap_v = [] of Float32
    property subrs = [] of Bytes?
    getter charstrings = {} of String => Bytes

    @char_string_cache = Hash(String, Fontbox::CFF::Type1CharString).new
    @char_string_parser : Fontbox::CFF::Type1CharStringParser?
    @char_string_cache_mutex = Thread::Mutex.new
    @reader : PrivateType1CharStringReader?

    private class PrivateType1CharStringReader < Fontbox::CFF::Type1CharStringReader
      def initialize(@font : Type1Font)
      end

      def type1_char_string(name : String) : Fontbox::CFF::Type1CharString
        @font.type1_char_string(name)
      end
    end

    def self.create_with_pfb(input : IO) : Type1Font
      pfb = Fontbox::Pfb::PfbParser.new(input)
      Type1Parser.new.parse(
        segment_bytes(pfb.segment1),
        segment_bytes(pfb.segment2)
      )
    end

    def self.create_with_pfb(bytes : Bytes) : Type1Font
      pfb = Fontbox::Pfb::PfbParser.new(bytes)
      Type1Parser.new.parse(
        segment_bytes(pfb.segment1),
        segment_bytes(pfb.segment2)
      )
    end

    def self.create_with_segments(segment1 : Bytes, segment2 : Bytes) : Type1Font
      Type1Parser.new.parse(segment1, segment2)
    end

    private def self.segment_bytes(segment : Array(UInt8)) : Bytes
      Bytes.new(segment.size) { |index| segment[index] }
    end

    def initialize(@ascii_segment : Bytes, @binary_segment : Bytes)
      @reader = PrivateType1CharStringReader.new(self)
    end

    private def reader : PrivateType1CharStringReader
      reader = @reader
      raise "Type1 charstring reader was not initialized" unless reader
      reader
    end

    def name : String
      @font_name
    end

    def font_bbox : Fontbox::Util::BoundingBox
      return Fontbox::Util::BoundingBox.new if @font_bbox_values.size < 4
      Fontbox::Util::BoundingBox.new(@font_bbox_values)
    end

    def font_matrix : Array(Float32)
      @font_matrix_values
    end

    def path(name : String) : Fontbox::Util::Path
      type1_char_string(name).path
    end

    def width(name : String) : Float32
      type1_char_string(name).width.to_f32
    end

    def has_glyph?(name : String) : Bool
      @charstrings.has_key?(name)
    end

    def type1_char_string(name : String) : Fontbox::CFF::Type1CharString
      if cached = @char_string_cache[name]?
        return cached
      end

      @char_string_cache_mutex.synchronize do
        if cached = @char_string_cache[name]?
          return cached
        end

        bytes = @charstrings[name]? || @charstrings[".notdef"]?
        raise IO::Error.new(".notdef is not defined") unless bytes

        sequence = parser.parse(bytes, @subrs, name)
        type1 = Fontbox::CFF::Type1CharString.new(reader, @font_name, name, sequence)
        @char_string_cache[name] = type1
        type1
      end
    end

    def parser : Fontbox::CFF::Type1CharStringParser
      @char_string_parser ||= Fontbox::CFF::Type1CharStringParser.new(@font_name)
    end
  end
end

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

require "../pdmodel/font"
require "../util"

module Pdfbox::Text
  # Represents a position of text in a PDF document.
  # Corresponds to org.apache.pdfbox.text.TextPosition in Apache PDFBox.
  class TextPosition
    DIACRITICS = {
      0x0060 => "\u0300",
      0x02CB => "\u0300",
      0x0027 => "\u0301",
      0x02B9 => "\u0301",
      0x02CA => "\u0301",
      0x005E => "\u0302",
      0x02C6 => "\u0302",
      0x007E => "\u0303",
      0x02C9 => "\u0304",
      0x00B0 => "\u030A",
      0x02BA => "\u030B",
      0x02C7 => "\u030C",
      0x02C8 => "\u030D",
      0x0022 => "\u030E",
      0x02BB => "\u0312",
      0x02BC => "\u0313",
      0x0486 => "\u0313",
      0x055A => "\u0313",
      0x02BD => "\u0314",
      0x0485 => "\u0314",
      0x0559 => "\u0314",
      0x02D4 => "\u031D",
      0x02D5 => "\u031E",
      0x02D6 => "\u031F",
      0x02D7 => "\u0320",
      0x02B2 => "\u0321",
      0x02CC => "\u0329",
      0x02B7 => "\u032B",
      0x02CD => "\u0331",
      0x005F => "\u0332",
      0x204E => "\u0359",
    }

    getter text_matrix : Pdfbox::Util::Matrix
    getter end_x : Float32
    getter end_y : Float32
    getter rotation : Int32
    getter max_height : Float32
    getter page_height : Float32
    getter page_width : Float32
    property widths : Array(Float32)
    getter width_of_space : Float32
    property unicode : String
    getter char_codes : Array(Int32)
    getter font : Pdfbox::Pdmodel::Font::PDFont?
    getter font_size : Float32
    getter font_size_pt : Int32
    getter x : Float32
    getter y : Float32
    @direction : Float32 = -1.0_f32

    def initialize(page_rotation : Int32, page_width : Float32, page_height : Float32, text_matrix : Pdfbox::Util::Matrix,
                   end_x : Float32, end_y : Float32, max_height : Float32, individual_width : Float32,
                   space_width : Float32, unicode : String, char_codes : Array(Int32), font : Pdfbox::Pdmodel::Font::PDFont?,
                   font_size : Float32, font_size_pt : Int32)
      @text_matrix = text_matrix
      @end_x = end_x
      @end_y = end_y
      @rotation = page_rotation
      @max_height = max_height
      @page_height = page_height
      @page_width = page_width
      @widths = [individual_width]
      @width_of_space = space_width
      @unicode = unicode
      @char_codes = char_codes
      @font = font
      @font_size = font_size
      @font_size_pt = font_size_pt

      @x = get_x_rot(page_rotation)
      @y = if page_rotation == 0 || page_rotation == 180
             page_height - get_y_lower_left_rot(page_rotation)
           else
             page_width - get_y_lower_left_rot(page_rotation)
           end
    end

    def x : Float32
      @x
    end

    def y : Float32
      @y
    end

    def unicode : String
      @unicode
    end

    # Matches org.apache.pdfbox.text.TextPosition#getVisuallyOrderedUnicode.
    def visually_ordered_unicode : String
      text = unicode
      byte_index = 0

      text.each_char do |char|
        next_index = byte_index + char.bytesize
        if rtl_directionality?(char.ord) && (byte_index != 0 || next_index < text.bytesize)
          return text.reverse
        end
        byte_index = next_index
      end

      text
    end

    def font : Pdfbox::Pdmodel::Font::PDFont?
      @font
    end

    def font_size : Float32
      @font_size
    end

    def height : Float32
      @max_height
    end

    def width : Float32
      get_width_rot(rotation)
    end

    def dir : Float32
      if @direction < 0
        a = text_matrix.get_value(1, 1)
        b = text_matrix.get_value(1, 0)
        c = text_matrix.get_value(0, 1)
        d = text_matrix.get_value(0, 0)

        @direction = if a > 0 && b.abs < d && c.abs < a && d > 0
                       0.0_f32
                     elsif a < 0 && b.abs < d.abs && c.abs < a.abs && d < 0
                       180.0_f32
                     elsif a.abs < c.abs && b > 0 && c < 0 && d.abs < b
                       90.0_f32
                     elsif a.abs < c && b < 0 && c > 0 && d.abs < b.abs
                       270.0_f32
                     else
                       0.0_f32
                     end
      end
      @direction
    end

    def x_dir_adj : Float32
      get_x_rot(dir.round.to_i)
    end

    def y_dir_adj : Float32
      direction = dir.round.to_i
      if direction == 0 || direction == 180
        page_height - get_y_lower_left_rot(direction)
      else
        page_width - get_y_lower_left_rot(direction)
      end
    end

    def width_dir_adj : Float32
      get_width_rot(dir.round.to_i)
    end

    def height_dir : Float32
      @max_height
    end

    def contains(other : TextPosition) : Bool
      this_x_start = x_dir_adj
      this_width = width_dir_adj
      this_x_end = this_x_start + this_width

      other_x_start = other.x_dir_adj
      other_x_end = other_x_start + other.width_dir_adj
      return false if other_x_end <= this_x_start || other_x_start >= this_x_end

      this_y_start = y_dir_adj
      other_y_start = other.y_dir_adj
      return false if other_y_start + other.height_dir < this_y_start || other_y_start > this_y_start + height_dir

      if other_x_start > this_x_start && other_x_end > this_x_end
        overlap = this_x_end - other_x_start
        overlap_percent = overlap / this_width
        return overlap_percent > 0.15_f32
      end

      if other_x_start < this_x_start && other_x_end < this_x_end
        overlap = other_x_end - this_x_start
        overlap_percent = overlap / this_width
        return overlap_percent > 0.15_f32
      end

      true
    end

    def completely_contains(other : TextPosition) : Bool
      this_left = x_dir_adj
      this_right = this_left + width_dir_adj
      other_left = other.x_dir_adj
      other_right = other_left + other.width_dir_adj
      return false if this_left > other_left || other_right > this_right

      this_top = y_dir_adj
      this_bottom = this_top + height_dir
      other_top = other.y_dir_adj
      other_bottom = other_top + other.height_dir
      return false if this_top > other_top || other_bottom > this_bottom

      true
    end

    def merge_diacritic(diacritic : TextPosition) : Nil
      return if diacritic.unicode.size > 1

      diac_x_start = diacritic.x_dir_adj
      diac_x_end = diac_x_start + diacritic.widths[0]
      curr_char_x_start = x_dir_adj

      str_len = unicode.size
      was_added = false

      str_len.times do |i|
        break if was_added
        break if i >= widths.size

        curr_char_x_end = curr_char_x_start + widths[i]

        if diac_x_start < curr_char_x_start && diac_x_end <= curr_char_x_end
          if i == 0
            insert_diacritic(i, diacritic)
          else
            distance_overlapping1 = diac_x_end - curr_char_x_start
            percentage1 = distance_overlapping1 / widths[i]

            distance_overlapping2 = curr_char_x_start - diac_x_start
            percentage2 = distance_overlapping2 / widths[i - 1]

            if percentage1 >= percentage2
              insert_diacritic(i, diacritic)
            else
              insert_diacritic(i - 1, diacritic)
            end
          end
          was_added = true
        elsif diac_x_start < curr_char_x_start
          insert_diacritic(i, diacritic)
          was_added = true
        elsif diac_x_end <= curr_char_x_end
          insert_diacritic(i, diacritic)
          was_added = true
        elsif i == str_len - 1
          insert_diacritic(i, diacritic)
          was_added = true
        end

        curr_char_x_start += widths[i]
      end
    end

    def diacritic? : Bool
      text = unicode
      return false unless text.size == 1
      return false if text == "ー"

      diacritic_codepoint?(text[0].ord)
    end

    private def diacritic_codepoint?(codepoint : Int32) : Bool
      (0x0300 <= codepoint && codepoint <= 0x036F) ||
        (0x0483 <= codepoint && codepoint <= 0x0489) ||
        (0x0591 <= codepoint && codepoint <= 0x05C7) ||
        (0x0610 <= codepoint && codepoint <= 0x061A) ||
        (0x064B <= codepoint && codepoint <= 0x065F) ||
        codepoint == 0x0670 ||
        (0x06D6 <= codepoint && codepoint <= 0x06ED) ||
        (0x08D3 <= codepoint && codepoint <= 0x08FF) ||
        (0x1AB0 <= codepoint && codepoint <= 0x1AFF) ||
        (0x1DC0 <= codepoint && codepoint <= 0x1DFF) ||
        (0x20D0 <= codepoint && codepoint <= 0x20FF) ||
        (0x2B0 <= codepoint && codepoint <= 0x02FF) ||
        (0xFC5E <= codepoint && codepoint <= 0xFC63) ||
        (0xFE70 <= codepoint && codepoint <= 0xFE7F) ||
        (0xFE20 <= codepoint && codepoint <= 0xFE2F) ||
        DIACRITICS.has_key?(codepoint)
    end

    private def insert_diacritic(index : Int32, diacritic : TextPosition) : Nil
      widths2 = Array(Float32).new(widths.size + 1, 0.0_f32)
      index.times { |i| widths2[i] = widths[i] }
      widths2[index] = widths[index]
      widths2[index + 1] = 0.0_f32
      ((index + 1)...widths.size).each do |i|
        widths2[i + 1] = widths[i]
      end

      chars = unicode.chars
      rebuilt = String.build do |io|
        index.times { |i| io << chars[i] }
        io << chars[index]

        suffix_start = index + 1
        if index < chars.size - 1 && chars[index].ord.in?(0xD800..0xDBFF) && chars[index + 1].ord.in?(0xDC00..0xDFFF)
          io << chars[index + 1]
          suffix_start += 1
        end

        io << combine_diacritic(diacritic.unicode)
        (suffix_start...chars.size).each { |i| io << chars[i] }
      end

      self.unicode = rebuilt
      self.widths = widths2
    end

    private def combine_diacritic(str : String) : String
      codepoint = str[0].ord
      return DIACRITICS[codepoint] if DIACRITICS.has_key?(codepoint)
      str.unicode_normalize(:nfkc).strip
    end

    private def get_x_rot(rotation : Int32) : Float32
      case rotation
      when 0, 360
        text_matrix.translate_x
      when 90
        text_matrix.translate_y
      when 180
        page_width - text_matrix.translate_x
      when 270
        page_height - text_matrix.translate_y
      else
        0.0_f32
      end
    end

    private def get_y_lower_left_rot(rotation : Int32) : Float32
      case rotation
      when 0, 360
        text_matrix.translate_y
      when 90
        page_width - text_matrix.translate_x
      when 180
        page_height - text_matrix.translate_y
      when 270
        text_matrix.translate_x
      else
        0.0_f32
      end
    end

    private def get_width_rot(rotation : Int32) : Float32
      case rotation
      when 90, 270
        (end_y - text_matrix.translate_y).abs.to_f32
      else
        (end_x - text_matrix.translate_x).abs.to_f32
      end
    end

    private def rtl_directionality?(codepoint : Int32) : Bool
      (0x0590 <= codepoint && codepoint <= 0x08FF) ||
        (0xFB1D <= codepoint && codepoint <= 0xFDFF) ||
        (0xFE70 <= codepoint && codepoint <= 0xFEFF)
    end
  end
end

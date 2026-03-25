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
    getter text_matrix : Pdfbox::Util::Matrix
    getter end_x : Float32
    getter end_y : Float32
    getter rotation : Int32
    getter max_height : Float32
    getter page_height : Float32
    getter page_width : Float32
    getter widths : Array(Float32)
    getter width_of_space : Float32
    getter unicode : String
    getter char_codes : Array(Int32)
    getter font : Pdfbox::Pdmodel::Font::PDFont?
    getter font_size : Float32
    getter font_size_pt : Int32
    getter x : Float32
    getter y : Float32

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
      @widths.sum
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

    private def rtl_directionality?(codepoint : Int32) : Bool
      (0x0590 <= codepoint && codepoint <= 0x08FF) ||
        (0xFB1D <= codepoint && codepoint <= 0xFDFF) ||
        (0xFE70 <= codepoint && codepoint <= 0xFEFF)
    end
  end
end

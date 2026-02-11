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

module Fontbox::TTF
  # Header table.
  #
  # Ported from Apache PDFBox HeaderTable.
  class HeaderTable < TTFTable
    # Tag for this table.
    TAG = "head"

    @version : Float32 = 0.0_f32
    @font_revision : Float32 = 0.0_f32
    @check_sum_adjustment : UInt32 = 0
    @magic_number : UInt32 = 0
    @flags : UInt16 = 0
    @units_per_em : UInt16 = 0
    @created : Time = Time.utc
    @modified : Time = Time.utc
    @x_min : Int16 = 0
    @y_min : Int16 = 0
    @x_max : Int16 = 0
    @y_max : Int16 = 0
    @mac_style : UInt16 = 0
    @lowest_rec_ppem : UInt16 = 0
    @font_direction_hint : Int16 = 0
    @index_to_loc_format : Int16 = 0
    @glyph_data_format : Int16 = 0

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement header table reading
    end

    # Gets the mac style flags.
    def get_mac_style : UInt16
      @mac_style
    end
  end

  # Horizontal header table.
  #
  # Ported from Apache PDFBox HorizontalHeaderTable.
  class HorizontalHeaderTable < TTFTable
    # Tag for this table.
    TAG = "hhea"

    @version : Float32 = 0.0_f32
    @ascender : Int16 = 0
    @descender : Int16 = 0
    @line_gap : Int16 = 0
    @advance_width_max : UInt16 = 0
    @min_left_side_bearing : Int16 = 0
    @min_right_side_bearing : Int16 = 0
    @x_max_extent : Int16 = 0
    @caret_slope_rise : Int16 = 0
    @caret_slope_run : Int16 = 0
    @caret_offset : Int16 = 0
    @reserved1 : Int16 = 0
    @reserved2 : Int16 = 0
    @reserved3 : Int16 = 0
    @reserved4 : Int16 = 0
    @metric_data_format : Int16 = 0
    @number_of_h_metrics : UInt16 = 0

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement horizontal header table reading
    end
  end

  # Maximum profile table.
  #
  # Ported from Apache PDFBox MaximumProfileTable.
  class MaximumProfileTable < TTFTable
    # Tag for this table.
    TAG = "maxp"

    @version : Float32 = 0.0_f32
    @num_glyphs : UInt16 = 0
    @max_points : UInt16 = 0
    @max_contours : UInt16 = 0
    @max_composite_points : UInt16 = 0
    @max_composite_contours : UInt16 = 0
    @max_zones : UInt16 = 0
    @max_twilight_points : UInt16 = 0
    @max_storage : UInt16 = 0
    @max_function_defs : UInt16 = 0
    @max_instruction_defs : UInt16 = 0
    @max_stack_elements : UInt16 = 0
    @max_size_of_instructions : UInt16 = 0
    @max_component_elements : UInt16 = 0
    @max_component_depth : UInt16 = 0

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement maximum profile table reading
    end
  end

  # PostScript table.
  #
  # Ported from Apache PDFBox PostScriptTable.
  class PostScriptTable < TTFTable
    # Tag for this table.
    TAG = "post"

    @format_type : Float32 = 0.0_f32
    @italic_angle : Float32 = 0.0_f32
    @underline_position : Int16 = 0
    @underline_thickness : Int16 = 0
    @is_fixed_pitch : UInt32 = 0
    @min_mem_type42 : UInt32 = 0
    @max_mem_type42 : UInt32 = 0
    @min_mem_type1 : UInt32 = 0
    @max_mem_type1 : UInt32 = 0

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement postscript table reading
    end
  end

  # Naming table.
  #
  # Ported from Apache PDFBox NamingTable.
  class NamingTable < TTFTable
    # Tag for this table.
    TAG = "name"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement naming table reading
    end
  end

  # CFF table (Compact Font Format).
  #
  # Ported from Apache PDFBox CFFTable.
  class CFFTable < TTFTable
    # Tag for this table.
    TAG = "CFF "

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement CFF table reading
    end
  end
end

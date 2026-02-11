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
  # The OS/2 and Windows Metrics Table in a TrueType font.
  #
  # Ported from Apache PDFBox OS2WindowsMetricsTable.
  class OS2WindowsMetricsTable < TTFTable
    # Tag for this table.
    TAG = "OS/2"

    # Weight class constant.
    WEIGHT_CLASS_THIN = 100
    # Weight class constant.
    WEIGHT_CLASS_ULTRA_LIGHT = 200
    # Weight class constant.
    WEIGHT_CLASS_LIGHT = 300
    # Weight class constant.
    WEIGHT_CLASS_NORMAL = 400
    # Weight class constant.
    WEIGHT_CLASS_MEDIUM = 500
    # Weight class constant.
    WEIGHT_CLASS_SEMI_BOLD = 600
    # Weight class constant.
    WEIGHT_CLASS_BOLD = 700
    # Weight class constant.
    WEIGHT_CLASS_EXTRA_BOLD = 800
    # Weight class constant.
    WEIGHT_CLASS_BLACK = 900

    @version : UInt16 = 0
    @x_avg_char_width : Int16 = 0
    @weight_class : UInt16 = 0
    @width_class : UInt16 = 0
    @fs_type : UInt16 = 0
    @y_subscript_x_size : Int16 = 0
    @y_subscript_y_size : Int16 = 0
    @y_subscript_x_offset : Int16 = 0
    @y_subscript_y_offset : Int16 = 0
    @y_superscript_x_size : Int16 = 0
    @y_superscript_y_size : Int16 = 0
    @y_superscript_x_offset : Int16 = 0
    @y_superscript_y_offset : Int16 = 0
    @y_strikeout_size : Int16 = 0
    @y_strikeout_position : Int16 = 0
    @s_family_class : Int16 = 0
    @panose : Bytes = Bytes.new(10)
    @unicode_range1 : UInt32 = 0
    @unicode_range2 : UInt32 = 0
    @unicode_range3 : UInt32 = 0
    @unicode_range4 : UInt32 = 0
    @ach_vendor_id : String = ""
    @fs_selection : UInt16 = 0
    @fs_first_char_index : UInt16 = 0
    @fs_last_char_index : UInt16 = 0
    @typo_ascender : Int16 = 0
    @typo_descender : Int16 = 0
    @typo_line_gap : Int16 = 0
    @win_ascent : UInt16 = 0
    @win_descent : UInt16 = 0
    @code_page_range1 : UInt32 = 0
    @code_page_range2 : UInt32 = 0
    @sx_height : Int16 = 0
    @s_cap_height : Int16 = 0
    @us_default_char : UInt16 = 0
    @us_break_char : UInt16 = 0
    @us_max_context : UInt16 = 0

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement OS/2 table reading
    end

    # This will read required headers from the stream into out_headers.
    def read_headers(ttf : TrueTypeFont, data : TTFDataStream, out_headers : FontHeaders) : Nil
      # TODO: Implement OS/2 table header reading
    end
  end
end

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

require "./text_position"

module Pdfbox::Text
  # Comparator for TextPosition operators. It handles pages with text in
  # different directions by grouping the text based on direction and sorting
  # in that direction, so continuous text in a given direction is grouped
  # together.
  # Corresponds to org.apache.pdfbox.text.TextPositionComparator.
  class TextPositionComparator
    def compare(pos1 : TextPosition, pos2 : TextPosition) : Int32
      # only compare text that is in the same direction
      cmp1 = float_compare(pos1.dir, pos2.dir)
      return cmp1 if cmp1 != 0

      # get the text direction adjusted coordinates
      x1 = pos1.x_dir_adj
      x2 = pos2.x_dir_adj

      pos1_y_bottom = pos1.y_dir_adj
      pos2_y_bottom = pos2.y_dir_adj

      # note that the coordinates have been adjusted so 0,0 is in upper left
      pos1_y_top = pos1_y_bottom - pos1.height_dir
      pos2_y_top = pos2_y_bottom - pos2.height_dir

      y_difference = (pos1_y_bottom - pos2_y_bottom).abs

      # we will do a simple tolerance comparison
      if y_difference < 0.1_f32 ||
         (pos2_y_bottom >= pos1_y_top && pos2_y_bottom <= pos1_y_bottom) ||
         (pos1_y_bottom >= pos2_y_top && pos1_y_bottom <= pos2_y_bottom)
        float_compare(x1, x2)
      elsif pos1_y_bottom < pos2_y_bottom
        -1
      else
        1
      end
    end

    # Matches Java Float.compare: NaN == NaN is 0.
    private def float_compare(left : Float32, right : Float32) : Int32
      return 0 if left == right
      return 0 if left.nan? && right.nan?
      return 1 if left.nan?
      return -1 if right.nan?

      if left < right
        -1
      else
        1
      end
    end
  end
end

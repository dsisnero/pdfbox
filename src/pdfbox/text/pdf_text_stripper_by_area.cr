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

require "./pdf_text_stripper"
require "../../fontbox/util/rectangle2d"

module Pdfbox::Text
  # Corresponds to org.apache.pdfbox.text.PDFTextStripperByArea.
  class PDFTextStripperByArea < PDFTextStripper
    @regions = [] of String
    @region_area = {} of String => Fontbox::Util::Rectangle2D
    @region_text = {} of String => String

    def initialize
      super()
    end

    def should_separate_by_beads=(value : Bool) : Nil
    end

    def add_region(region_name : String, rect : Fontbox::Util::Rectangle2D) : Nil
      @regions << region_name
      @region_area[region_name] = rect
    end

    def remove_region(region_name : String) : Nil
      @regions.delete(region_name)
      @region_area.delete(region_name)
      @region_text.delete(region_name)
    end

    def regions : Array(String)
      @regions
    end

    def get_text_for_region(region_name : String) : String
      @region_text[region_name]? || ""
    end

    def extract_regions(page : Pdfbox::Pdmodel::Page) : Nil
      @region_text.clear
      return unless page.has_contents?

      collected_text_positions.clear
      process_page(page)

      @regions.each do |region_name|
        rect = @region_area[region_name]? || next
        region_positions = [] of TextPosition
        line_groups_for(ordered_text_positions(collected_text_positions)).each do |line|
          next unless line.any? { |text| contains_text_position?(rect, text) }
          region_positions.concat(line)
        end
        @region_text[region_name] = render_text_positions(region_positions)
      end
    end

    private def contains_text_position?(rect : Fontbox::Util::Rectangle2D, text : TextPosition) : Bool
      text_left = text.x.to_f64
      text_right = text_left + text.width.to_f64
      text_top = text.y.to_f64
      text_bottom = text.y.to_f64 + text.height.to_f64
      rect_right = rect.x + rect.width
      lower_tolerance = 1.5_f64
      rect_top = rect.y - lower_tolerance
      rect_bottom = rect.y + rect.height + lower_tolerance
      vertical_match = (text_top >= rect_top && text_top <= rect_bottom) ||
                       (text_bottom >= rect_top && text_bottom <= rect_bottom)

      text_right >= rect.x && text_left <= rect_right &&
        vertical_match
    end
  end
end

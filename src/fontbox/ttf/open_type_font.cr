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
  class OpenTypeFont < TrueTypeFont
    def glyph : GlyphTable?
      raise IO::Error.new("OTF fonts do not have a glyf table") if post_script?
      super
    end

    def path(name : String) : Fontbox::Util::Path
      if post_script? && supported_otf?
        gid = name_to_gid(name)
        return Fontbox::Util::Path.new if gid < 0
        cff_font = cff.font
        return Fontbox::Util::Path.new unless cff_font

        case cff_font
        when Fontbox::CFF::CFFCIDFont
          cff_font.path(gid)
        when Fontbox::CFF::CFFType1Font
          cff_font.path(name)
        else
          Fontbox::Util::Path.new
        end
      else
        gid = name_to_gid(name)
        return Fontbox::Util::Path.new if gid <= 0 || gid >= number_of_glyphs

        glyph_data = glyph.try(&.glyph(gid))
        glyph_data ? glyph_data.path : Fontbox::Util::Path.new
      end
    rescue
      Fontbox::Util::Path.new
    end

    def post_script? : Bool
      table_map.has_key?(CFFTable::TAG) || table_map.has_key?("CFF2")
    end

    def supported_otf? : Bool
      !(post_script? && !table_map.has_key?(CFFTable::TAG) && table_map.has_key?("CFF2"))
    end

    def has_layout_tables? : Bool
      table_map.has_key?("BASE") ||
        table_map.has_key?("GDEF") ||
        table_map.has_key?("GPOS") ||
        table_map.has_key?(GlyphSubstitutionTable::TAG) ||
        table_map.has_key?(OTLTable::TAG)
    end

    def cff : CFFTable
      raise IO::Error.new("TTF fonts do not have a CFF table") unless post_script?
      table(CFFTable::TAG).as(CFFTable)
    end
  end
end

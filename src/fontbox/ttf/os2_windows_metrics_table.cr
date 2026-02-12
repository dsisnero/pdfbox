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

    # Width class constant.
    WIDTH_CLASS_ULTRA_CONDENSED = 1
    # Width class constant.
    WIDTH_CLASS_EXTRA_CONDENSED = 2
    # Width class constant.
    WIDTH_CLASS_CONDENSED = 3
    # Width class constant.
    WIDTH_CLASS_SEMI_CONDENSED = 4
    # Width class constant.
    WIDTH_CLASS_MEDIUM = 5
    # Width class constant.
    WIDTH_CLASS_SEMI_EXPANDED = 6
    # Width class constant.
    WIDTH_CLASS_EXPANDED = 7
    # Width class constant.
    WIDTH_CLASS_EXTRA_EXPANDED = 8
    # Width class constant.
    WIDTH_CLASS_ULTRA_EXPANDED = 9

    # Family class constant.
    FAMILY_CLASS_NO_CLASSIFICATION = 0
    # Family class constant.
    FAMILY_CLASS_OLDSTYLE_SERIFS = 1
    # Family class constant.
    FAMILY_CLASS_TRANSITIONAL_SERIFS = 2
    # Family class constant.
    FAMILY_CLASS_MODERN_SERIFS = 3
    # Family class constant.
    FAMILY_CLASS_CLAREDON_SERIFS = 4
    # Family class constant.
    FAMILY_CLASS_SLAB_SERIFS = 5
    # Family class constant.
    FAMILY_CLASS_FREEFORM_SERIFS = 7
    # Family class constant.
    FAMILY_CLASS_SANS_SERIF = 8
    # Family class constant.
    FAMILY_CLASS_ORNAMENTALS = 9
    # Family class constant.
    FAMILY_CLASS_SCRIPTS = 10
    # Family class constant.
    FAMILY_CLASS_SYMBOLIC = 12

    # Restricted License embedding: must not be modified, embedded or exchanged in any manner.
    #
    # <p>For Restricted License embedding to take effect, it must be the only level of embedding
    # selected.
    FSTYPE_RESTRICTED = 0x0002

    # Preview and Print embedding: the font may be embedded, and temporarily loaded on the
    # remote system. No edits can be applied to the document.
    FSTYPE_PREVIEW_AND_PRINT = 0x0004

    # Editable embedding: the font may be embedded but must only be installed temporarily on other
    # systems. Documents may be edited and changes saved.
    FSTYPE_EDITIBLE = 0x0008

    # No subsetting: the font must not be subsetted prior to embedding.
    FSTYPE_NO_SUBSETTING = 0x0100

    # Bitmap embedding only: only bitmaps contained in the font may be embedded. No outline data
    # may be embedded. Other embedding restrictions specified in bits 0-3 and 8 also apply.
    FSTYPE_BITMAP_ONLY = 0x0200

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
      @version = data.read_unsigned_short.to_u16
      @x_avg_char_width = data.read_signed_short
      @weight_class = data.read_unsigned_short.to_u16
      @width_class = data.read_unsigned_short.to_u16
      @fs_type = data.read_signed_short.to_u16
      @y_subscript_x_size = data.read_signed_short
      @y_subscript_y_size = data.read_signed_short
      @y_subscript_x_offset = data.read_signed_short
      @y_subscript_y_offset = data.read_signed_short
      @y_superscript_x_size = data.read_signed_short
      @y_superscript_y_size = data.read_signed_short
      @y_superscript_x_offset = data.read_signed_short
      @y_superscript_y_offset = data.read_signed_short
      @y_strikeout_size = data.read_signed_short
      @y_strikeout_position = data.read_signed_short
      @s_family_class = data.read_signed_short
      @panose = data.read(10)
      @unicode_range1 = data.read_unsigned_int.to_u32
      @unicode_range2 = data.read_unsigned_int.to_u32
      @unicode_range3 = data.read_unsigned_int.to_u32
      @unicode_range4 = data.read_unsigned_int.to_u32
      @ach_vendor_id = data.read_string(4)
      @fs_selection = data.read_unsigned_short.to_u16
      @fs_first_char_index = data.read_unsigned_short.to_u16
      @fs_last_char_index = data.read_unsigned_short.to_u16

      begin
        @typo_ascender = data.read_signed_short
        @typo_descender = data.read_signed_short
        @typo_line_gap = data.read_signed_short
        @win_ascent = data.read_unsigned_short.to_u16
        @win_descent = data.read_unsigned_short.to_u16
      rescue ex : IO::EOFError
        # TODO: Log debug "EOF, probably some legacy TrueType font"
        @initialized = true
        return
      end

      if @version >= 1
        begin
          @code_page_range1 = data.read_unsigned_int.to_u32
          @code_page_range2 = data.read_unsigned_int.to_u32
        rescue ex : IO::EOFError
          @version = 0_u16
          # TODO: Log warn "Could not read all expected parts of version >= 1, setting version to 0"
          @initialized = true
          return
        end
      end

      if @version >= 2
        begin
          @sx_height = data.read_signed_short
          @s_cap_height = data.read_signed_short
          @us_default_char = data.read_unsigned_short.to_u16
          @us_break_char = data.read_unsigned_short.to_u16
          @us_max_context = data.read_unsigned_short.to_u16
        rescue ex : IO::EOFError
          @version = 1_u16
          # TODO: Log warn "Could not read all expected parts of version >= 2, setting version to 1"
          @initialized = true
          return
        end
      end

      @initialized = true
    end

    # This will read required headers from the stream into out_headers.
    def read_headers(ttf : TrueTypeFont, data : TTFDataStream, out_headers : FontHeaders) : Nil
      out_headers.os2_windows = self
    end

    # Gets the version.
    def version : UInt16
      @version
    end

    # Gets the average character width.
    def average_char_width : Int16
      @x_avg_char_width
    end

    # Gets the weight class.
    def weight_class : UInt16
      @weight_class
    end

    # Gets the width class.
    def width_class : UInt16
      @width_class
    end

    # Gets the fs type.
    def fs_type : UInt16
      @fs_type
    end

    # Gets the subscript x size.
    def subscript_x_size : Int16
      @y_subscript_x_size
    end

    # Gets the subscript y size.
    def subscript_y_size : Int16
      @y_subscript_y_size
    end

    # Gets the subscript x offset.
    def subscript_x_offset : Int16
      @y_subscript_x_offset
    end

    # Gets the subscript y offset.
    def subscript_y_offset : Int16
      @y_subscript_y_offset
    end

    # Gets the superscript x size.
    def superscript_x_size : Int16
      @y_superscript_x_size
    end

    # Gets the superscript y size.
    def superscript_y_size : Int16
      @y_superscript_y_size
    end

    # Gets the superscript x offset.
    def superscript_x_offset : Int16
      @y_superscript_x_offset
    end

    # Gets the superscript y offset.
    def superscript_y_offset : Int16
      @y_superscript_y_offset
    end

    # Gets the strikeout size.
    def strikeout_size : Int16
      @y_strikeout_size
    end

    # Gets the strikeout position.
    def strikeout_position : Int16
      @y_strikeout_position
    end

    # Gets the family class.
    def family_class : Int16
      @s_family_class
    end

    # Gets the panose bytes.
    def panose : Bytes
      @panose
    end

    # Gets the unicode range 1.
    def unicode_range1 : UInt32
      @unicode_range1
    end

    # Gets the unicode range 2.
    def unicode_range2 : UInt32
      @unicode_range2
    end

    # Gets the unicode range 3.
    def unicode_range3 : UInt32
      @unicode_range3
    end

    # Gets the unicode range 4.
    def unicode_range4 : UInt32
      @unicode_range4
    end

    # Gets the vendor id.
    def vendor_id : String
      @ach_vendor_id
    end

    # Gets the fs selection.
    def fs_selection : UInt16
      @fs_selection
    end

    # Gets the first character index.
    def first_char_index : UInt16
      @fs_first_char_index
    end

    # Gets the last character index.
    def last_char_index : UInt16
      @fs_last_char_index
    end

    # Gets the typographic ascender.
    def typo_ascender : Int16
      @typo_ascender
    end

    # Gets the typographic descender.
    def typo_descender : Int16
      @typo_descender
    end

    # Gets the typographic line gap.
    def typo_line_gap : Int16
      @typo_line_gap
    end

    # Gets the windows ascent.
    def win_ascent : UInt16
      @win_ascent
    end

    # Gets the windows descent.
    def win_descent : UInt16
      @win_descent
    end

    # Gets the code page range 1.
    def code_page_range1 : UInt32
      @code_page_range1
    end

    # Gets the code page range 2.
    def code_page_range2 : UInt32
      @code_page_range2
    end

    # Gets the sx height.
    def sx_height : Int16
      @sx_height
    end

    # Gets the cap height.
    def cap_height : Int16
      @s_cap_height
    end

    # Gets the default character.
    def default_char : UInt16
      @us_default_char
    end

    # Gets the break character.
    def break_char : UInt16
      @us_break_char
    end

    # Gets the maximum context.
    def max_context : UInt16
      @us_max_context
    end
  end
end

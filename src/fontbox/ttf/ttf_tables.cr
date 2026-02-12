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

require "./gsub/glyph_substitution_data_extractor"

# ameba:disable Naming/AccessorMethodName
module Fontbox::TTF
  # Header table.
  #
  # Ported from Apache PDFBox HeaderTable.
  class HeaderTable < TTFTable
    # Tag for this table.
    TAG = "head"

    # Bold macStyle flag.
    MAC_STYLE_BOLD = 1

    # Italic macStyle flag.
    MAC_STYLE_ITALIC = 2

    @version : Float32 = 0.0_f32
    @font_revision : Float32 = 0.0_f32
    @check_sum_adjustment : UInt64 = 0
    @magic_number : UInt64 = 0
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
      @version = data.read_32_fixed
      @font_revision = data.read_32_fixed
      @check_sum_adjustment = data.read_unsigned_int
      @magic_number = data.read_unsigned_int
      @flags = data.read_unsigned_short.to_u16
      @units_per_em = data.read_unsigned_short.to_u16
      @created = data.read_international_date
      @modified = data.read_international_date
      @x_min = data.read_signed_short
      @y_min = data.read_signed_short
      @x_max = data.read_signed_short
      @y_max = data.read_signed_short
      @mac_style = data.read_unsigned_short.to_u16
      @lowest_rec_ppem = data.read_unsigned_short.to_u16
      @font_direction_hint = data.read_signed_short
      @index_to_loc_format = data.read_signed_short
      @glyph_data_format = data.read_signed_short
      @initialized = true
    end

    # This will read required headers from the stream into out_headers.
    def read_headers(ttf : TrueTypeFont, data : TTFDataStream, out_headers : FontHeaders) : Nil
      # 44 == 4 + 4 + 4 + 4 + 2 + 2 + 2*8 + 4*2, see read()
      data.seek(data.current_position + 44)
      @mac_style = data.read_unsigned_short.to_u16
      out_headers.set_header_mac_style(@mac_style.to_i32)
    end

    # Gets the mac style flags.
    def get_mac_style : UInt16
      @mac_style
    end

    # Gets the check sum adjustment.
    def get_check_sum_adjustment : UInt64
      @check_sum_adjustment
    end

    # Gets the created date.
    def get_created : Time
      @created
    end

    # Gets the flags.
    def get_flags : UInt16
      @flags
    end

    # Gets the font direction hint.
    def get_font_direction_hint : Int16
      @font_direction_hint
    end

    # Gets the font revision.
    def get_font_revision : Float32
      @font_revision
    end

    # Gets the glyph data format.
    def get_glyph_data_format : Int16
      @glyph_data_format
    end

    # Gets the index to location format.
    def index_to_loc_format : Int16
      @index_to_loc_format
    end

    # Gets the lowest recommended PPEM.
    def get_lowest_rec_ppem : UInt16
      @lowest_rec_ppem
    end

    # Gets the magic number.
    def get_magic_number : UInt64
      @magic_number
    end

    # Gets the modified date.
    def get_modified : Time
      @modified
    end

    # Gets the units per em.
    def units_per_em : UInt16
      @units_per_em
    end

    # Gets the x max.
    def get_x_max : Int16
      @x_max
    end

    # Gets the x min.
    def get_x_min : Int16
      @x_min
    end

    # Gets the y max.
    def get_y_max : Int16
      @y_max
    end

    # Gets the y min.
    def get_y_min : Int16
      @y_min
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
      @version = data.read_32_fixed
      @ascender = data.read_signed_short
      @descender = data.read_signed_short
      @line_gap = data.read_signed_short
      @advance_width_max = data.read_unsigned_short.to_u16
      @min_left_side_bearing = data.read_signed_short
      @min_right_side_bearing = data.read_signed_short
      @x_max_extent = data.read_signed_short
      @caret_slope_rise = data.read_signed_short
      @caret_slope_run = data.read_signed_short
      @reserved1 = data.read_signed_short
      @reserved2 = data.read_signed_short
      @reserved3 = data.read_signed_short
      @reserved4 = data.read_signed_short
      @caret_offset = data.read_signed_short # reserved5 in Java
      @metric_data_format = data.read_signed_short
      @number_of_h_metrics = data.read_unsigned_short.to_u16
      @initialized = true
    end

    # Gets the version.
    def get_version : Float32
      @version
    end

    # Gets the ascender.
    def get_ascender : Int16
      @ascender
    end

    # Gets the descender.
    def get_descender : Int16
      @descender
    end

    # Gets the line gap.
    def get_line_gap : Int16
      @line_gap
    end

    # Gets the advance width max.
    def get_advance_width_max : UInt16
      @advance_width_max
    end

    # Gets the minimum left side bearing.
    def get_min_left_side_bearing : Int16
      @min_left_side_bearing
    end

    # Gets the minimum right side bearing.
    def get_min_right_side_bearing : Int16
      @min_right_side_bearing
    end

    # Gets the x max extent.
    def get_x_max_extent : Int16
      @x_max_extent
    end

    # Gets the caret slope rise.
    def get_caret_slope_rise : Int16
      @caret_slope_rise
    end

    # Gets the caret slope run.
    def get_caret_slope_run : Int16
      @caret_slope_run
    end

    # Gets the caret offset.
    def get_caret_offset : Int16
      @caret_offset
    end

    # Gets the metric data format.
    def get_metric_data_format : Int16
      @metric_data_format
    end

    # Gets the number of horizontal metrics.
    def number_of_h_metrics : UInt16
      @number_of_h_metrics
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
      @version = data.read_32_fixed
      @num_glyphs = data.read_unsigned_short.to_u16
      if @version >= 1.0_f32
        @max_points = data.read_unsigned_short.to_u16
        @max_contours = data.read_unsigned_short.to_u16
        @max_composite_points = data.read_unsigned_short.to_u16
        @max_composite_contours = data.read_unsigned_short.to_u16
        @max_zones = data.read_unsigned_short.to_u16
        @max_twilight_points = data.read_unsigned_short.to_u16
        @max_storage = data.read_unsigned_short.to_u16
        @max_function_defs = data.read_unsigned_short.to_u16
        @max_instruction_defs = data.read_unsigned_short.to_u16
        @max_stack_elements = data.read_unsigned_short.to_u16
        @max_size_of_instructions = data.read_unsigned_short.to_u16
        @max_component_elements = data.read_unsigned_short.to_u16
        @max_component_depth = data.read_unsigned_short.to_u16
      end
      @initialized = true
    end

    # Gets the number of glyphs.
    def num_glyphs : UInt16
      @num_glyphs
    end

    # Gets the version.
    def get_version : Float32
      @version
    end

    # Gets the maximum points.
    def get_max_points : UInt16
      @max_points
    end

    # Gets the maximum contours.
    def get_max_contours : UInt16
      @max_contours
    end

    # Gets the maximum composite points.
    def get_max_composite_points : UInt16
      @max_composite_points
    end

    # Gets the maximum composite contours.
    def get_max_composite_contours : UInt16
      @max_composite_contours
    end

    # Gets the maximum zones.
    def get_max_zones : UInt16
      @max_zones
    end

    # Gets the maximum twilight points.
    def get_max_twilight_points : UInt16
      @max_twilight_points
    end

    # Gets the maximum storage.
    def get_max_storage : UInt16
      @max_storage
    end

    # Gets the maximum function definitions.
    def get_max_function_defs : UInt16
      @max_function_defs
    end

    # Gets the maximum instruction definitions.
    def get_max_instruction_defs : UInt16
      @max_instruction_defs
    end

    # Gets the maximum stack elements.
    def get_max_stack_elements : UInt16
      @max_stack_elements
    end

    # Gets the maximum size of instructions.
    def get_max_size_of_instructions : UInt16
      @max_size_of_instructions
    end

    # Gets the maximum component elements.
    def get_max_component_elements : UInt16
      @max_component_elements
    end

    # Gets the maximum component depth.
    def get_max_component_depth : UInt16
      @max_component_depth
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
    @is_fixed_pitch : UInt64 = 0
    @min_mem_type42 : UInt64 = 0
    @max_mem_type42 : UInt64 = 0
    @min_mem_type1 : UInt64 = 0
    @max_mem_type1 : UInt64 = 0
    @glyph_names : Array(String)? = nil

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      @format_type = data.read_32_fixed
      @italic_angle = data.read_32_fixed
      @underline_position = data.read_signed_short
      @underline_thickness = data.read_signed_short
      @is_fixed_pitch = data.read_unsigned_int
      @min_mem_type42 = data.read_unsigned_int
      @max_mem_type42 = data.read_unsigned_int
      @min_mem_type1 = data.read_unsigned_int
      @max_mem_type1 = data.read_unsigned_int

      if data.current_position == data.original_data_size
        # TODO: Log warning - No PostScript name data is provided for the font
        # LOG.warn("No PostScript name data is provided for the font #{ttf.get_name}")
      elsif @format_type == 1.0_f32
        # This TrueType font file contains exactly the 258 glyphs in the standard Macintosh TrueType.
        @glyph_names = WGL4Names.get_all_names
      elsif @format_type == 2.0_f32
        num_glyphs = data.read_unsigned_short.to_i32
        glyph_name_index = Array(Int32).new(num_glyphs)
        @glyph_names = Array.new(num_glyphs, ".undefined")
        max_index = Int32::MIN
        num_glyphs.times do |_|
          index = data.read_unsigned_short.to_i32
          glyph_name_index << index
          # PDFBOX-808: Index numbers between 32768 and 65535 are
          # reserved for future use, so we should just ignore them
          if index <= 32767
            max_index = Math.max(max_index, index)
          end
        end
        name_array : Array(String)? = nil
        if max_index >= WGL4Names::NUMBER_OF_MAC_GLYPHS
          name_array_size = max_index - WGL4Names::NUMBER_OF_MAC_GLYPHS + 1
          name_array = Array(String).new(name_array_size)
          name_array_size.times do |i|
            number_of_chars = data.read_unsigned_byte
            begin
              name_array << data.read_string(number_of_chars)
            rescue ex : IO::EOFError
              # PDFBOX-4851: EOF
              # TODO: Log warning
              # LOG.warn("Error reading names in PostScript table at entry #{i} of #{name_array_size}, setting remaining entries to .notdef")
              (name_array_size - i).times do
                name_array << ".notdef"
              end
              break
            end
          end
        end
        num_glyphs.times do |i|
          index = glyph_name_index[i]
          if index >= 0 && index < WGL4Names::NUMBER_OF_MAC_GLYPHS
            @glyph_names.as(Array(String))[i] = WGL4Names.get_glyph_name(index) || ".undefined"
          elsif index >= WGL4Names::NUMBER_OF_MAC_GLYPHS && index <= 32767 && !name_array.nil?
            @glyph_names.as(Array(String))[i] = name_array.as(Array(String))[index - WGL4Names::NUMBER_OF_MAC_GLYPHS]
          else
            # PDFBOX-808: Index numbers between 32768 and 65535 are
            # reserved for future use, so we should just ignore them
            @glyph_names.as(Array(String))[i] = ".undefined"
          end
        end
      elsif @format_type == 2.5_f32
        num_glyphs = ttf.number_of_glyphs
        if num_glyphs <= 0
          # TODO: Log error - invalid number of glyphs
        else
          glyph_name_index = Array(Int32).new(num_glyphs)
          num_glyphs.times do |i|
            offset = data.read_signed_byte
            glyph_name_index << i + 1 + offset
          end
          @glyph_names = Array.new(num_glyphs, ".undefined")
          num_glyphs.times do |i|
            index = glyph_name_index[i]
            if index >= 0 && index < WGL4Names::NUMBER_OF_MAC_GLYPHS
              name = WGL4Names.get_glyph_name(index)
              if !name.nil?
                @glyph_names.as(Array(String))[i] = name
              end
            else
              # TODO: Log debug
              # LOG.debug("incorrect glyph name index #{index}, valid numbers 0..#{WGL4Names::NUMBER_OF_MAC_GLYPHS}")
            end
          end
        end
      elsif @format_type == 3.0_f32
        # no postscript information is provided.
        # TODO: Log debug
        # LOG.debug("No PostScript name information is provided for the font #{ttf.get_name}")
      end
      @initialized = true
    end

    # Gets the format type.
    def get_format_type : Float32
      @format_type
    end

    # Gets the italic angle.
    def get_italic_angle : Float32
      @italic_angle
    end

    # Gets the underline position.
    def get_underline_position : Int16
      @underline_position
    end

    # Gets the underline thickness.
    def get_underline_thickness : Int16
      @underline_thickness
    end

    # Gets the is fixed pitch flag.
    def get_is_fixed_pitch : UInt64
      @is_fixed_pitch
    end

    # Gets the minimum memory type 42.
    def get_min_mem_type42 : UInt64
      @min_mem_type42
    end

    # Gets the maximum memory type 42.
    def get_max_mem_type42 : UInt64
      @max_mem_type42
    end

    # Gets the minimum memory type 1.
    def get_min_mem_type1 : UInt64
      @min_mem_type1
    end

    # Gets the maximum memory type 1.
    def get_max_mem_type1 : UInt64
      @max_mem_type1
    end

    # Gets the glyph names.
    def get_glyph_names : Array(String)?
      @glyph_names
    end

    # Returns the glyph name of the given GID.
    #
    # @param gid the GID of the glyph name
    # @return the glyph name for the given glyph name or nil
    def get_name(gid : Int32) : String?
      if gid < 0 || @glyph_names.nil? || gid >= @glyph_names.as(Array(String)).size
        return
      end
      @glyph_names.as(Array(String))[gid]
    end
  end

  # A name record in the name table.
  #
  # Ported from Apache PDFBox NameRecord.
  class NameRecord
    # platform ids
    PLATFORM_UNICODE   = 0
    PLATFORM_MACINTOSH = 1
    PLATFORM_ISO       = 2
    PLATFORM_WINDOWS   = 3

    # Unicode encoding ids
    ENCODING_UNICODE_1_0      = 0
    ENCODING_UNICODE_1_1      = 1
    ENCODING_UNICODE_2_0_BMP  = 3
    ENCODING_UNICODE_2_0_FULL = 4

    # Unicode encoding ids
    LANGUAGE_UNICODE = 0

    # Windows encoding ids
    ENCODING_WINDOWS_SYMBOL       =  0
    ENCODING_WINDOWS_UNICODE_BMP  =  1
    ENCODING_WINDOWS_UNICODE_UCS4 = 10

    # Windows language ids
    LANGUAGE_WINDOWS_EN_US = 0x0409

    # Macintosh encoding ids
    ENCODING_MACINTOSH_ROMAN = 0

    # Macintosh language ids
    LANGUAGE_MACINTOSH_ENGLISH = 0

    # name ids
    NAME_COPYRIGHT            = 0
    NAME_FONT_FAMILY_NAME     = 1
    NAME_FONT_SUB_FAMILY_NAME = 2
    NAME_UNIQUE_FONT_ID       = 3
    NAME_FULL_FONT_NAME       = 4
    NAME_VERSION              = 5
    NAME_POSTSCRIPT_NAME      = 6
    NAME_TRADEMARK            = 7

    @platform_id : Int32 = 0
    @platform_encoding_id : Int32 = 0
    @language_id : Int32 = 0
    @name_id : Int32 = 0
    @string_length : Int32 = 0
    @string_offset : Int32 = 0
    @string : String? = nil

    # This will read the required data from the stream.
    def init_data(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      @platform_id = data.read_unsigned_short.to_i32
      @platform_encoding_id = data.read_unsigned_short.to_i32
      @language_id = data.read_unsigned_short.to_i32
      @name_id = data.read_unsigned_short.to_i32
      @string_length = data.read_unsigned_short.to_i32
      @string_offset = data.read_unsigned_short.to_i32
    end

    def platform_id : Int32
      @platform_id
    end

    def platform_encoding_id : Int32
      @platform_encoding_id
    end

    def language_id : Int32
      @language_id
    end

    def name_id : Int32
      @name_id
    end

    def string_length : Int32
      @string_length
    end

    def string_offset : Int32
      @string_offset
    end

    def string : String?
      @string
    end

    def string=(string_value : String?)
      @string = string_value
    end
  end

  # Naming table.
  #
  # Ported from Apache PDFBox NamingTable.
  class NamingTable < TTFTable
    # Tag for this table.
    TAG = "name"

    @name_records : Array(NameRecord) = [] of NameRecord
    @lookup_table : Hash(Int32, Hash(Int32, Hash(Int32, Hash(Int32, String)))) = Hash(Int32, Hash(Int32, Hash(Int32, Hash(Int32, String)))).new
    @font_family : String? = nil
    @font_sub_family : String? = nil
    @ps_name : String? = nil

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      read_internal(ttf, data, false)
      @initialized = true
    end

    # This will read required headers from the stream into out_headers.
    def read_headers(ttf : TrueTypeFont, data : TTFDataStream, out_headers : FontHeaders) : Nil
      read_internal(ttf, data, true)
      out_headers.set_name(@ps_name) if @ps_name
      out_headers.set_font_family(@font_family, @font_sub_family) if @font_family
    end

    private def read_internal(ttf : TrueTypeFont, data : TTFDataStream, only_headers : Bool) : Nil
      _format_selector = data.read_unsigned_short.to_i32
      number_of_name_records = data.read_unsigned_short.to_i32
      _offset_to_start_of_string_storage = data.read_unsigned_short.to_i32

      @name_records = [] of NameRecord
      number_of_name_records.times do |_|
        nr = NameRecord.new
        nr.init_data(ttf, data)
        if !only_headers || useful_for_only_headers?(nr)
          @name_records << nr
        end
      end

      @name_records.each do |record|
        # don't try to read invalid offsets, see PDFBOX-2608
        if record.string_offset.to_i64 > length
          record.string = nil
          next
        end

        data.seek(offset + (2_i64 * 3) + number_of_name_records.to_i64 * 2_i64 * 6 + record.string_offset.to_i64)
        charset = get_charset(record)
        string = data.read_string(record.string_length, charset)
        record.string = string
      end

      @lookup_table = Hash(Int32, Hash(Int32, Hash(Int32, Hash(Int32, String)))).new
      fill_lookup_table
      read_interesting_strings
    end

    private def get_charset(nr : NameRecord) : String
      platform = nr.platform_id
      encoding = nr.platform_encoding_id
      charset = "ISO-8859-1" # Default to ISO Latin-1

      if platform == NameRecord::PLATFORM_WINDOWS && (encoding == NameRecord::ENCODING_WINDOWS_SYMBOL || encoding == NameRecord::ENCODING_WINDOWS_UNICODE_BMP)
        charset = "UTF-16"
      elsif platform == NameRecord::PLATFORM_UNICODE
        charset = "UTF-16"
      elsif platform == NameRecord::PLATFORM_ISO
        case encoding
        when 0
          charset = "US-ASCII"
        when 1
          # not sure if this is correct??
          charset = "UTF-16BE"
        end
      end
      charset
    end

    private def fill_lookup_table : Nil
      # build multi-dimensional lookup table
      @name_records.each do |record|
        string_value = record.string
        next if string_value.nil?

        # name id
        platform_lookup = @lookup_table[record.name_id] ||= Hash(Int32, Hash(Int32, Hash(Int32, String))).new
        # platform id
        encoding_lookup = platform_lookup[record.platform_id] ||= Hash(Int32, Hash(Int32, String)).new
        # encoding id
        language_lookup = encoding_lookup[record.platform_encoding_id] ||= Hash(Int32, String).new
        # language id / string
        language_lookup[record.language_id] = string_value
      end
    end

    private def read_interesting_strings : Nil
      @font_family = get_english_name(NameRecord::NAME_FONT_FAMILY_NAME)
      @font_sub_family = get_english_name(NameRecord::NAME_FONT_SUB_FAMILY_NAME)

      # extract PostScript name, only these two formats are valid
      @ps_name = get_name(NameRecord::NAME_POSTSCRIPT_NAME,
        NameRecord::PLATFORM_MACINTOSH,
        NameRecord::ENCODING_MACINTOSH_ROMAN,
        NameRecord::LANGUAGE_MACINTOSH_ENGLISH)
      if @ps_name.nil?
        @ps_name = get_name(NameRecord::NAME_POSTSCRIPT_NAME,
          NameRecord::PLATFORM_WINDOWS,
          NameRecord::ENCODING_WINDOWS_UNICODE_BMP,
          NameRecord::LANGUAGE_WINDOWS_EN_US)
      end
      if ps = @ps_name
        @ps_name = ps.strip
      end
    end

    private def useful_for_only_headers?(nr : NameRecord) : Bool
      name_id = nr.name_id
      # see "psName =" and "getEnglishName()"
      if name_id == NameRecord::NAME_POSTSCRIPT_NAME ||
         name_id == NameRecord::NAME_FONT_FAMILY_NAME ||
         name_id == NameRecord::NAME_FONT_SUB_FAMILY_NAME
        language_id = nr.language_id
        return language_id == NameRecord::LANGUAGE_UNICODE ||
          language_id == NameRecord::LANGUAGE_WINDOWS_EN_US
      end
      false
    end

    # Helper to get English names by best effort.
    private def get_english_name(name_id : Int32) : String?
      # Unicode, Full, BMP, 1.1, 1.0
      (4.downto(0)).each do |i|
        name_uni = get_name(name_id,
          NameRecord::PLATFORM_UNICODE,
          i,
          NameRecord::LANGUAGE_UNICODE)
        if !name_uni.nil?
          return name_uni
        end
      end

      # Windows, Unicode BMP, EN-US
      name_win = get_name(name_id,
        NameRecord::PLATFORM_WINDOWS,
        NameRecord::ENCODING_WINDOWS_UNICODE_BMP,
        NameRecord::LANGUAGE_WINDOWS_EN_US)
      if !name_win.nil?
        return name_win
      end

      # Macintosh, Roman, English
      get_name(name_id,
        NameRecord::PLATFORM_MACINTOSH,
        NameRecord::ENCODING_MACINTOSH_ROMAN,
        NameRecord::LANGUAGE_MACINTOSH_ENGLISH)
    end

    # Returns a name from the table, or nil if it does not exist.
    def get_name(name_id : Int32, platform_id : Int32, encoding_id : Int32, language_id : Int32) : String?
      platforms = @lookup_table[name_id]?
      return if platforms.nil?

      encodings = platforms[platform_id]?
      return if encodings.nil?

      languages = encodings[encoding_id]?
      return if languages.nil?

      languages[language_id]?
    end

    # Gets the name records for this naming table.
    def get_name_records : Array(NameRecord)
      @name_records
    end

    # Returns the font family name, in English.
    def get_font_family : String?
      @font_family
    end

    # Returns the font sub family name, in English.
    def get_font_sub_family : String?
      @font_sub_family
    end

    # Returns the PostScript name.
    def get_postscript_name : String?
      @ps_name
    end
  end

  # CFF table (Compact Font Format).
  #
  # Ported from Apache PDFBox CFFTable.
  class CFFTable < TTFTable
    # Tag for this table.
    TAG = "CFF "

    @cff_font : Fontbox::CFF::CFFFont?

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      bytes = data.read(length.to_i32)
      parser = Fontbox::CFF::CFFParser.new
      @cff_font = parser.parse(bytes)[0]?
      @initialized = true
    end

    # This will read required headers from the stream into out_headers.
    def read_headers(ttf : TrueTypeFont, data : TTFDataStream, out_headers : FontHeaders) : Nil
      sub_reader = data.create_sub_view(length)
      reader : Pdfbox::IO::RandomAccessRead
      if sub_reader
        reader = sub_reader
      else
        bytes = data.read(length.to_i32)
        reader = Pdfbox::IO::RandomAccessReadBuffer.new(bytes)
      end
      begin
        cff_font = Fontbox::CFF::CFFParser.new.parse(reader)[0]?
        if cff_font.is_a?(Fontbox::CFF::CFFCIDFont)
          out_headers.set_otf_ros(cff_font.registry, cff_font.ordering, cff_font.supplement)
        end
      ensure
        reader.close
      end
    end

    # Returns the parsed CFF font.
    def get_font : Fontbox::CFF::CFFFont?
      @cff_font
    end
  end

  # A "cmap" subtable.
  #
  # Ported from Apache PDFBox CmapSubtable.
  class CmapSubtable
    include CmapLookup
    # platform
    PLATFORM_UNICODE   = 0
    PLATFORM_MACINTOSH = 1
    PLATFORM_WINDOWS   = 3

    # Mac encodings
    ENCODING_MAC_ROMAN = 0

    # Windows encodings
    ENCODING_WIN_SYMBOL       =  0 # Unicode, non-standard character set
    ENCODING_WIN_UNICODE_BMP  =  1 # Unicode BMP (UCS-2)
    ENCODING_WIN_SHIFT_JIS    =  2
    ENCODING_WIN_BIG5         =  3
    ENCODING_WIN_PRC          =  4
    ENCODING_WIN_WANSUNG      =  5
    ENCODING_WIN_JOHAB        =  6
    ENCODING_WIN_UNICODE_FULL = 10 # Unicode Full (UCS-4)

    # Unicode encodings
    ENCODING_UNICODE_1_0      = 0
    ENCODING_UNICODE_1_1      = 1
    ENCODING_UNICODE_2_0_BMP  = 3
    ENCODING_UNICODE_2_0_FULL = 4

    # Surrogate offsets for format 8
    private LEAD_OFFSET      = 0xD800_i64 - (0x10000_i64 >> 10)
    private SURROGATE_OFFSET = 0x10000_i64 - (0xD800_i64 << 10) - 0xDC00_i64

    @platform_id : Int32 = 0
    @platform_encoding_id : Int32 = 0
    @sub_table_offset : UInt64 = 0
    @glyph_id_to_character_code : Array(Int32)? = nil
    @glyph_id_to_character_code_multiple : Hash(Int32, Array(Int32)) = Hash(Int32, Array(Int32)).new
    @character_code_to_glyph_id : Hash(Int32, Int32) = Hash(Int32, Int32).new

    # Class used to manage CMap format 2 subheaders.
    private record SubHeader, first_code : Int32, entry_count : Int32, id_delta : Int32, id_range_offset : Int32

    # This will read the required data from the stream.
    def init_data(data : TTFDataStream) : Nil
      @platform_id = data.read_unsigned_short.to_i32
      @platform_encoding_id = data.read_unsigned_short.to_i32
      @sub_table_offset = data.read_unsigned_int
    end

    # This will read the required data from the stream.
    def init_subtable(cmap : CmapTable, num_glyphs : Int32, data : TTFDataStream) : Nil
      data.seek(cmap.offset + @sub_table_offset)
      subtable_format = data.read_unsigned_short
      length : UInt64
      version : UInt64
      if subtable_format < 8
        length = data.read_unsigned_short.to_u64
        version = data.read_unsigned_short.to_u64
      else
        # read an other UnsignedShort to read a Fixed32
        data.read_unsigned_short
        length = data.read_unsigned_int
        version = data.read_unsigned_int
      end

      case subtable_format
      when 0
        process_subtype0(data)
      when 2
        process_subtype2(data, num_glyphs)
      when 4
        process_subtype4(data, num_glyphs)
      when 6
        process_subtype6(data, num_glyphs)
      when 8
        process_subtype8(data, num_glyphs)
      when 10
        process_subtype10(data, num_glyphs)
      when 12
        process_subtype12(data, num_glyphs)
      when 13
        process_subtype13(data, num_glyphs)
      when 14
        process_subtype14(data, num_glyphs)
      else
        raise IO::EOFError.new("Unknown cmap format:#{subtable_format}")
      end
    end

    # Getter methods
    def platform_id : Int32
      @platform_id
    end

    def platform_encoding_id : Int32
      @platform_encoding_id
    end

    def sub_table_offset : UInt64
      @sub_table_offset
    end

    def glyph_id_to_character_code : Array(Int32)?
      @glyph_id_to_character_code
    end

    def character_code_to_glyph_id : Hash(Int32, Int32)
      @character_code_to_glyph_id
    end

    # Returns the GlyphId linked with the given character code.
    def get_glyph_id(character_code : Int32) : Int32
      glyph_id = @character_code_to_glyph_id[character_code]?
      glyph_id.nil? ? 0 : glyph_id
    end

    # Returns all possible character codes for the given gid, or nil if there is none.
    def get_char_codes(gid : Int32) : Array(Int32)?
      code = get_char_code(gid)
      return if code == -1
      if code == Int32::MIN
        mapped_values = @glyph_id_to_character_code_multiple[gid]?
        if mapped_values
          codes = mapped_values.dup
          codes.sort!
          codes
        end
      else
        [code]
      end
    end

    private def get_char_code(gid : Int32) : Int32
      return -1 if gid < 0 || @glyph_id_to_character_code.nil? || gid >= @glyph_id_to_character_code.as(Array(Int32)).size
      @glyph_id_to_character_code.as(Array(Int32))[gid]
    end

    # Format-specific processing methods to be implemented
    private def process_subtype0(data : TTFDataStream) : Nil
      glyph_mapping = data.read_unsigned_byte_array(256)
      @glyph_id_to_character_code = new_glyph_id_to_character_code(256)
      @character_code_to_glyph_id = Hash(Int32, Int32).new
      glyph_mapping.each_with_index do |glyph_index, i|
        @glyph_id_to_character_code.as(Array(Int32))[glyph_index] = i
        @character_code_to_glyph_id[i] = glyph_index
      end
    end

    private def process_subtype2(data : TTFDataStream, num_glyphs : Int32) : Nil
      sub_header_keys = Array(Int32).new(256)
      max_sub_header_index = 0
      256.times do |_|
        key = data.read_unsigned_short.to_i32
        sub_header_keys << key
        max_sub_header_index = Math.max(max_sub_header_index, key // 8)
      end

      # Read all SubHeaders to avoid useless seek on DataSource
      sub_headers = Array(SubHeader).new(max_sub_header_index + 1)
      (max_sub_header_index + 1).times do |i|
        first_code = data.read_unsigned_short.to_i32
        entry_count = data.read_unsigned_short.to_i32
        id_delta = data.read_signed_short.to_i32
        id_range_offset = data.read_unsigned_short.to_i32 - (max_sub_header_index + 1 - i - 1) * 8 - 2
        sub_headers << SubHeader.new(first_code, entry_count, id_delta, id_range_offset)
      end
      start_glyph_index_offset = data.current_position
      @glyph_id_to_character_code = new_glyph_id_to_character_code(num_glyphs)
      @character_code_to_glyph_id = Hash(Int32, Int32).new
      if num_glyphs == 0
        # TODO: Log warning - subtable has no glyphs
        # LOG.warn("subtable has no glyphs")
        return
      end
      logged = Set(Int32).new
      max_logging_reached = false
      (max_sub_header_index + 1).times do |i|
        sh = sub_headers[i]
        first_code = sh.first_code
        id_range_offset = sh.id_range_offset
        id_delta = sh.id_delta
        entry_count = sh.entry_count
        data.seek(start_glyph_index_offset + id_range_offset)
        entry_count.times do |j|
          # Compute the Character Code
          char_code = i
          char_code = (char_code << 8) + (first_code + j)

          # Go to the CharacterCode position in the Sub Array of the glyphIndexArray
          # glyphIndexArray contains Unsigned Short so add (j * 2) bytes at the index position
          p = data.read_unsigned_short.to_i32
          # Compute the glyphIndex
          if p > 0
            p = (p + id_delta) % 65536
            if p < 0
              p += 65536
            end
          end

          if p >= num_glyphs
            if !max_logging_reached && !logged.includes?(p)
              # TODO: Log warning
              # LOG.warn("glyphId #{p} for charcode #{char_code} ignored, numGlyphs is #{num_glyphs}")
              logged.add(p)
              if logged.size > 10
                # TODO: Log warning
                # LOG.warn("too many bad glyphIds, more won't be reported for this table")
                max_logging_reached = true
              end
            end
            next
          end

          @glyph_id_to_character_code.as(Array(Int32))[p] = char_code
          @character_code_to_glyph_id[char_code] = p
        end
      end
    end

    private def process_subtype4(data : TTFDataStream, num_glyphs : Int32) : Nil
      seg_count_x2 = data.read_unsigned_short.to_i32
      seg_count = seg_count_x2 // 2
      search_range = data.read_unsigned_short.to_i32
      entry_selector = data.read_unsigned_short.to_i32
      range_shift = data.read_unsigned_short.to_i32
      end_count = data.read_unsigned_short_array(seg_count)
      reserved_pad = data.read_unsigned_short.to_i32
      start_count = data.read_unsigned_short_array(seg_count)
      id_delta = data.read_unsigned_short_array(seg_count)
      id_range_offset_position = data.current_position
      id_range_offset = data.read_unsigned_short_array(seg_count)

      @character_code_to_glyph_id = Hash(Int32, Int32).new
      max_glyph_id = 0

      seg_count.times do |i|
        start = start_count[i].to_i32
        end_val = end_count[i].to_i32
        if start != 65535 && end_val != 65535
          delta = id_delta[i].to_i32
          range_offset = id_range_offset[i].to_i32
          segment_range_offset = id_range_offset_position + (i * 2) + range_offset
          (start..end_val).each do |j|
            if range_offset == 0
              glyph_id = (j + delta) & 0xFFFF
              max_glyph_id = Math.max(glyph_id, max_glyph_id)
              @character_code_to_glyph_id[j] = glyph_id
            else
              glyph_offset = segment_range_offset + ((j - start) * 2)
              data.seek(glyph_offset)
              glyph_index = data.read_unsigned_short.to_i32
              if glyph_index != 0
                glyph_index = (glyph_index + delta) & 0xFFFF
                max_glyph_id = Math.max(glyph_index, max_glyph_id)
                @character_code_to_glyph_id[j] = glyph_index
              end
            end
          end
        end
      end

      if @character_code_to_glyph_id.empty?
        # TODO: Log warning - cmap format 4 subtable is empty
        # LOG.warn("cmap format 4 subtable is empty")
        return
      end
      build_glyph_id_to_character_code_lookup(max_glyph_id)
    end

    private def process_subtype6(data : TTFDataStream, num_glyphs : Int32) : Nil
      first_code = data.read_unsigned_short.to_i32
      entry_count = data.read_unsigned_short.to_i32
      # skip empty tables
      return if entry_count == 0
      @character_code_to_glyph_id = Hash(Int32, Int32).new
      glyph_id_array = data.read_unsigned_short_array(entry_count)
      max_glyph_id = 0
      entry_count.times do |i|
        glyph_id = glyph_id_array[i].to_i32
        max_glyph_id = Math.max(max_glyph_id, glyph_id)
        @character_code_to_glyph_id[first_code + i] = glyph_id
      end
      build_glyph_id_to_character_code_lookup(max_glyph_id)
    end

    private def process_subtype8(data : TTFDataStream, num_glyphs : Int32) : Nil
      # --- is32 is a 65536 BITS array ( = 8192 BYTES)
      is32 = data.read_unsigned_byte_array(8192)
      nb_groups = data.read_unsigned_int

      # --- nb_groups shouldn't be greater than 65536
      if nb_groups > 65536_u64
        raise IO::EOFError.new("CMap ( Subtype8 ) is invalid")
      end

      @glyph_id_to_character_code = new_glyph_id_to_character_code(num_glyphs)
      @character_code_to_glyph_id = Hash(Int32, Int32).new
      if num_glyphs == 0
        # TODO: Log warning - subtable has no glyphs
        # LOG.warn("subtable has no glyphs")
        return
      end
      # -- Read all sub header
      nb_groups.times do |_|
        first_code = data.read_unsigned_int
        end_code = data.read_unsigned_int
        start_glyph = data.read_unsigned_int

        # -- process simple validation
        if first_code > end_code || 0 > first_code
          raise IO::EOFError.new("Range invalid")
        end

        (first_code..end_code).each do |j|
          # -- Convert the Character code in decimal
          if j > Int32::MAX
            raise IO::EOFError.new("[Sub Format 8] Invalid character code #{j}")
          end
          if (j // 8).to_i32 >= is32.size
            raise IO::EOFError.new("[Sub Format 8] Invalid character code #{j}")
          end

          current_char_code : Int32
          if (is32[(j // 8).to_i32] & (1 << (j % 8).to_i32)) == 0
            current_char_code = j.to_i32
          else
            # the character code uses a 32bits format
            # convert it in decimal : see http://www.unicode.org/faq//utf_bom.html#utf16-4
            lead = LEAD_OFFSET + (j >> 10).to_i64
            trail = 0xDC00_i64 + (j & 0x3FF_u64).to_i64

            codepoint = (lead << 10) + trail + SURROGATE_OFFSET
            if codepoint > Int32::MAX
              raise IO::EOFError.new("[Sub Format 8] Invalid character code #{codepoint}")
            end
            current_char_code = codepoint.to_i32
          end

          glyph_index = start_glyph + (j - first_code)
          if glyph_index > num_glyphs || glyph_index > Int32::MAX
            raise IO::EOFError.new("CMap contains an invalid glyph index")
          end

          @glyph_id_to_character_code.as(Array(Int32))[glyph_index.to_i32] = current_char_code
          @character_code_to_glyph_id[current_char_code] = glyph_index.to_i32
        end
      end
    end

    private def process_subtype10(data : TTFDataStream, num_glyphs : Int32) : Nil
      start_code = data.read_unsigned_int
      num_chars = data.read_unsigned_int
      if num_chars > Int32::MAX
        raise IO::EOFError.new("Invalid number of Characters")
      end

      if start_code < 0 || start_code > 0x0010FFFF_u64 || (start_code + num_chars) > 0x0010FFFF_u64 ||
         ((start_code + num_chars) >= 0x0000D800_u64 && (start_code + num_chars) <= 0x0000DFFF_u64)
        raise IO::EOFError.new("Invalid character codes, " +
                               "startCode: 0x#{start_code.to_s(16)}, numChars: #{num_chars}")
      end
    end

    private def process_subtype12(data : TTFDataStream, num_glyphs : Int32) : Nil
      max_glyph_id = 0
      nb_groups = data.read_unsigned_int
      @glyph_id_to_character_code = new_glyph_id_to_character_code(num_glyphs)
      @character_code_to_glyph_id = Hash(Int32, Int32).new
      if num_glyphs == 0
        # TODO: Log warning - subtable has no glyphs
        # LOG.warn("subtable has no glyphs")
        return
      end
      nb_groups.times do |_|
        first_code = data.read_unsigned_int
        end_code = data.read_unsigned_int
        start_glyph = data.read_unsigned_int

        if first_code < 0 || first_code > 0x0010FFFF_u64 ||
           (first_code >= 0x0000D800_u64 && first_code <= 0x0000DFFF_u64)
          raise IO::EOFError.new("Invalid character code 0x#{first_code.to_s(16)}")
        end

        if (end_code > 0 && end_code < first_code) ||
           end_code > 0x0010FFFF_u64 ||
           (end_code >= 0x0000D800_u64 && end_code <= 0x0000DFFF_u64)
          raise IO::EOFError.new("Invalid character code 0x#{end_code.to_s(16)}")
        end

        (0_u64..(end_code - first_code)).each do |j|
          glyph_index = start_glyph + j
          if glyph_index >= num_glyphs
            # TODO: Log warning
            # LOG.warn("Format 12 cmap contains an invalid glyph index")
            break
          end

          if first_code + j > 0x10FFFF_u64
            # TODO: Log warning - Format 12 cmap contains character beyond UCS-4
            # LOG.warn("Format 12 cmap contains character beyond UCS-4")
          end

          max_glyph_id = Math.max(max_glyph_id, glyph_index.to_i32)
          @character_code_to_glyph_id[(first_code + j).to_i32] = glyph_index.to_i32
        end
      end
      build_glyph_id_to_character_code_lookup(max_glyph_id)
    end

    private def process_subtype13(data : TTFDataStream, num_glyphs : Int32) : Nil
      nb_groups = data.read_unsigned_int
      @glyph_id_to_character_code = new_glyph_id_to_character_code(num_glyphs)
      @character_code_to_glyph_id = Hash(Int32, Int32).new
      if num_glyphs == 0
        # TODO: Log warning - subtable has no glyphs
        # LOG.warn("subtable has no glyphs")
        return
      end
      nb_groups.times do |_|
        first_code = data.read_unsigned_int
        end_code = data.read_unsigned_int
        glyph_id = data.read_unsigned_int

        if glyph_id > num_glyphs
          # TODO: Log warning
          # LOG.warn("Format 13 cmap contains an invalid glyph index")
          break
        end

        if first_code < 0 || first_code > 0x0010FFFF_u64 || (first_code >= 0x0000D800_u64 && first_code <= 0x0000DFFF_u64)
          raise IO::EOFError.new("Invalid character code 0x#{first_code.to_s(16)}")
        end

        if (end_code > 0 && end_code < first_code) || end_code > 0x0010FFFF_u64 || (end_code >= 0x0000D800_u64 && end_code <= 0x0000DFFF_u64)
          raise IO::EOFError.new("Invalid character code 0x#{end_code.to_s(16)}")
        end

        (0_u64..(end_code - first_code)).each do |j|
          if first_code + j > Int32::MAX
            raise IO::EOFError.new("Character Code greater than Integer.MAX_VALUE")
          end

          if first_code + j > 0x10FFFF_u64
            # TODO: Log warning - Format 13 cmap contains character beyond UCS-4
            # LOG.warn("Format 13 cmap contains character beyond UCS-4")
          end

          @glyph_id_to_character_code.as(Array(Int32))[glyph_id.to_i32] = (first_code + j).to_i32
          @character_code_to_glyph_id[(first_code + j).to_i32] = glyph_id.to_i32
        end
      end
    end

    private def process_subtype14(data : TTFDataStream, num_glyphs : Int32) : Nil
      # Unicode Variation Sequences (UVS) are ignored, matching Apache PDFBox behavior.
    end

    private def new_glyph_id_to_character_code(size : Int32) : Array(Int32)
      Array.new(size, -1)
    end

    private def build_glyph_id_to_character_code_lookup(max_glyph_id : Int32) : Nil
      @glyph_id_to_character_code = new_glyph_id_to_character_code(max_glyph_id + 1)
      @character_code_to_glyph_id.each do |key, value|
        if @glyph_id_to_character_code.as(Array(Int32))[value] == -1
          # add new value to the array
          @glyph_id_to_character_code.as(Array(Int32))[value] = key
        else
          # there is already a mapping for the given glyphId
          mapped_values = @glyph_id_to_character_code_multiple[value]?
          if mapped_values.nil?
            mapped_values = [] of Int32
            @glyph_id_to_character_code_multiple[value] = mapped_values
            mapped_values << @glyph_id_to_character_code.as(Array(Int32))[value]
            # mark value as multiple mapping
            @glyph_id_to_character_code.as(Array(Int32))[value] = Int32::MIN
          end
          mapped_values << key
        end
      end
    end
  end

  # CMAP table (Character to Glyph Mapping).
  #
  # Ported from Apache PDFBox CmapTable.
  class CmapTable < TTFTable
    # Tag for this table.
    TAG = "cmap"

    # platform
    PLATFORM_UNICODE   = 0
    PLATFORM_MACINTOSH = 1
    PLATFORM_WINDOWS   = 3

    # Mac encodings
    ENCODING_MAC_ROMAN = 0

    # Windows encodings
    ENCODING_WIN_SYMBOL       =  0 # Unicode, non-standard character set
    ENCODING_WIN_UNICODE_BMP  =  1 # Unicode BMP (UCS-2)
    ENCODING_WIN_SHIFT_JIS    =  2
    ENCODING_WIN_BIG5         =  3
    ENCODING_WIN_PRC          =  4
    ENCODING_WIN_WANSUNG      =  5
    ENCODING_WIN_JOHAB        =  6
    ENCODING_WIN_UNICODE_FULL = 10 # Unicode Full (UCS-4)

    # Unicode encodings
    ENCODING_UNICODE_1_0      = 0
    ENCODING_UNICODE_1_1      = 1
    ENCODING_UNICODE_2_0_BMP  = 3
    ENCODING_UNICODE_2_0_FULL = 4

    @cmaps : Array(CmapSubtable) = [] of CmapSubtable

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      version = data.read_unsigned_short.to_i32
      number_of_tables = data.read_unsigned_short.to_i32
      @cmaps = Array(CmapSubtable).new(number_of_tables)
      number_of_tables.times do
        cmap = CmapSubtable.new
        cmap.init_data(data)
        @cmaps << cmap
      end
      number_of_glyphs = ttf.number_of_glyphs
      number_of_tables.times do |i|
        @cmaps[i].init_subtable(self, number_of_glyphs, data)
      end
      @initialized = true
    end

    # Returns the cmaps.
    def cmaps : Array(CmapSubtable)
      @cmaps
    end

    # Sets the cmaps.
    def cmaps=(cmaps_value : Array(CmapSubtable))
      @cmaps = cmaps_value
    end

    # Returns the subtable, if any, for the given platform and encoding.
    def get_subtable(platform_id : Int32, platform_encoding_id : Int32) : CmapSubtable?
      @cmaps.each do |cmap|
        if cmap.platform_id == platform_id && cmap.platform_encoding_id == platform_encoding_id
          return cmap
        end
      end
      nil
    end
  end

  # GLYF table (Glyph Data).
  #
  # Ported from Apache PDFBox GlyphTable.
  class GlyphTable < TTFTable
    # Tag for this table.
    TAG = "glyf"

    @glyphs : Array(GlyphData?)? = nil
    @data_stream : TTFDataStream? = nil
    @loca : IndexToLocationTable? = nil
    @num_glyphs : Int32 = 0
    @cached : Int32 = 0
    @hmt : HorizontalMetricsTable? = nil
    @maxp : MaximumProfileTable? = nil
    @data_lock = Mutex.new
    @data_lock_owner : Fiber? = nil
    @data_lock_depth : Int32 = 0

    MAX_CACHE_SIZE    = 5000
    MAX_CACHED_GLYPHS =  100

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      @loca = ttf.index_to_location
      if @loca.nil?
        raise IO::EOFError.new("Could not get loca table")
      end
      @num_glyphs = ttf.number_of_glyphs

      if @num_glyphs < MAX_CACHE_SIZE
        # don't cache huge fonts to save memory
        @glyphs = Array.new(@num_glyphs, nil.as(GlyphData?))
      end

      # Cache table bytes into an independent stream so the source can be closed later.
      data_bytes = data.read(length.to_i32)
      read = Pdfbox::IO::RandomAccessReadBuffer.new(data_bytes)
      @data_stream = RandomAccessReadDataStream.new(read)

      # Read hmtx and maxp references early like Java to avoid future lock-order issues.
      @hmt = ttf.horizontal_metrics
      @maxp = ttf.maximum_profile

      @initialized = true
    end

    # Sets glyph cache (mostly for tests).
    def set_glyphs(glyphs_value : Array(GlyphData?)) : Nil
      @glyphs = glyphs_value
    end

    # Returns the data for the glyph with the given GID.
    def get_glyph(gid : Int32) : GlyphData?
      get_glyph(gid, 0)
    end

    # Returns the data for the glyph with the given GID at composite resolution level.
    def get_glyph(gid : Int32, level : Int32) : GlyphData?
      return if gid < 0 || gid >= @num_glyphs

      if @glyphs && (cached_glyph = @glyphs.not_nil![gid]?)
        return cached_glyph
      end

      with_data_lock do
        offsets = @loca.not_nil!.get_offsets
        glyph : GlyphData
        data_stream = @data_stream.not_nil!

        if offsets[gid] == offsets[gid + 1] || offsets[gid] == data_stream.original_data_size
          # No outline. Return an empty glyph, not nil; composite glyphs may reference it.
          glyph = GlyphData.new
          glyph.init_empty_data
        else
          current_position = data_stream.current_position
          begin
            data_stream.seek(offsets[gid])
            glyph = get_glyph_data(gid, level)
          ensure
            data_stream.seek(current_position)
          end
        end

        if @glyphs && @glyphs.not_nil![gid]?.nil? && @cached < MAX_CACHED_GLYPHS
          @glyphs.not_nil![gid] = glyph
          @cached += 1
        end

        glyph
      end
    end

    private def get_glyph_data(gid : Int32, level : Int32) : GlyphData
      max_component_depth = @maxp.not_nil!.get_max_component_depth.to_i32
      if level > max_component_depth
        raise IO::Error.new("composite glyph maximum level (#{max_component_depth}) reached")
      end

      glyph = GlyphData.new
      left_side_bearing = @hmt.nil? ? 0 : @hmt.not_nil!.get_left_side_bearing(gid)
      glyph.init_data(self, @data_stream.not_nil!, left_side_bearing, level)

      # Resolve composite glyphs immediately.
      if glyph.get_description.is_composite
        glyph.get_description.resolve
      end
      glyph
    end

    private def with_data_lock(&)
      current_fiber = Fiber.current
      if @data_lock_owner == current_fiber
        @data_lock_depth += 1
        begin
          yield
        ensure
          @data_lock_depth -= 1
        end
      else
        @data_lock.lock
        @data_lock_owner = current_fiber
        @data_lock_depth = 1
        begin
          yield
        ensure
          @data_lock_depth = 0
          @data_lock_owner = nil
          @data_lock.unlock
        end
      end
    end
  end

  # A component of a composite glyph.
  #
  # Ported from Apache PDFBox GlyfCompositeComp.
  class GlyfCompositeComp
    # Flags for composite glyphs.
    ARG_1_AND_2_ARE_WORDS    = 0x0001
    ARGS_ARE_XY_VALUES       = 0x0002
    ROUND_XY_TO_GRID         = 0x0004
    WE_HAVE_A_SCALE          = 0x0008
    MORE_COMPONENTS          = 0x0020
    WE_HAVE_AN_X_AND_Y_SCALE = 0x0040
    WE_HAVE_A_TWO_BY_TWO     = 0x0080
    WE_HAVE_INSTRUCTIONS     = 0x0100
    USE_MY_METRICS           = 0x0200

    @first_index : Int32 = 0
    @first_contour : Int32 = 0
    @argument1 : Int16
    @argument2 : Int16
    @flags : Int16
    @glyph_index : Int32
    @xscale : Float64 = 1.0
    @yscale : Float64 = 1.0
    @scale01 : Float64 = 0.0
    @scale10 : Float64 = 0.0
    @xtranslate : Int32 = 0
    @ytranslate : Int32 = 0
    @point1 : Int32 = 0
    @point2 : Int32 = 0

    def initialize(data : TTFDataStream)
      @flags = data.read_signed_short
      @glyph_index = data.read_unsigned_short.to_i32

      if (@flags & ARG_1_AND_2_ARE_WORDS) != 0
        @argument1 = data.read_signed_short
        @argument2 = data.read_signed_short
      else
        @argument1 = data.read_signed_byte.to_i16
        @argument2 = data.read_signed_byte.to_i16
      end

      if (@flags & ARGS_ARE_XY_VALUES) != 0
        @xtranslate = @argument1.to_i32
        @ytranslate = @argument2.to_i32
      else
        @point1 = @argument1.to_i32
        @point2 = @argument2.to_i32
      end

      if (@flags & WE_HAVE_A_SCALE) != 0
        i = data.read_signed_short
        @xscale = @yscale = i / 16384.0_f64
      elsif (@flags & WE_HAVE_AN_X_AND_Y_SCALE) != 0
        i = data.read_signed_short
        @xscale = i / 16384.0_f64
        i = data.read_signed_short
        @yscale = i / 16384.0_f64
      elsif (@flags & WE_HAVE_A_TWO_BY_TWO) != 0
        i = data.read_signed_short
        @xscale = i / 16384.0_f64
        i = data.read_signed_short
        @scale01 = i / 16384.0_f64
        i = data.read_signed_short
        @scale10 = i / 16384.0_f64
        i = data.read_signed_short
        @yscale = i / 16384.0_f64
      end
    end

    def set_first_index(idx : Int32) : Nil
      @first_index = idx
    end

    def get_first_index : Int32
      @first_index
    end

    def set_first_contour(idx : Int32) : Nil
      @first_contour = idx
    end

    def get_first_contour : Int32
      @first_contour
    end

    def get_argument1 : Int16
      @argument1
    end

    def get_argument2 : Int16
      @argument2
    end

    def get_flags : Int16
      @flags
    end

    def get_glyph_index : Int32
      @glyph_index
    end

    def get_scale01 : Float64
      @scale01
    end

    def get_scale10 : Float64
      @scale10
    end

    def get_x_scale : Float64
      @xscale
    end

    def get_y_scale : Float64
      @yscale
    end

    def get_x_translate : Int32
      @xtranslate
    end

    def get_y_translate : Int32
      @ytranslate
    end

    # Transforms an x-coordinate for this component.
    def scale_x(x : Int32, y : Int32) : Int32
      (x * @xscale + y * @scale10).round.to_i32
    end

    # Transforms a y-coordinate for this component.
    def scale_y(x : Int32, y : Int32) : Int32
      (x * @scale01 + y * @yscale).round.to_i32
    end
  end

  # Specifies access to glyph description classes, simple and composite.
  #
  # Ported from Apache PDFBox GlyphDescription.
  module GlyphDescription
    abstract def get_end_pt_of_contours(i : Int32) : Int32
    abstract def get_flags(i : Int32) : Int32
    abstract def get_x_coordinate(i : Int32) : Int16
    abstract def get_y_coordinate(i : Int32) : Int16
    abstract def is_composite : Bool
    abstract def get_point_count : Int32
    abstract def get_contour_count : Int32
    abstract def resolve : Nil
  end

  # Base class for glyf descriptions.
  #
  # Ported from Apache PDFBox GlyfDescript.
  abstract class GlyfDescript
    include GlyphDescription

    ON_CURVE       = 0x01
    X_SHORT_VECTOR = 0x02
    Y_SHORT_VECTOR = 0x04
    REPEAT         = 0x08
    X_DUAL         = 0x10
    Y_DUAL         = 0x20

    @instructions : Array(Int32) = [] of Int32
    @contour_count : Int32

    def initialize(number_of_contours : Int16)
      @contour_count = number_of_contours.to_i32
    end

    def resolve : Nil
      # no-op in base class
    end

    def get_contour_count : Int32
      @contour_count
    end

    def get_instructions : Array(Int32)
      @instructions
    end

    protected def read_instructions(data : TTFDataStream, count : Int32) : Nil
      @instructions = data.read_unsigned_byte_array(count)
    end
  end

  # Description for a simple glyf glyph.
  #
  # Ported from Apache PDFBox GlyfSimpleDescript.
  class GlyfSimpleDescript < GlyfDescript
    @end_pts_of_contours : Array(Int32) = [] of Int32
    @flags : Array(Int32) = [] of Int32
    @x_coordinates : Array(Int16) = [] of Int16
    @y_coordinates : Array(Int16) = [] of Int16
    @point_count : Int32 = 0

    # Constructor for an empty description.
    def initialize
      super(0_i16)
      @point_count = 0
    end

    # Constructor from stream data.
    def initialize(number_of_contours : Int16, data : TTFDataStream, x0 : Int16)
      super(number_of_contours)

      if number_of_contours == 0
        @point_count = 0
        return
      end

      @end_pts_of_contours = data.read_unsigned_short_array(number_of_contours.to_i32)

      last_end_pt = @end_pts_of_contours[number_of_contours - 1]
      if number_of_contours == 1 && last_end_pt == 65535
        # PDFBOX-2939: assume an empty glyph
        @point_count = 0
        return
      end

      @point_count = last_end_pt + 1
      @flags = Array.new(@point_count, 0)
      @x_coordinates = Array.new(@point_count, 0_i16)
      @y_coordinates = Array.new(@point_count, 0_i16)

      instruction_count = data.read_unsigned_short.to_i32
      read_instructions(data, instruction_count)
      read_flags(@point_count, data)
      read_coords(@point_count, data, x0)
    end

    def get_end_pt_of_contours(i : Int32) : Int32
      @end_pts_of_contours[i]
    end

    def get_flags(i : Int32) : Int32
      @flags[i]
    end

    def get_x_coordinate(i : Int32) : Int16
      @x_coordinates[i]
    end

    def get_y_coordinate(i : Int32) : Int16
      @y_coordinates[i]
    end

    def is_composite : Bool
      false
    end

    def get_point_count : Int32
      @point_count
    end

    # The table is stored as relative values, but we'll store them as absolutes.
    private def read_coords(count : Int32, data : TTFDataStream, x0 : Int16) : Nil
      x = x0.to_i32
      y = 0
      count.times do |i|
        if (@flags[i] & X_DUAL) != 0
          if (@flags[i] & X_SHORT_VECTOR) != 0
            x += data.read_unsigned_byte
          end
        else
          if (@flags[i] & X_SHORT_VECTOR) != 0
            x -= data.read_unsigned_byte
          else
            x += data.read_signed_short.to_i32
          end
        end
        @x_coordinates[i] = x.to_i16
      end

      count.times do |i|
        if (@flags[i] & Y_DUAL) != 0
          if (@flags[i] & Y_SHORT_VECTOR) != 0
            y += data.read_unsigned_byte
          end
        else
          if (@flags[i] & Y_SHORT_VECTOR) != 0
            y -= data.read_unsigned_byte
          else
            y += data.read_signed_short.to_i32
          end
        end
        @y_coordinates[i] = y.to_i16
      end
    end

    # The flags are run-length encoded.
    private def read_flags(flag_count : Int32, data : TTFDataStream) : Nil
      index = 0
      while index < flag_count
        @flags[index] = data.read_unsigned_byte
        if (@flags[index] & REPEAT) != 0
          repeats = data.read_unsigned_byte
          (1..repeats).each do |i|
            if index + i >= @flags.size
              raise IO::Error.new("repeat count (#{repeats}) higher than remaining space")
            end
            @flags[index + i] = @flags[index]
          end
          index += repeats
        end
        index += 1
      end
    end
  end

  # A glyph data record in the glyf table.
  #
  # Ported from Apache PDFBox GlyphData.
  class GlyphData
    @x_min : Int16 = 0
    @y_min : Int16 = 0
    @x_max : Int16 = 0
    @y_max : Int16 = 0
    @bounding_box : Fontbox::Util::BoundingBox? = nil
    @number_of_contours : Int16 = 0
    @glyph_description : GlyphDescription? = nil

    # Reads glyph data from the stream.
    def init_data(glyph_table : GlyphTable, data : TTFDataStream, left_side_bearing : Int32, level : Int32) : Nil
      @number_of_contours = data.read_signed_short
      @x_min = data.read_signed_short
      @y_min = data.read_signed_short
      @x_max = data.read_signed_short
      @y_max = data.read_signed_short
      @bounding_box = Fontbox::Util::BoundingBox.new(@x_min.to_f32, @y_min.to_f32, @x_max.to_f32, @y_max.to_f32)

      if @number_of_contours >= 0
        x0 = (left_side_bearing - @x_min).to_i16
        @glyph_description = GlyfSimpleDescript.new(@number_of_contours, data, x0)
      else
        @glyph_description = GlyfCompositeDescript.new(data, glyph_table, level + 1)
      end
    end

    # Initializes an empty glyph record.
    def init_empty_data : Nil
      @glyph_description = GlyfSimpleDescript.new
      @bounding_box = Fontbox::Util::BoundingBox.new(0_f32, 0_f32, 0_f32, 0_f32)
    end

    def get_bounding_box : Fontbox::Util::BoundingBox
      @bounding_box.not_nil!
    end

    def get_number_of_contours : Int16
      @number_of_contours
    end

    def get_description : GlyphDescription
      @glyph_description.not_nil!
    end

    def get_x_maximum : Int16
      @x_max
    end

    def get_x_minimum : Int16
      @x_min
    end

    def get_y_maximum : Int16
      @y_max
    end

    def get_y_minimum : Int16
      @y_min
    end
  end

  # Glyph description for composite glyphs.
  #
  # Ported from Apache PDFBox GlyfCompositeDescript.
  class GlyfCompositeDescript < GlyfDescript
    @components : Array(GlyfCompositeComp) = [] of GlyfCompositeComp
    @descriptions = Hash(Int32, GlyphDescription).new
    @glyph_table : GlyphTable
    @being_resolved : Bool = false
    @resolved : Bool = false
    @point_count : Int32 = -1
    @contour_count : Int32 = -1

    def initialize(data : TTFDataStream, @glyph_table : GlyphTable, level : Int32)
      super(-1_i16)

      loop do
        comp = GlyfCompositeComp.new(data)
        @components << comp
        break if (comp.get_flags & GlyfCompositeComp::MORE_COMPONENTS) == 0
      end

      last_comp = @components.last
      if (last_comp.get_flags & GlyfCompositeComp::WE_HAVE_INSTRUCTIONS) != 0
        read_instructions(data, data.read_unsigned_short.to_i32)
      end
      init_descriptions(level)
    end

    def resolve : Nil
      return if @resolved
      return if @being_resolved

      @being_resolved = true
      first_index = 0
      first_contour = 0

      @components.each do |comp|
        comp.set_first_index(first_index)
        comp.set_first_contour(first_contour)

        if desc = @descriptions[comp.get_glyph_index]?
          desc.resolve
          first_index += desc.get_point_count
          first_contour += desc.get_contour_count
        end
      end

      @resolved = true
      @being_resolved = false
    end

    def get_end_pt_of_contours(i : Int32) : Int32
      if comp = get_composite_comp_end_pt(i)
        if desc = @descriptions[comp.get_glyph_index]?
          return desc.get_end_pt_of_contours(i - comp.get_first_contour) + comp.get_first_index
        end
      end
      0
    end

    def get_flags(i : Int32) : Int32
      if comp = get_composite_comp(i)
        if desc = @descriptions[comp.get_glyph_index]?
          return desc.get_flags(i - comp.get_first_index)
        end
      end
      0
    end

    def get_x_coordinate(i : Int32) : Int16
      if comp = get_composite_comp(i)
        if desc = @descriptions[comp.get_glyph_index]?
          n = i - comp.get_first_index
          x = desc.get_x_coordinate(n).to_i32
          y = desc.get_y_coordinate(n).to_i32
          return (comp.scale_x(x, y) + comp.get_x_translate).to_i16
        end
      end
      0_i16
    end

    def get_y_coordinate(i : Int32) : Int16
      if comp = get_composite_comp(i)
        if desc = @descriptions[comp.get_glyph_index]?
          n = i - comp.get_first_index
          x = desc.get_x_coordinate(n).to_i32
          y = desc.get_y_coordinate(n).to_i32
          return (comp.scale_y(x, y) + comp.get_y_translate).to_i16
        end
      end
      0_i16
    end

    def is_composite : Bool
      true
    end

    def get_point_count : Int32
      if @point_count < 0
        if comp = @components.last?
          if desc = @descriptions[comp.get_glyph_index]?
            @point_count = comp.get_first_index + desc.get_point_count
          else
            @point_count = 0
          end
        else
          return 0
        end
      end
      @point_count
    end

    def get_contour_count : Int32
      if @contour_count < 0
        if comp = @components.last?
          if desc = @descriptions[comp.get_glyph_index]?
            @contour_count = comp.get_first_contour + desc.get_contour_count
          else
            @contour_count = 0
          end
        else
          return 0
        end
      end
      @contour_count
    end

    def get_component_count : Int32
      @components.size
    end

    # Returns a copy to keep the internal list unmodifiable by callers.
    def get_components : Array(GlyfCompositeComp)
      @components.dup
    end

    private def get_composite_comp(i : Int32) : GlyfCompositeComp?
      @components.each do |comp|
        desc = @descriptions[comp.get_glyph_index]?
        next if desc.nil?

        if comp.get_first_index <= i && i < (comp.get_first_index + desc.get_point_count)
          return comp
        end
      end
      nil
    end

    private def get_composite_comp_end_pt(i : Int32) : GlyfCompositeComp?
      @components.each do |comp|
        desc = @descriptions[comp.get_glyph_index]?
        next if desc.nil?

        if comp.get_first_contour <= i && i < (comp.get_first_contour + desc.get_contour_count)
          return comp
        end
      end
      nil
    end

    private def init_descriptions(level : Int32) : Nil
      @components.each do |component|
        begin
          glyph = @glyph_table.get_glyph(component.get_glyph_index, level)
          if glyph
            @descriptions[component.get_glyph_index] = glyph.get_description
          end
        rescue IO::Error
          # Match Java behavior: ignore broken component references and continue.
        end
      end
    end
  end

  # HMTX table (Horizontal Metrics).
  #
  # Ported from Apache PDFBox HorizontalMetricsTable.
  class HorizontalMetricsTable < TTFTable
    # Tag for this table.
    TAG = "hmtx"

    @advance_width : Array(Int32) = [] of Int32
    @left_side_bearing : Array(Int16) = [] of Int16
    @non_horizontal_left_side_bearing : Array(Int16) = [] of Int16
    @num_h_metrics : Int32 = 0

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      h_header = ttf.horizontal_header
      if h_header.nil?
        raise IO::EOFError.new("Could not get hmtx table")
      end
      @num_h_metrics = h_header.number_of_h_metrics.to_i32
      num_glyphs = ttf.number_of_glyphs

      bytes_read = 0
      @advance_width = Array.new(@num_h_metrics, 0)
      @left_side_bearing = Array.new(@num_h_metrics, 0_i16)
      @num_h_metrics.times do |i|
        @advance_width[i] = data.read_unsigned_short.to_i32
        @left_side_bearing[i] = data.read_signed_short
        bytes_read += 4
      end

      number_non_horizontal = num_glyphs - @num_h_metrics

      # handle bad fonts with too many hmetrics
      if number_non_horizontal < 0
        number_non_horizontal = num_glyphs
      end

      # make sure that table is never null and correct size, even with bad fonts that have no
      # "leftSideBearing" table, although they should
      @non_horizontal_left_side_bearing = Array.new(number_non_horizontal, 0_i16)

      if bytes_read < length
        number_non_horizontal.times do |i|
          if bytes_read < length
            @non_horizontal_left_side_bearing[i] = data.read_signed_short
            bytes_read += 2
          end
        end
      end

      @initialized = true
    end

    # Returns the advance width for the given GID.
    def get_advance_width(gid : Int32) : Int32
      if @advance_width.empty?
        return 250
      end
      if gid < @num_h_metrics
        @advance_width[gid]
      else
        # monospaced fonts may not have a width for every glyph
        # the last one is for subsequent glyphs
        @advance_width[@advance_width.size - 1]
      end
    end

    # Returns the left side bearing for the given GID.
    def get_left_side_bearing(gid : Int32) : Int32
      if @left_side_bearing.empty?
        return 0
      end
      if gid < @num_h_metrics
        @left_side_bearing[gid].to_i32
      else
        @non_horizontal_left_side_bearing[gid - @num_h_metrics].to_i32
      end
    end

    # Gets the advance width array.
    def get_advance_width_array : Array(Int32)
      @advance_width
    end

    # Gets the left side bearing array.
    def get_left_side_bearing_array : Array(Int16)
      @left_side_bearing
    end

    # Gets the non-horizontal left side bearing array.
    def get_non_horizontal_left_side_bearing_array : Array(Int16)
      @non_horizontal_left_side_bearing
    end

    # Gets the number of horizontal metrics.
    def get_num_h_metrics : Int32
      @num_h_metrics
    end
  end

  # LOCA table (Index to Location).
  #
  # Ported from Apache PDFBox IndexToLocationTable.
  class IndexToLocationTable < TTFTable
    # Tag for this table.
    TAG = "loca"

    SHORT_OFFSETS = 0
    LONG_OFFSETS  = 1

    @offsets : Array(Int64) = [] of Int64

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      head = ttf.header
      if head.nil?
        raise IO::EOFError.new("Could not get head table")
      end
      num_glyphs = ttf.number_of_glyphs
      @offsets = Array(Int64).new(num_glyphs + 1)
      (num_glyphs + 1).times do |_|
        if head.index_to_loc_format == SHORT_OFFSETS
          @offsets << data.read_unsigned_short.to_i64 * 2
        elsif head.index_to_loc_format == LONG_OFFSETS
          @offsets << data.read_unsigned_int.to_i64
        else
          raise IO::EOFError.new("Error:TTF.loca unknown offset format: #{head.index_to_loc_format}")
        end
      end
      if num_glyphs == 1 && @offsets[0] == 0 && @offsets[1] == 0
        # PDFBOX-5794 empty glyph
        raise IO::EOFError.new("The font has no glyphs")
      end
      @initialized = true
    end

    # Returns the offsets.
    def get_offsets : Array(Int64)
      @offsets
    end

    # Sets the offsets.
    def set_offsets(offsets_value : Array(Int64))
      @offsets = offsets_value
    end
  end

  # DSIG table (Digital Signature).
  #
  # Ported from Apache PDFBox DigitalSignatureTable.
  class DigitalSignatureTable < TTFTable
    # Tag for this table.
    TAG = "DSIG"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # No payload is consumed here in Apache PDFBox; table presence is enough.
      @initialized = true
    end
  end

  # KERN table (Kerning).
  #
  # Ported from Apache PDFBox KerningTable.
  class KerningTable < TTFTable
    # Tag for this table.
    TAG = "kern"

    @subtables : Array(KerningSubtable)? = nil

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      version = data.read_unsigned_short.to_i32
      if version != 0
        version = (version << 16) | data.read_unsigned_short.to_i32
      end
      num_subtables = 0
      case version
      when 0
        num_subtables = data.read_unsigned_short.to_i32
      when 1
        num_subtables = data.read_unsigned_int.to_i32
      else
        # unsupported kerning table version
      end
      if num_subtables > 0
        @subtables = Array.new(num_subtables) { KerningSubtable.new }
        num_subtables.times do |i|
          subtable = KerningSubtable.new
          subtable.read(data, version)
          @subtables.not_nil![i] = subtable
        end
      end
      @initialized = true
    end

    # Obtain first subtable that supports non-cross-stream horizontal kerning.
    def get_horizontal_kerning_subtable(cross : Bool = false) : KerningSubtable?
      return if @subtables.nil?
      @subtables.not_nil!.each do |subtable|
        if subtable.is_horizontal_kerning(cross)
          return subtable
        end
      end
      nil
    end
  end

  # A subtable of a KERN table.
  #
  # Ported from Apache PDFBox KerningSubtable.
  class KerningSubtable
    private COVERAGE_HORIZONTAL   = 0x0001
    private COVERAGE_MINIMUMS     = 0x0002
    private COVERAGE_CROSS_STREAM = 0x0004
    private COVERAGE_FORMAT       = 0xFF00

    private COVERAGE_HORIZONTAL_SHIFT   = 0
    private COVERAGE_MINIMUMS_SHIFT     = 1
    private COVERAGE_CROSS_STREAM_SHIFT = 2
    private COVERAGE_FORMAT_SHIFT       = 8

    @horizontal : Bool = false
    @minimums : Bool = false
    @cross_stream : Bool = false
    @pairs : PairData? = nil

    def read(data : TTFDataStream, version : Int32) : Nil
      if version == 0
        read_subtable0(data)
      elsif version == 1
        read_subtable1(data)
      else
        raise "Unsupported kerning table version #{version}"
      end
    end

    def is_horizontal_kerning(cross : Bool = false) : Bool
      return false unless @horizontal
      return false if @minimums
      cross ? @cross_stream : !@cross_stream
    end

    # Obtain kerning adjustment for glyph pair {l, r}.
    def get_kerning(l : Int32, r : Int32) : Int32
      return 0 if @pairs.nil?
      @pairs.not_nil!.get_kerning(l, r)
    end

    # Obtain kerning adjustments for a glyph sequence.
    def get_kerning(glyphs : Array(Int32)) : Array(Int32)?
      return if @pairs.nil?
      ng = glyphs.size
      kerning = Array.new(ng, 0)
      ng.times do |i|
        left = glyphs[i]
        right = -1
        (i + 1...ng).each do |k|
          g = glyphs[k]
          if g >= 0
            right = g
            break
          end
        end
        kerning[i] = get_kerning(left, right)
      end
      kerning
    end

    private def read_subtable0(data : TTFDataStream) : Nil
      version = data.read_unsigned_short.to_i32
      return if version != 0

      length = data.read_unsigned_short.to_i32
      return if length < 6

      coverage = data.read_unsigned_short.to_i32
      @horizontal = is_bits_set(coverage, COVERAGE_HORIZONTAL, COVERAGE_HORIZONTAL_SHIFT)
      @minimums = is_bits_set(coverage, COVERAGE_MINIMUMS, COVERAGE_MINIMUMS_SHIFT)
      @cross_stream = is_bits_set(coverage, COVERAGE_CROSS_STREAM, COVERAGE_CROSS_STREAM_SHIFT)
      format = get_bits(coverage, COVERAGE_FORMAT, COVERAGE_FORMAT_SHIFT)

      case format
      when 0
        read_subtable0_format0(data)
      when 2
        read_subtable0_format2(data)
      else
        # unsupported format
      end
    end

    private def read_subtable0_format0(data : TTFDataStream) : Nil
      pair_data = PairData0Format0.new
      pair_data.read(data)
      @pairs = pair_data
    end

    private def read_subtable0_format2(data : TTFDataStream) : Nil
      # not yet supported in Apache PDFBox either
    end

    private def read_subtable1(data : TTFDataStream) : Nil
      # not yet supported in Apache PDFBox either
    end

    private def is_bits_set(bits : Int32, mask : Int32, shift : Int32) : Bool
      get_bits(bits, mask, shift) != 0
    end

    private def get_bits(bits : Int32, mask : Int32, shift : Int32) : Int32
      (bits & mask) >> shift
    end

    private module PairData
      abstract def read(data : TTFDataStream) : Nil
      abstract def get_kerning(l : Int32, r : Int32) : Int32
    end

    private class PairData0Format0
      include PairData

      @search_range : Int32 = 0
      @pairs = [] of Tuple(Int32, Int32, Int32)

      def read(data : TTFDataStream) : Nil
        num_pairs = data.read_unsigned_short.to_i32
        @search_range = data.read_unsigned_short.to_i32 // 6
        _entry_selector = data.read_unsigned_short.to_i32
        _range_shift = data.read_unsigned_short.to_i32
        @pairs = Array.new(num_pairs) do
          left = data.read_unsigned_short.to_i32
          right = data.read_unsigned_short.to_i32
          value = data.read_signed_short.to_i32
          {left, right, value}
        end
      end

      def get_kerning(l : Int32, r : Int32) : Int32
        low = 0
        high = @pairs.size - 1
        while low <= high
          mid = (low + high) // 2
          left, right, value = @pairs[mid]
          if left == l && right == r
            return value
          elsif (left < l) || (left == l && right < r)
            low = mid + 1
          else
            high = mid - 1
          end
        end
        0
      end
    end
  end

  # VHEA table (Vertical Header).
  #
  # Ported from Apache PDFBox VerticalHeaderTable.
  class VerticalHeaderTable < TTFTable
    # Tag for this table.
    TAG = "vhea"

    @version : Float32 = 0.0_f32
    @ascender : Int16 = 0
    @descender : Int16 = 0
    @line_gap : Int16 = 0
    @advance_height_max : UInt16 = 0
    @min_top_side_bearing : Int16 = 0
    @min_bottom_side_bearing : Int16 = 0
    @y_max_extent : Int16 = 0
    @caret_slope_rise : Int16 = 0
    @caret_slope_run : Int16 = 0
    @caret_offset : Int16 = 0
    @reserved1 : Int16 = 0
    @reserved2 : Int16 = 0
    @reserved3 : Int16 = 0
    @reserved4 : Int16 = 0
    @metric_data_format : Int16 = 0
    @number_of_v_metrics : UInt16 = 0

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      @version = data.read_32_fixed
      @ascender = data.read_signed_short
      @descender = data.read_signed_short
      @line_gap = data.read_signed_short
      @advance_height_max = data.read_unsigned_short.to_u16
      @min_top_side_bearing = data.read_signed_short
      @min_bottom_side_bearing = data.read_signed_short
      @y_max_extent = data.read_signed_short
      @caret_slope_rise = data.read_signed_short
      @caret_slope_run = data.read_signed_short
      @caret_offset = data.read_signed_short
      @reserved1 = data.read_signed_short
      @reserved2 = data.read_signed_short
      @reserved3 = data.read_signed_short
      @reserved4 = data.read_signed_short
      @metric_data_format = data.read_signed_short
      @number_of_v_metrics = data.read_unsigned_short.to_u16
      @initialized = true
    end

    def get_version : Float32
      @version
    end

    def get_ascender : Int16
      @ascender
    end

    def get_descender : Int16
      @descender
    end

    def get_line_gap : Int16
      @line_gap
    end

    def get_advance_height_max : UInt16
      @advance_height_max
    end

    def get_min_top_side_bearing : Int16
      @min_top_side_bearing
    end

    def get_min_bottom_side_bearing : Int16
      @min_bottom_side_bearing
    end

    def get_y_max_extent : Int16
      @y_max_extent
    end

    def get_caret_slope_rise : Int16
      @caret_slope_rise
    end

    def get_caret_slope_run : Int16
      @caret_slope_run
    end

    def get_caret_offset : Int16
      @caret_offset
    end

    def get_reserved1 : Int16
      @reserved1
    end

    def get_reserved2 : Int16
      @reserved2
    end

    def get_reserved3 : Int16
      @reserved3
    end

    def get_reserved4 : Int16
      @reserved4
    end

    def get_metric_data_format : Int16
      @metric_data_format
    end

    def number_of_v_metrics : UInt16
      @number_of_v_metrics
    end
  end

  # VMTX table (Vertical Metrics).
  #
  # Ported from Apache PDFBox VerticalMetricsTable.
  class VerticalMetricsTable < TTFTable
    # Tag for this table.
    TAG = "vmtx"

    @advance_height : Array(Int32) = [] of Int32
    @top_side_bearing : Array(Int16) = [] of Int16
    @additional_top_side_bearing : Array(Int16) = [] of Int16
    @num_v_metrics : Int32 = 0

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      v_header = ttf.vertical_header
      if v_header.nil?
        raise IO::EOFError.new("Could not get vhea table")
      end
      @num_v_metrics = v_header.number_of_v_metrics.to_i32
      num_glyphs = ttf.number_of_glyphs

      bytes_read = 0
      @advance_height = Array.new(@num_v_metrics, 0)
      @top_side_bearing = Array.new(@num_v_metrics, 0_i16)
      @num_v_metrics.times do |i|
        @advance_height[i] = data.read_unsigned_short.to_i32
        @top_side_bearing[i] = data.read_signed_short
        bytes_read += 4
      end

      if bytes_read < length
        number_non_vertical = num_glyphs - @num_v_metrics
        if number_non_vertical < 0
          number_non_vertical = num_glyphs
        end

        @additional_top_side_bearing = Array.new(number_non_vertical, 0_i16)
        number_non_vertical.times do |i|
          if bytes_read < length
            @additional_top_side_bearing[i] = data.read_signed_short
            bytes_read += 2
          end
        end
      else
        @additional_top_side_bearing = [] of Int16
      end

      @initialized = true
    end

    def get_top_side_bearing(gid : Int32) : Int32
      if gid < @num_v_metrics
        @top_side_bearing[gid].to_i32
      else
        @additional_top_side_bearing[gid - @num_v_metrics].to_i32
      end
    end

    def get_advance_height(gid : Int32) : Int32
      if gid < @num_v_metrics
        @advance_height[gid]
      else
        @advance_height[@advance_height.size - 1]
      end
    end
  end

  # VORG table (Vertical Origin).
  #
  # Ported from Apache PDFBox VerticalOriginTable.
  class VerticalOriginTable < TTFTable
    # Tag for this table.
    TAG = "VORG"

    @version : Float32 = 0.0_f32
    @default_vert_origin_y : Int16 = 0
    @origins : Hash(Int32, Int16) = Hash(Int32, Int16).new

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      @version = data.read_32_fixed
      @default_vert_origin_y = data.read_signed_short
      num_vert_origin_y_metrics = data.read_unsigned_short.to_i32
      @origins = Hash(Int32, Int16).new(initial_capacity: num_vert_origin_y_metrics)
      num_vert_origin_y_metrics.times do
        glyph_id = data.read_unsigned_short.to_i32
        y = data.read_signed_short
        @origins[glyph_id] = y
      end
      @initialized = true
    end

    def get_version : Float32
      @version
    end

    def get_origin_y(gid : Int32) : Int32
      @origins[gid]?.try(&.to_i32) || @default_vert_origin_y.to_i32
    end
  end

  # Range record in Coverage format 2.
  #
  # Ported from Apache PDFBox RangeRecord.
  class RangeRecord
    @start_glyph_id : Int32
    @end_glyph_id : Int32
    @start_coverage_index : Int32

    def initialize(start_glyph_id : Int32, end_glyph_id : Int32, start_coverage_index : Int32)
      @start_glyph_id = start_glyph_id
      @end_glyph_id = end_glyph_id
      @start_coverage_index = start_coverage_index
    end

    def get_start_glyph_id : Int32
      @start_glyph_id
    end

    def get_end_glyph_id : Int32
      @end_glyph_id
    end

    def get_start_coverage_index : Int32
      @start_coverage_index
    end
  end

  # Coverage table.
  #
  # Ported from Apache PDFBox CoverageTable.
  abstract class CoverageTable
    @coverage_format : Int32

    def initialize(@coverage_format : Int32)
    end

    abstract def get_coverage_index(gid : Int32) : Int32
    abstract def get_glyph_id(index : Int32) : Int32
    abstract def get_size : Int32

    def get_coverage_format : Int32
      @coverage_format
    end
  end

  # Coverage format 1.
  #
  # Ported from Apache PDFBox CoverageTableFormat1.
  class CoverageTableFormat1 < CoverageTable
    @glyph_array : Array(Int32)

    def initialize(coverage_format : Int32, @glyph_array : Array(Int32))
      super(coverage_format)
    end

    def get_coverage_index(gid : Int32) : Int32
      @glyph_array.bsearch_index(gid) || -1
    end

    def get_glyph_id(index : Int32) : Int32
      @glyph_array[index]
    end

    def get_size : Int32
      @glyph_array.size
    end

    def get_glyph_array : Array(Int32)
      @glyph_array
    end
  end

  # Coverage format 2.
  #
  # Ported from Apache PDFBox CoverageTableFormat2.
  class CoverageTableFormat2 < CoverageTableFormat1
    @range_records : Array(RangeRecord)

    def initialize(coverage_format : Int32, @range_records : Array(RangeRecord))
      super(coverage_format, self.class.range_records_as_array(@range_records))
    end

    def get_range_records : Array(RangeRecord)
      @range_records
    end

    def self.range_records_as_array(range_records : Array(RangeRecord)) : Array(Int32)
      glyph_ids = [] of Int32
      range_records.each do |range|
        (range.get_start_glyph_id..range.get_end_glyph_id).each do |glyph_id|
          glyph_ids << glyph_id
        end
      end
      glyph_ids
    end
  end

  # Language system table.
  #
  # Ported from Apache PDFBox LangSysTable.
  class LangSysTable
    @lookup_order : Int32
    @required_feature_index : Int32
    @feature_index_count : Int32
    @feature_indices : Array(Int32)

    def initialize(@lookup_order : Int32, @required_feature_index : Int32, @feature_index_count : Int32,
                   @feature_indices : Array(Int32))
    end

    def get_lookup_order : Int32
      @lookup_order
    end

    def get_required_feature_index : Int32
      @required_feature_index
    end

    def get_feature_index_count : Int32
      @feature_index_count
    end

    def get_feature_indices : Array(Int32)
      @feature_indices
    end
  end

  # Script table.
  #
  # Ported from Apache PDFBox ScriptTable.
  class ScriptTable
    @default_lang_sys_table : LangSysTable?
    @lang_sys_tables : Hash(String, LangSysTable)

    def initialize(@default_lang_sys_table : LangSysTable?, @lang_sys_tables : Hash(String, LangSysTable))
    end

    def get_default_lang_sys_table : LangSysTable?
      @default_lang_sys_table
    end

    def get_lang_sys_tables : Hash(String, LangSysTable)
      @lang_sys_tables
    end
  end

  # Feature table.
  #
  # Ported from Apache PDFBox FeatureTable.
  class FeatureTable
    @feature_params : Int32
    @lookup_index_count : Int32
    @lookup_list_indices : Array(Int32)

    def initialize(@feature_params : Int32, @lookup_index_count : Int32, @lookup_list_indices : Array(Int32))
    end

    def get_feature_params : Int32
      @feature_params
    end

    def get_lookup_index_count : Int32
      @lookup_index_count
    end

    def get_lookup_list_indices : Array(Int32)
      @lookup_list_indices
    end
  end

  # Feature record.
  #
  # Ported from Apache PDFBox FeatureRecord.
  class FeatureRecord
    @feature_tag : String
    @feature_table : FeatureTable

    def initialize(@feature_tag : String, @feature_table : FeatureTable)
    end

    def get_feature_tag : String
      @feature_tag
    end

    def get_feature_table : FeatureTable
      @feature_table
    end
  end

  # Feature list table.
  #
  # Ported from Apache PDFBox FeatureListTable.
  class FeatureListTable
    @feature_count : Int32
    @feature_records : Array(FeatureRecord)

    def initialize(@feature_count : Int32, @feature_records : Array(FeatureRecord))
    end

    def get_feature_count : Int32
      @feature_count
    end

    def get_feature_records : Array(FeatureRecord)
      @feature_records
    end
  end

  # Lookup sub-table.
  #
  # Ported from Apache PDFBox LookupSubTable.
  abstract class LookupSubTable
    @subst_format : Int32
    @coverage_table : CoverageTable

    def initialize(@subst_format : Int32, @coverage_table : CoverageTable)
    end

    abstract def do_substitution(gid : Int32, coverage_index : Int32) : Int32

    def get_subst_format : Int32
      @subst_format
    end

    def get_coverage_table : CoverageTable
      @coverage_table
    end
  end

  # Lookup table.
  #
  # Ported from Apache PDFBox LookupTable.
  class LookupTable
    @lookup_type : Int32
    @lookup_flag : Int32
    @mark_filtering_set : Int32
    @sub_tables : Array(LookupSubTable)

    def initialize(@lookup_type : Int32, @lookup_flag : Int32, @mark_filtering_set : Int32,
                   @sub_tables : Array(LookupSubTable))
    end

    def get_lookup_type : Int32
      @lookup_type
    end

    def get_lookup_flag : Int32
      @lookup_flag
    end

    def get_mark_filtering_set : Int32
      @mark_filtering_set
    end

    def get_sub_tables : Array(LookupSubTable)
      @sub_tables
    end
  end

  # Lookup list table.
  #
  # Ported from Apache PDFBox LookupListTable.
  class LookupListTable
    @lookup_count : Int32
    @lookups : Array(LookupTable)

    def initialize(@lookup_count : Int32, @lookups : Array(LookupTable))
    end

    def get_lookup_count : Int32
      @lookup_count
    end

    def get_lookups : Array(LookupTable)
      @lookups
    end
  end

  # Sequence table.
  #
  # Ported from Apache PDFBox SequenceTable.
  class SequenceTable
    @glyph_count : Int32
    @substitute_glyph_ids : Array(Int32)

    def initialize(@glyph_count : Int32, @substitute_glyph_ids : Array(Int32))
    end

    def get_glyph_count : Int32
      @glyph_count
    end

    def get_substitute_glyph_ids : Array(Int32)
      @substitute_glyph_ids
    end
  end

  # Alternate set table.
  #
  # Ported from Apache PDFBox AlternateSetTable.
  class AlternateSetTable
    @glyph_count : Int32
    @alternate_glyph_ids : Array(Int32)

    def initialize(@glyph_count : Int32, @alternate_glyph_ids : Array(Int32))
    end

    def get_glyph_count : Int32
      @glyph_count
    end

    def get_alternate_glyph_ids : Array(Int32)
      @alternate_glyph_ids
    end
  end

  # Ligature set table.
  #
  # Ported from Apache PDFBox LigatureSetTable.
  class LigatureSetTable
    @ligature_count : Int32
    @ligature_tables : Array(LigatureTable)

    def initialize(@ligature_count : Int32, @ligature_tables : Array(LigatureTable))
    end

    def get_ligature_count : Int32
      @ligature_count
    end

    def get_ligature_tables : Array(LigatureTable)
      @ligature_tables
    end
  end

  # Ligature table.
  #
  # Ported from Apache PDFBox LigatureTable.
  class LigatureTable
    @ligature_glyph : Int32
    @component_count : Int32
    @component_glyph_ids : Array(Int32)

    def initialize(@ligature_glyph : Int32, @component_count : Int32, @component_glyph_ids : Array(Int32))
    end

    def get_ligature_glyph : Int32
      @ligature_glyph
    end

    def get_component_count : Int32
      @component_count
    end

    def get_component_glyph_ids : Array(Int32)
      @component_glyph_ids
    end
  end

  # Lookup type 1 single substitution format 1.
  #
  # Ported from Apache PDFBox LookupTypeSingleSubstFormat1.
  class LookupTypeSingleSubstFormat1 < LookupSubTable
    @delta_glyph_id : Int16

    def initialize(subst_format : Int32, coverage_table : CoverageTable, @delta_glyph_id : Int16)
      super(subst_format, coverage_table)
    end

    def do_substitution(gid : Int32, coverage_index : Int32) : Int32
      coverage_index < 0 ? gid : gid + @delta_glyph_id.to_i32
    end

    def get_delta_glyph_id : Int16
      @delta_glyph_id
    end
  end

  # Lookup type 1 single substitution format 2.
  #
  # Ported from Apache PDFBox LookupTypeSingleSubstFormat2.
  class LookupTypeSingleSubstFormat2 < LookupSubTable
    @substitute_glyph_ids : Array(Int32)

    def initialize(subst_format : Int32, coverage_table : CoverageTable, @substitute_glyph_ids : Array(Int32))
      super(subst_format, coverage_table)
    end

    def do_substitution(gid : Int32, coverage_index : Int32) : Int32
      coverage_index < 0 ? gid : @substitute_glyph_ids[coverage_index]
    end

    def get_substitute_glyph_ids : Array(Int32)
      @substitute_glyph_ids
    end
  end

  # Lookup type 2 multiple substitution format 1.
  #
  # Ported from Apache PDFBox LookupTypeMultipleSubstitutionFormat1.
  class LookupTypeMultipleSubstitutionFormat1 < LookupSubTable
    @sequence_tables : Array(SequenceTable)

    def initialize(subst_format : Int32, coverage_table : CoverageTable, @sequence_tables : Array(SequenceTable))
      super(subst_format, coverage_table)
    end

    def do_substitution(gid : Int32, coverage_index : Int32) : Int32
      # TODO: Implement multiple substitution
      gid
    end

    def get_sequence_tables : Array(SequenceTable)
      @sequence_tables
    end
  end

  # Lookup type 3 alternate substitution format 1.
  #
  # Ported from Apache PDFBox LookupTypeAlternateSubstitutionFormat1.
  class LookupTypeAlternateSubstitutionFormat1 < LookupSubTable
    @alternate_set_tables : Array(AlternateSetTable)

    def initialize(subst_format : Int32, coverage_table : CoverageTable, @alternate_set_tables : Array(AlternateSetTable))
      super(subst_format, coverage_table)
    end

    def do_substitution(gid : Int32, coverage_index : Int32) : Int32
      # TODO: Implement alternate substitution
      gid
    end

    def get_alternate_set_tables : Array(AlternateSetTable)
      @alternate_set_tables
    end
  end

  # Lookup type 4 ligature substitution format 1.
  #
  # Ported from Apache PDFBox LookupTypeLigatureSubstitutionSubstFormat1.
  class LookupTypeLigatureSubstitutionSubstFormat1 < LookupSubTable
    @ligature_set_tables : Array(LigatureSetTable)

    def initialize(subst_format : Int32, coverage_table : CoverageTable, @ligature_set_tables : Array(LigatureSetTable))
      super(subst_format, coverage_table)
    end

    def do_substitution(gid : Int32, coverage_index : Int32) : Int32
      # TODO: Implement ligature substitution
      gid
    end

    def get_ligature_set_tables : Array(LigatureSetTable)
      @ligature_set_tables
    end
  end

  # GSUB table (Glyph Substitution).
  #
  # Ported from Apache PDFBox GlyphSubstitutionTable.
  class GlyphSubstitutionTable < TTFTable
    # Tag for this table.
    TAG = "GSUB"

    private Log = ::Log.for(self)

    @script_list : Hash(String, ScriptTable)
    @feature_list_table : FeatureListTable
    @lookup_list_table : LookupListTable
    @lookup_cache : Hash(Int32, Int32)
    @reverse_lookup : Hash(Int32, Int32)
    @last_used_supported_script : String?
    @gsub_data : Model::GsubData?

    def initialize
      super
      @script_list = Hash(String, ScriptTable).new
      @feature_list_table = FeatureListTable.new(0, [] of FeatureRecord)
      @lookup_list_table = LookupListTable.new(0, [] of LookupTable)
      @lookup_cache = Hash(Int32, Int32).new
      @reverse_lookup = Hash(Int32, Int32).new
      @gsub_data = nil
    end

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      start = data.current_position
      major_version = data.read_unsigned_short.to_i32
      minor_version = data.read_unsigned_short.to_i32
      script_list_offset = data.read_unsigned_short.to_i32
      feature_list_offset = data.read_unsigned_short.to_i32
      lookup_list_offset = data.read_unsigned_short.to_i32
      feature_variations_offset = -1_i64
      if minor_version == 1
        feature_variations_offset = data.read_unsigned_int.to_i64.to_i64
      end

      @script_list = read_script_list(data, start + script_list_offset)
      @feature_list_table = read_feature_list(data, start + feature_list_offset)
      if lookup_list_offset > 0
        @lookup_list_table = read_lookup_list(data, start + lookup_list_offset)
      else
        Log.warn { "lookupListOffset is 0, LookupListTable is considered empty" }
        @lookup_list_table = LookupListTable.new(0, [] of LookupTable)
      end

      # TODO: debugging logging as in Java

      glyph_substitution_data_extractor = Gsub::GlyphSubstitutionDataExtractor.new
      @gsub_data = glyph_substitution_data_extractor.get_gsub_data(@script_list, @feature_list_table, @lookup_list_table)

      @initialized = true
    end

    # Returns a read-only view of the script tags for which this GSUB table has records.
    def get_supported_script_tags : Set(String)
      Set.new(@script_list.keys)
    end

    # Builds a new GsubData instance for given script tag.
    def get_gsub_data(script_tag : String) : Model::GsubData?
      script_table = @script_list[script_tag]?
      return unless script_table
      Gsub::GlyphSubstitutionDataExtractor.new.get_gsub_data(script_tag, script_table,
        @feature_list_table, @lookup_list_table)
    end

    # Returns the GsubData instance containing all scripts of the table.
    def get_gsub_data : Model::GsubData?
      @gsub_data
    end

    # Apply glyph substitutions to the supplied gid.
    def get_substitution(gid : Int32, script_tags : Array(String), enabled_features : Array(String)? = nil) : Int32
      # TODO: implement
      gid
    end

    # For a substitute-gid, retrieve the original gid.
    def get_unsubstitution(sgid : Int32) : Int32
      # TODO: implement
      sgid
    end

    private def read_script_list(data : TTFDataStream, offset : Int64) : Hash(String, ScriptTable)
      data.seek(offset)
      script_count = data.read_unsigned_short.to_i32
      script_offsets = Array(Int32).new(script_count)
      script_tags = Array(String).new(script_count)
      result = Hash(String, ScriptTable).new
      script_count.times do |i|
        script_tags << data.read_string(4)
        script_offsets << data.read_unsigned_short.to_i32
        if script_offsets[i] < data.current_position - offset
          Log.error { "scriptOffsets[#{i}]: #{script_offsets[i]} implausible: data.current_position - offset = #{data.current_position - offset}" }
          return result
        end
      end
      script_count.times do |i|
        if result.has_key?(script_tags[i])
          # PDFBOX-6146 duplicate script tag, skip
          next
        end
        script_table = read_script_table(data, offset + script_offsets[i])
        result[script_tags[i]] = script_table
      end
      result
    end

    private def read_script_table(data : TTFDataStream, offset : Int64) : ScriptTable
      data.seek(offset)
      default_lang_sys_offset = data.read_unsigned_short.to_i32
      lang_sys_count = data.read_unsigned_short.to_i32
      lang_sys_tags = Array(String).new(lang_sys_count)
      lang_sys_offsets = Array(Int32).new(lang_sys_count)
      lang_sys_count.times do |i|
        lang_sys_tags << data.read_string(4)
        lang_sys_offsets << data.read_unsigned_short.to_i32
        if lang_sys_offsets[i] < data.current_position - offset
          Log.error { "langSysOffsets[#{i}]: #{lang_sys_offsets[i]} implausible: data.current_position - offset = #{data.current_position - offset}" }
          return ScriptTable.new(nil, Hash(String, LangSysTable).new)
        end
        if i > 0 && lang_sys_tags[i] < lang_sys_tags[i - 1]
          Log.error { "LangSysRecords not alphabetically sorted by LangSys tag: #{lang_sys_tags[i]} < #{lang_sys_tags[i - 1]}" }
          return ScriptTable.new(nil, Hash(String, LangSysTable).new)
        end
      end

      default_lang_sys_table = nil
      if default_lang_sys_offset != 0
        default_lang_sys_table = read_lang_sys_table(data, offset + default_lang_sys_offset)
      end
      lang_sys_tables = Hash(String, LangSysTable).new
      lang_sys_count.times do |i|
        lang_sys_table = read_lang_sys_table(data, offset + lang_sys_offsets[i])
        lang_sys_tables[lang_sys_tags[i]] = lang_sys_table
      end
      ScriptTable.new(default_lang_sys_table, lang_sys_tables)
    end

    private def read_lang_sys_table(data : TTFDataStream, offset : Int64) : LangSysTable
      data.seek(offset)
      lookup_order = data.read_unsigned_short.to_i32
      required_feature_index = data.read_unsigned_short.to_i32
      feature_index_count = data.read_unsigned_short.to_i32
      feature_indices = Array(Int32).new(feature_index_count)
      feature_index_count.times do |_|
        feature_indices << data.read_unsigned_short.to_i32
      end
      LangSysTable.new(lookup_order, required_feature_index, feature_index_count, feature_indices)
    end

    private def read_feature_list(data : TTFDataStream, offset : Int64) : FeatureListTable
      data.seek(offset)
      feature_count = data.read_unsigned_short.to_i32
      feature_records = Array(FeatureRecord).new(feature_count)
      feature_offsets = Array(Int32).new(feature_count)
      feature_tags = Array(String).new(feature_count)
      feature_count.times do |i|
        feature_tags << data.read_string(4)
        if i > 0 && feature_tags[i] < feature_tags[i - 1]
          # catch corrupt file
          if feature_tags[i].matches?(/\\w{4}/) && feature_tags[i - 1].matches?(/\\w{4}/)
            Log.debug { "FeatureRecord array not alphabetically sorted by FeatureTag: #{feature_tags[i]} < #{feature_tags[i - 1]}" }
          else
            Log.warn { "FeatureRecord array not alphabetically sorted by FeatureTag: #{feature_tags[i]} < #{feature_tags[i - 1]}" }
            return FeatureListTable.new(0, [] of FeatureRecord)
          end
        end
        feature_offsets << data.read_unsigned_short.to_i32
      end
      feature_count.times do |i|
        feature_table = read_feature_table(data, offset + feature_offsets[i])
        feature_records << FeatureRecord.new(feature_tags[i], feature_table)
      end
      FeatureListTable.new(feature_count, feature_records)
    end

    private def read_feature_table(data : TTFDataStream, offset : Int64) : FeatureTable
      data.seek(offset)
      feature_params = data.read_unsigned_short.to_i32
      lookup_index_count = data.read_unsigned_short.to_i32
      lookup_list_indices = Array(Int32).new(lookup_index_count)
      lookup_index_count.times do |_|
        lookup_list_indices << data.read_unsigned_short.to_i32
      end
      FeatureTable.new(feature_params, lookup_index_count, lookup_list_indices)
    end

    private def read_lookup_list(data : TTFDataStream, offset : Int64) : LookupListTable
      data.seek(offset)
      lookup_count = data.read_unsigned_short.to_i32
      lookups = Array(Int32).new(lookup_count)
      lookup_count.times do |i|
        lookups << data.read_unsigned_short.to_i32
        if lookups[i] == 0
          Log.error { "lookups[#{i}] is 0 at offset #{data.current_position - 2}" }
        elsif offset + lookups[i] > data.original_data_size
          Log.error { "#{offset + lookups[i]} > #{data.original_data_size}" }
        end
      end
      lookup_tables = Array(LookupTable).new(lookup_count)
      lookup_table_map = Hash(Int32, LookupTable).new
      lookup_count.times do |i|
        lookup_table = lookup_table_map[lookups[i]]?
        if lookup_table.nil?
          lookup_table = read_lookup_table(data, offset + lookups[i])
          lookup_table_map[lookups[i]] = lookup_table
        end
        lookup_tables << lookup_table
      end
      LookupListTable.new(lookup_count, lookup_tables)
    end

    private def read_lookup_table(data : TTFDataStream, offset : Int64) : LookupTable
      data.seek(offset)
      lookup_type = data.read_unsigned_short.to_i32
      lookup_flag = data.read_unsigned_short.to_i32
      sub_table_count = data.read_unsigned_short.to_i32
      sub_table_offsets = Array(Int32).new(sub_table_count)
      sub_table_count.times do |i|
        sub_table_offsets << data.read_unsigned_short.to_i32
        if sub_table_offsets[i] == 0
          Log.error { "subTableOffsets[#{i}] is 0 at offset #{data.current_position - 2}" }
          return LookupTable.new(lookup_type, lookup_flag, 0, [] of LookupSubTable)
        elsif offset + sub_table_offsets[i] > data.original_data_size
          Log.error { "#{offset + sub_table_offsets[i]} > #{data.original_data_size}" }
          return LookupTable.new(lookup_type, lookup_flag, 0, [] of LookupSubTable)
        end
      end
      mark_filtering_set = 0
      if (lookup_flag & 0x0010) != 0
        mark_filtering_set = data.read_unsigned_short.to_i32
      end
      sub_tables = Array(LookupSubTable | Nil).new(sub_table_count) { nil }
      case lookup_type
      when 1, 2, 3, 4
        sub_table_count.times do |i|
          sub_tables[i] = read_lookup_subtable(data, offset + sub_table_offsets[i], lookup_type)
        end
      when 7
        # Extension Substitution
        sub_table_count.times do |i|
          data.seek(offset + sub_table_offsets[i])
          subst_format = data.read_unsigned_short.to_i32
          if subst_format != 1
            Log.error { "The expected SubstFormat for ExtensionSubstFormat1 subtable is #{subst_format} but should be 1 at offset #{offset + sub_table_offsets[i]}" }
            next
          end
          extension_lookup_type = data.read_unsigned_short.to_i32
          if lookup_type != 7 && lookup_type != extension_lookup_type
            Log.error { "extensionLookupType changed from #{lookup_type} to #{extension_lookup_type} at offset #{offset + sub_table_offsets[i] + 2}" }
            next
          end
          lookup_type = extension_lookup_type
          extension_offset = data.read_unsigned_int.to_i64
          extension_lookup_table_address = offset + sub_table_offsets[i] + extension_offset
          sub_tables[i] = read_lookup_subtable(data, extension_lookup_table_address, extension_lookup_type)
        end
      else
        Log.debug { "Type #{lookup_type} GSUB lookup table is not supported and will be ignored" }
      end
      LookupTable.new(lookup_type, lookup_flag, mark_filtering_set, sub_tables.compact)
    end

    private def read_lookup_subtable(data : TTFDataStream, offset : Int64, lookup_type : Int32) : LookupSubTable?
      case lookup_type
      when 1
        read_single_lookup_subtable(data, offset)
      when 2
        read_multiple_substitution_subtable(data, offset)
      when 3
        read_alternate_substitution_subtable(data, offset)
      when 4
        read_ligature_substitution_subtable(data, offset)
      else
        Log.debug { "Type #{lookup_type} GSUB lookup table is not supported and will be ignored" }
        nil
      end
    end

    private def read_single_lookup_subtable(data : TTFDataStream, offset : Int64) : LookupSubTable?
      data.seek(offset)
      subst_format = data.read_unsigned_short.to_i32
      case subst_format
      when 1
        coverage_offset = data.read_unsigned_short.to_i32
        delta_glyph_id = data.read_signed_short
        coverage_table = read_coverage_table(data, offset + coverage_offset)
        LookupTypeSingleSubstFormat1.new(subst_format, coverage_table, delta_glyph_id)
      when 2
        coverage_offset = data.read_unsigned_short.to_i32
        glyph_count = data.read_unsigned_short.to_i32
        substitute_glyph_ids = Array(Int32).new(glyph_count)
        glyph_count.times do |_|
          substitute_glyph_ids << data.read_unsigned_short.to_i32
        end
        coverage_table = read_coverage_table(data, offset + coverage_offset)
        LookupTypeSingleSubstFormat2.new(subst_format, coverage_table, substitute_glyph_ids)
      else
        Log.warn { "Unknown substFormat: #{subst_format}" }
        nil
      end
    end

    private def read_multiple_substitution_subtable(data : TTFDataStream, offset : Int64) : LookupSubTable?
      data.seek(offset)
      subst_format = data.read_unsigned_short.to_i32
      if subst_format != 1
        # TODO: raise IOException
        return
      end
      coverage = data.read_unsigned_short.to_i32
      sequence_count = data.read_unsigned_short.to_i32
      sequence_offsets = Array(Int32).new(sequence_count)
      sequence_count.times do |_|
        sequence_offsets << data.read_unsigned_short.to_i32
      end
      coverage_table = read_coverage_table(data, offset + coverage)
      if sequence_count != coverage_table.get_size
        # TODO: raise IOException
        return
      end
      sequence_tables = Array(SequenceTable).new(sequence_count)
      sequence_count.times do |i|
        data.seek(offset + sequence_offsets[i])
        glyph_count = data.read_unsigned_short.to_i32
        substitute_glyph_ids = data.read_unsigned_short_array(glyph_count)
        sequence_tables << SequenceTable.new(glyph_count, substitute_glyph_ids)
      end
      LookupTypeMultipleSubstitutionFormat1.new(subst_format, coverage_table, sequence_tables)
    end

    private def read_alternate_substitution_subtable(data : TTFDataStream, offset : Int64) : LookupSubTable?
      data.seek(offset)
      subst_format = data.read_unsigned_short.to_i32
      if subst_format != 1
        # TODO: raise IOException
        return
      end
      coverage = data.read_unsigned_short.to_i32
      alt_set_count = data.read_unsigned_short.to_i32
      alternate_offsets = Array(Int32).new(alt_set_count)
      alt_set_count.times do |_|
        alternate_offsets << data.read_unsigned_short.to_i32
      end
      coverage_table = read_coverage_table(data, offset + coverage)
      if alt_set_count != coverage_table.get_size
        # TODO: raise IOException
        return
      end
      alternate_set_tables = Array(AlternateSetTable).new(alt_set_count)
      alt_set_count.times do |i|
        data.seek(offset + alternate_offsets[i])
        glyph_count = data.read_unsigned_short.to_i32
        alternate_glyph_ids = data.read_unsigned_short_array(glyph_count)
        alternate_set_tables << AlternateSetTable.new(glyph_count, alternate_glyph_ids)
      end
      LookupTypeAlternateSubstitutionFormat1.new(subst_format, coverage_table, alternate_set_tables)
    end

    private def read_ligature_substitution_subtable(data : TTFDataStream, offset : Int64) : LookupSubTable?
      data.seek(offset)
      subst_format = data.read_unsigned_short.to_i32
      if subst_format != 1
        # TODO: raise IOException
        return
      end
      coverage = data.read_unsigned_short.to_i32
      lig_set_count = data.read_unsigned_short.to_i32
      ligature_offsets = Array(Int32).new(lig_set_count)
      lig_set_count.times do |_|
        ligature_offsets << data.read_unsigned_short.to_i32
      end
      coverage_table = read_coverage_table(data, offset + coverage)
      if lig_set_count != coverage_table.get_size
        # TODO: raise IOException
        return
      end
      ligature_set_tables = Array(LigatureSetTable).new(lig_set_count)
      lig_set_count.times do |i|
        coverage_glyph_id = coverage_table.get_glyph_id(i)
        ligature_set_tables << read_ligature_set_table(data, offset + ligature_offsets[i], coverage_glyph_id)
      end
      LookupTypeLigatureSubstitutionSubstFormat1.new(subst_format, coverage_table, ligature_set_tables)
    end

    private def read_ligature_set_table(data : TTFDataStream, ligature_set_table_location : Int64, coverage_glyph_id : Int32) : LigatureSetTable
      data.seek(ligature_set_table_location)
      ligature_count = data.read_unsigned_short.to_i32
      ligature_offsets = Array(Int32).new(ligature_count)
      ligature_tables = Array(LigatureTable).new(ligature_count)
      ligature_count.times do |_|
        ligature_offsets << data.read_unsigned_short.to_i32
      end
      ligature_count.times do |i|
        ligature_offset = ligature_offsets[i]
        ligature_tables << read_ligature_table(data, ligature_set_table_location + ligature_offset, coverage_glyph_id)
      end
      LigatureSetTable.new(ligature_count, ligature_tables)
    end

    private def read_ligature_table(data : TTFDataStream, ligature_table_location : Int64, coverage_glyph_id : Int32) : LigatureTable
      data.seek(ligature_table_location)
      ligature_glyph = data.read_unsigned_short.to_i32
      component_count = data.read_unsigned_short.to_i32
      if component_count > 100
        # TODO: raise IOException
        component_count = 0
      end
      component_glyph_ids = Array(Int32).new(component_count)
      if component_count > 0
        component_glyph_ids << coverage_glyph_id
      end
      (1...component_count).each do |_|
        component_glyph_ids << data.read_unsigned_short.to_i32
      end
      LigatureTable.new(ligature_glyph, component_count, component_glyph_ids)
    end

    private def read_coverage_table(data : TTFDataStream, offset : Int64) : CoverageTable
      data.seek(offset)
      coverage_format = data.read_unsigned_short.to_i32
      case coverage_format
      when 1
        glyph_count = data.read_unsigned_short.to_i32
        glyph_array = Array(Int32).new(glyph_count)
        glyph_count.times do |_|
          glyph_array << data.read_unsigned_short.to_i32
        end
        CoverageTableFormat1.new(coverage_format, glyph_array)
      when 2
        range_count = data.read_unsigned_short.to_i32
        range_records = Array(RangeRecord).new(range_count)
        range_count.times do |_|
          range_records << read_range_record(data)
        end
        CoverageTableFormat2.new(coverage_format, range_records)
      else
        # TODO: raise IOException
        CoverageTableFormat1.new(1, [] of Int32)
      end
    end

    private def read_range_record(data : TTFDataStream) : RangeRecord
      start_glyph_id = data.read_unsigned_short.to_i32
      end_glyph_id = data.read_unsigned_short.to_i32
      start_coverage_index = data.read_unsigned_short.to_i32
      RangeRecord.new(start_glyph_id, end_glyph_id, start_coverage_index)
    end
  end

  module Model
    abstract class GsubData
      abstract def get_language : Language
      abstract def get_active_script_name : String
      abstract def is_feature_supported(feature_name : String) : Bool
      abstract def get_feature(feature_name : String) : ScriptFeature
      abstract def get_supported_features : Set(String)

      class NoDataFoundGsubData < GsubData
        def get_language : Language
          raise "UnsupportedOperationException"
        end

        def get_active_script_name : String
          raise "UnsupportedOperationException"
        end

        def is_feature_supported(feature_name : String) : Bool
          raise "UnsupportedOperationException"
        end

        def get_feature(feature_name : String) : ScriptFeature
          raise "UnsupportedOperationException"
        end

        def get_supported_features : Set(String)
          raise "UnsupportedOperationException"
        end
      end

      NO_DATA_FOUND = NoDataFoundGsubData.new
    end

    enum Language
      BENGALI
      DEVANAGARI
      GUJARATI
      TAMIL
      LATIN
      DFLT
      UNSPECIFIED

      def script_names : Array(String)
        case self
        when BENGALI    then ["bng2", "beng"]
        when DEVANAGARI then ["dev2", "deva"]
        when GUJARATI   then ["gjr2", "gujr"]
        when TAMIL      then ["tml2", "taml"]
        when LATIN      then ["latn"]
        when DFLT       then ["DFLT"]
        else                 [] of String
        end
      end
    end

    abstract class ScriptFeature
      abstract def get_name : String
      abstract def get_all_glyph_ids_for_substitution : Set(Array(Int32))
      abstract def can_replace_glyphs(glyph_ids : Array(Int32)) : Bool
      abstract def get_replacement_for_glyphs(glyph_ids : Array(Int32)) : Array(Int32)
    end

    class MapBackedScriptFeature < ScriptFeature
      def initialize(@name : String, @feature_map : Hash(Array(Int32), Array(Int32)))
      end

      def get_name : String
        @name
      end

      def get_all_glyph_ids_for_substitution : Set(Array(Int32))
        @feature_map.keys.to_set
      end

      def can_replace_glyphs(glyph_ids : Array(Int32)) : Bool
        @feature_map.has_key?(glyph_ids)
      end

      def get_replacement_for_glyphs(glyph_ids : Array(Int32)) : Array(Int32)
        unless can_replace_glyphs(glyph_ids)
          raise "The glyphs #{glyph_ids} cannot be replaced"
        end
        @feature_map[glyph_ids]
      end
    end

    class MapBackedGsubData < GsubData
      def initialize(@language : Language, @active_script_name : String, @glyph_substitution_map : Hash(String, Hash(Array(Int32), Array(Int32))))
      end

      def get_language : Language
        @language
      end

      def get_active_script_name : String
        @active_script_name
      end

      def is_feature_supported(feature_name : String) : Bool
        @glyph_substitution_map.has_key?(feature_name)
      end

      def get_feature(feature_name : String) : ScriptFeature
        feature_map = @glyph_substitution_map[feature_name]?
        if feature_map.nil?
          raise "Feature #{feature_name} not supported"
        end
        MapBackedScriptFeature.new(feature_name, feature_map)
      end

      def get_supported_features : Set(String)
        Set.new(@glyph_substitution_map.keys)
      end
    end
  end

  MapBackedGsubData = Model::MapBackedGsubData
  GsubData          = Model::GsubData
end

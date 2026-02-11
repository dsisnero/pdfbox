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
      data.seek(data.get_current_position + 44)
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
    def get_index_to_loc_format : Int16
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
    def get_units_per_em : UInt16
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
    def get_number_of_h_metrics : UInt16
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
    def get_num_glyphs : UInt16
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

      if data.get_current_position == data.get_original_data_size
        # TODO: Log warning - No PostScript name data is provided for the font
        # LOG.warn("No PostScript name data is provided for the font #{ttf.get_name}")
      elsif @format_type == 1.0_f32
        # This TrueType font file contains exactly the 258 glyphs in the standard Macintosh TrueType.
        @glyph_names = WGL4Names.get_all_names
      elsif @format_type == 2.0_f32
        num_glyphs = data.read_unsigned_short.to_i32
        glyph_name_index = Array(Int32).new(num_glyphs)
        @glyph_names = Array(String).new(num_glyphs)
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
            @glyph_names.as(Array(String))[i] = WGL4Names.get_glyph_name(index)
          elsif index >= WGL4Names::NUMBER_OF_MAC_GLYPHS && index <= 32767 && !name_array.nil?
            @glyph_names.as(Array(String))[i] = name_array.as(Array(String))[index - WGL4Names::NUMBER_OF_MAC_GLYPHS]
          else
            # PDFBOX-808: Index numbers between 32768 and 65535 are
            # reserved for future use, so we should just ignore them
            @glyph_names.as(Array(String))[i] = ".undefined"
          end
        end
      elsif @format_type == 2.5_f32
        num_glyphs = ttf.get_number_of_glyphs
        if num_glyphs <= 0
          # TODO: Log error - invalid number of glyphs
        else
          glyph_name_index = Array(Int32).new(num_glyphs)
          num_glyphs.times do |i|
            offset = data.read_signed_byte
            glyph_name_index << i + 1 + offset
          end
          @glyph_names = Array(String).new(num_glyphs)
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

    # This will read required headers from the stream into out_headers.
    def read_headers(ttf : TrueTypeFont, data : TTFDataStream, out_headers : FontHeaders) : Nil
      # TODO: Implement naming table header reading
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

    # This will read required headers from the stream into out_headers.
    def read_headers(ttf : TrueTypeFont, data : TTFDataStream, out_headers : FontHeaders) : Nil
      # TODO: Implement CFF table header reading
    end
  end

  # CMAP table (Character to Glyph Mapping).
  #
  # Ported from Apache PDFBox CmapTable.
  class CmapTable < TTFTable
    # Tag for this table.
    TAG = "cmap"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement CMAP table reading
    end
  end

  # GLYF table (Glyph Data).
  #
  # Ported from Apache PDFBox GlyphTable.
  class GlyphTable < TTFTable
    # Tag for this table.
    TAG = "glyf"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement GLYF table reading
    end
  end

  # HMTX table (Horizontal Metrics).
  #
  # Ported from Apache PDFBox HorizontalMetricsTable.
  class HorizontalMetricsTable < TTFTable
    # Tag for this table.
    TAG = "hmtx"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement HMTX table reading
    end
  end

  # LOCA table (Index to Location).
  #
  # Ported from Apache PDFBox IndexToLocationTable.
  class IndexToLocationTable < TTFTable
    # Tag for this table.
    TAG = "loca"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement LOCA table reading
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
      # TODO: Implement DSIG table reading
    end
  end

  # KERN table (Kerning).
  #
  # Ported from Apache PDFBox KerningTable.
  class KerningTable < TTFTable
    # Tag for this table.
    TAG = "kern"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement KERN table reading
    end
  end

  # VHEA table (Vertical Header).
  #
  # Ported from Apache PDFBox VerticalHeaderTable.
  class VerticalHeaderTable < TTFTable
    # Tag for this table.
    TAG = "vhea"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement VHEA table reading
    end
  end

  # VMTX table (Vertical Metrics).
  #
  # Ported from Apache PDFBox VerticalMetricsTable.
  class VerticalMetricsTable < TTFTable
    # Tag for this table.
    TAG = "vmtx"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement VMTX table reading
    end
  end

  # VORG table (Vertical Origin).
  #
  # Ported from Apache PDFBox VerticalOriginTable.
  class VerticalOriginTable < TTFTable
    # Tag for this table.
    TAG = "VORG"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement VORG table reading
    end
  end

  # GSUB table (Glyph Substitution).
  #
  # Ported from Apache PDFBox GlyphSubstitutionTable.
  class GlyphSubstitutionTable < TTFTable
    # Tag for this table.
    TAG = "GSUB"

    # This will read the required data from the stream.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # TODO: Implement GSUB table reading
    end
  end
end

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

# ameba:disable Naming/AccessorMethodName
module Fontbox::TTF
  # A TrueType font file.
  #
  # Ported from Apache PDFBox TrueTypeFont.
  class TrueTypeFont
    @version : Float32 = 0.0_f32
    @number_of_glyphs : Int32 = -1
    @units_per_em : Int32 = -1
    @enable_gsub : Bool = true
    @tables = Hash(String, TTFTable).new
    @data : TTFDataStream
    @post_script_names : Hash(String, Int32)?

    @enabled_gsub_features = [] of String

    # Constructor. Clients should use the TTFParser to create a new TrueTypeFont object.
    #
    # @param font_data The font data.
    def initialize(font_data : TTFDataStream)
      @data = font_data
    end

    def close : Nil
      @data.close
    end

    # Gets the version.
    def version : Float32
      @version
    end

    # Set the version. Package-private, used by TTFParser only.
    protected def version=(version_value : Float32)
      @version = version_value
    end

    # Returns true if the GSUB table can be used for this font
    def enable_gsub? : Bool
      @enable_gsub
    end

    # Enable or disable the GSUB table for this font.
    def enable_gsub=(enable_gsub : Bool)
      @enable_gsub = enable_gsub
    end

    # Gets the original data size.
    def get_original_data_size : Int64
      @data.get_original_data_size
    end

    # Gets a table by tag.
    def get_table(tag : String) : TTFTable?
      @tables[tag]?
    end

    # Adds a table.
    def add_table(table : TTFTable) : Nil
      @tables[table.tag] = table
    end

    # Gets all tables.
    def get_tables : Array(TTFTable)
      @tables.values.to_a
    end

    # Gets the header table.
    def get_header : HeaderTable?
      table = get_table(HeaderTable::TAG).as?(HeaderTable)
      if table && !table.get_initialized
        read_table(table)
      end
      table
    end

    # Gets the horizontal header table.
    def get_horizontal_header : HorizontalHeaderTable?
      table = get_table(HorizontalHeaderTable::TAG).as?(HorizontalHeaderTable)
      if table && !table.get_initialized
        read_table(table)
      end
      table
    end

    # Gets the maximum profile table.
    def get_maximum_profile : MaximumProfileTable?
      table = get_table(MaximumProfileTable::TAG).as?(MaximumProfileTable)
      if table && !table.get_initialized
        read_table(table)
      end
      table
    end

    # Gets the postscript table.
    def get_postscript : PostScriptTable?
      get_table(PostScriptTable::TAG).as?(PostScriptTable)
    end

    # Gets the vertical header table.
    def get_vertical_header : VerticalHeaderTable?
      get_table(VerticalHeaderTable::TAG).as?(VerticalHeaderTable)
    end

    # Gets the vertical metrics table.
    def get_vertical_metrics : VerticalMetricsTable?
      get_table(VerticalMetricsTable::TAG).as?(VerticalMetricsTable)
    end

    # Gets the vertical origin table.
    def get_vertical_origin : VerticalOriginTable?
      get_table(VerticalOriginTable::TAG).as?(VerticalOriginTable)
    end

    # Gets the horizontal metrics table.
    def get_horizontal_metrics : HorizontalMetricsTable?
      table = get_table(HorizontalMetricsTable::TAG).as?(HorizontalMetricsTable)
      if table && !table.get_initialized
        read_table(table)
      end
      table
    end

    # Gets the index-to-location table.
    def get_index_to_location : IndexToLocationTable?
      table = get_table(IndexToLocationTable::TAG).as?(IndexToLocationTable)
      if table && !table.get_initialized
        read_table(table)
      end
      table
    end

    # Gets the glyph table.
    def get_glyph : GlyphTable?
      table = get_table(GlyphTable::TAG).as?(GlyphTable)
      if table && !table.get_initialized
        read_table(table)
      end
      table
    end

    # Gets the naming table.
    def get_naming : NamingTable?
      get_table(NamingTable::TAG).as?(NamingTable)
    end

    # Gets the OS/2 Windows metrics table.
    def get_os2_windows : OS2WindowsMetricsTable?
      get_table(OS2WindowsMetricsTable::TAG).as?(OS2WindowsMetricsTable)
    end

    # Gets the number of glyphs.
    def get_number_of_glyphs : Int32
      maxp = get_maximum_profile
      if maxp.nil?
        -1
      else
        maxp.get_num_glyphs.to_i32
      end
    end

    # Gets the units per em.
    def get_units_per_em : Int32
      header = get_header
      if header.nil?
        -1
      else
        header.get_units_per_em.to_i32
      end
    end

    # Reads a table.
    def read_table(table : TTFTable) : Nil
      return if table.get_initialized
      original_position = @data.get_current_position
      begin
        @data.seek(table.offset)
        table.read(self, @data)
      ensure
        @data.seek(original_position)
      end
    end

    # Reads table headers into the given FontHeaders object.
    def read_table_headers(tag : String, out_headers : FontHeaders) : Nil
      table = get_table(tag)
      return if table.nil?
      original_position = @data.get_current_position
      begin
        @data.seek(table.offset)
        table.read_headers(self, @data, out_headers)
      ensure
        @data.seek(original_position)
      end
    end

    # Reads up to n bytes from a table.
    def get_table_n_bytes(table : TTFTable, n : Int32) : Bytes
      original_position = @data.get_current_position
      begin
        @data.seek(table.offset)
        @data.read(n)
      ensure
        @data.seek(original_position)
      end
    end

    # Gets the font name.
    def get_name : String
      # TODO: Implement name retrieval from naming table
      ""
    end

    # Gets the cmap table.
    def get_cmap : CmapTable?
      get_table(CmapTable::TAG).as?(CmapTable)
    end

    # Returns the best Unicode cmap from the font (the most general).
    # The PDF spec says that "The means by which this is accomplished are implementation-dependent."
    # The returned cmap will perform glyph substitution.
    # @param is_strict False if we allow falling back to any cmap, even if it's not Unicode.
    # @return cmap to perform glyph substitution
    # @raise IO::Error if the font could not be read, or there is no Unicode cmap
    def get_unicode_cmap_lookup(is_strict : Bool = true) : CmapLookup
      cmap = get_unicode_cmap_impl(is_strict)
      # TODO: If enabled GSUB features, return SubstitutingCmapLookup
      cmap
    end

    private def get_unicode_cmap_impl(is_strict : Bool) : CmapSubtable
      cmap_table = get_cmap
      if cmap_table.nil?
        if is_strict
          raise IO::Error.new("The TrueType font #{get_name} does not contain a 'cmap' table")
        else
          raise IO::Error.new("No cmap table found")
        end
      end

      cmap = cmap_table.get_subtable(CmapTable::PLATFORM_UNICODE,
        CmapTable::ENCODING_UNICODE_2_0_FULL)
      if cmap.nil?
        cmap = cmap_table.get_subtable(CmapTable::PLATFORM_WINDOWS,
          CmapTable::ENCODING_WIN_UNICODE_FULL)
      end
      if cmap.nil?
        cmap = cmap_table.get_subtable(CmapTable::PLATFORM_UNICODE,
          CmapTable::ENCODING_UNICODE_2_0_BMP)
      end
      if cmap.nil?
        cmap = cmap_table.get_subtable(CmapTable::PLATFORM_WINDOWS,
          CmapTable::ENCODING_WIN_UNICODE_BMP)
      end
      if cmap.nil?
        # Microsoft's "Recommendations for OpenType Fonts" says that "Symbol" encoding
        # actually means "Unicode, non-standard character set"
        cmap = cmap_table.get_subtable(CmapTable::PLATFORM_WINDOWS,
          CmapTable::ENCODING_WIN_SYMBOL)
      end
      if cmap.nil?
        # PDFBOX-6015
        cmap = cmap_table.get_subtable(CmapTable::PLATFORM_UNICODE,
          CmapTable::ENCODING_UNICODE_1_1)
      end
      if cmap.nil?
        if is_strict
          raise IO::Error.new("The TrueType font does not contain a Unicode cmap")
        elsif cmap_table.cmaps.size > 0
          # fallback to the first cmap (may not be Unicode, so may produce poor results)
          cmap = cmap_table.cmaps[0]
        else
          raise IO::Error.new("No cmap subtables found")
        end
      end
      cmap
    end

    # Gets the GSUB table.
    def get_gsub : GlyphSubstitutionTable?
      get_table(GlyphSubstitutionTable::TAG).as?(GlyphSubstitutionTable)
    end

    # Gets the GSUB data for the font.
    def get_gsub_data : ::Fontbox::TTF::Model::GsubData
      unless enable_gsub?
        return ::Fontbox::TTF::Model::GsubData::NO_DATA_FOUND
      end

      table = get_gsub
      if table.nil?
        ::Fontbox::TTF::Model::GsubData::NO_DATA_FOUND
      else
        table.get_gsub_data || ::Fontbox::TTF::Model::GsubData::NO_DATA_FOUND
      end
    end
  end
end

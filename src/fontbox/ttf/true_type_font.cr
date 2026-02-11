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
      get_table(HeaderTable::TAG).as?(HeaderTable)
    end

    # Gets the horizontal header table.
    def get_horizontal_header : HorizontalHeaderTable?
      get_table(HorizontalHeaderTable::TAG).as?(HorizontalHeaderTable)
    end

    # Gets the maximum profile table.
    def get_maximum_profile : MaximumProfileTable?
      get_table(MaximumProfileTable::TAG).as?(MaximumProfileTable)
    end

    # Gets the postscript table.
    def get_postscript : PostScriptTable?
      get_table(PostScriptTable::TAG).as?(PostScriptTable)
    end

    # Gets the naming table.
    def get_naming : NamingTable?
      get_table(NamingTable::TAG).as?(NamingTable)
    end

    # Gets the OS/2 Windows metrics table.
    def get_os2_windows : OS2WindowsMetricsTable?
      get_table(OS2WindowsMetricsTable::TAG).as?(OS2WindowsMetricsTable)
    end

    # Reads a table.
    def read_table(table : TTFTable) : Nil
      # TODO: Implement table reading
    end

    # Gets the font name.
    def get_name : String
      # TODO: Implement name retrieval from naming table
      ""
    end
  end
end

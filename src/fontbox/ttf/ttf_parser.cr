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
  # TrueType font file parser.
  #
  # Ported from Apache PDFBox TTFParser.
  class TTFParser
    @is_embedded : Bool = false

    # Constructor.
    def initialize
      initialize(false)
    end

    # Constructor.
    #
    # @param is_embedded true if the font is embedded in PDF
    def initialize(is_embedded : Bool)
      @is_embedded = is_embedded
    end

    # Parse a RandomAccessRead and return a TrueType font.
    #
    # @param random_access_read The RandomAccessRead to be read from. It will be closed before returning.
    # @return A TrueType font.
    def parse(random_access_read : Pdfbox::IO::RandomAccessRead) : TrueTypeFont
      data_stream = RandomAccessReadDataStream.new(random_access_read)
      begin
        parse(data_stream)
      rescue ex : IO::Error
        # close only on error (source is still being accessed later)
        data_stream.close
        raise ex
      ensure
        random_access_read.close
      end
    end

    # Parse an input stream and return a TrueType font that is to be embedded.
    #
    # @param input_stream The TTF data stream to parse from. It will be closed before returning.
    # @return A TrueType font.
    def parse_embedded(input_stream : IO) : TrueTypeFont
      @is_embedded = true
      data_stream = RandomAccessReadDataStream.new(input_stream)
      begin
        parse(data_stream)
      rescue ex : IO::Error
        # close only on error (source is still being accessed later)
        data_stream.close
        raise ex
      ensure
        input_stream.close
      end
    end

    # Parse a RandomAccessRead and return the table headers.
    #
    # @param random_access_read The random_access_read to be read from. It will be closed before returning.
    # @return TrueType font headers.
    def parse_table_headers(random_access_read : Pdfbox::IO::RandomAccessRead) : FontHeaders
      data_stream = RandomAccessReadUnbufferedDataStream.new(random_access_read)
      begin
        parse_table_headers(data_stream)
      ensure
        # data_stream closes random_access_read
        data_stream.close
      end
    end

    # Parse a file and get a true type font.
    #
    # @param raf The TTF file.
    # @return A TrueType font.
    private def create_font_with_tables(raf : TTFDataStream) : TrueTypeFont
      font = new_font(raf)
      font.version = raf.read_32_fixed
      number_of_tables = raf.read_unsigned_short
      _search_range = raf.read_unsigned_short
      _entry_selector = raf.read_unsigned_short
      _range_shift = raf.read_unsigned_short
      number_of_tables.times do |_|
        table = read_table_directory(raf)

        # skip tables with zero length
        if !table.nil?
          if table.offset + table.length > font.get_original_data_size
            # PDFBOX-5285 if we're lucky, this is an "unimportant" table, e.g. vmtx
            # TODO: Log warning
            # LOG.warn("Skip table '#{table.tag}' which goes past the file size; offset: #{table.offset}, size: #{table.length}, font size: #{font.get_original_data_size}")
          else
            font.add_table(table)
          end
        end
      end
      font
    end

    def parse(raf : TTFDataStream) : TrueTypeFont
      font = create_font_with_tables(raf)
      parse_tables(font)
      font
    end

    def new_font(raf : TTFDataStream) : TrueTypeFont
      TrueTypeFont.new(raf)
    end

    # Parse all tables and check if all needed tables are present.
    #
    # @param font the TrueTypeFont instance holding the parsed data.
    private def parse_tables(font : TrueTypeFont) : Nil
      font.get_tables.each do |table|
        if !table.get_initialized
          font.read_table(table)
        end
      end

      has_cff = font.get_table(CFFTable::TAG) != nil
      # TODO: Implement OpenTypeFont check
      is_otf = false
      _is_post_script = is_otf ? false : has_cff

      head = font.get_header
      if head.nil?
        raise IO::Error.new("'head' table is mandatory")
      end

      hh = font.get_horizontal_header
      if hh.nil?
        raise IO::Error.new("'hhea' table is mandatory")
      end

      maxp = font.get_maximum_profile
      if maxp.nil?
        raise IO::Error.new("'maxp' table is mandatory")
      end

      # TODO: Check for other required tables
    end

    private def parse_table_headers(raf : TTFDataStream) : FontHeaders
      out_headers = FontHeaders.new
      font = create_font_with_tables(raf)

      # Read naming table headers
      naming_table = font.get_table(NamingTable::TAG)
      if naming_table
        font.read_table_headers(NamingTable::TAG, out_headers)
      end

      # Read header table headers
      header_table = font.get_table(HeaderTable::TAG)
      if header_table
        font.read_table_headers(HeaderTable::TAG, out_headers)
      end

      # Set OS/2 windows metrics
      os2_table = font.get_table(OS2WindowsMetricsTable::TAG)
      if os2_table
        out_headers.set_os2_windows(os2_table.as(OS2WindowsMetricsTable))
      end

      # Check for CFF table (OpenType PostScript)
      has_cff = font.get_table(CFFTable::TAG) != nil
      # TODO: Implement OpenTypeFont check
      is_otf = false
      is_otf_and_post_script = false
      if is_otf
        # TODO: Handle OpenType font
        nil
      elsif !is_otf && has_cff
        out_headers.set_error("True Type fonts using CFF outlines are not supported")
        return out_headers
      else
        # non-OTF with possible gcid table
        gcid_table = font.get_table("gcid")
        if gcid_table && gcid_table.length >= FontHeaders::BYTES_GCID
          out_headers.set_non_otf_gcid142(font.get_table_n_bytes(gcid_table, FontHeaders::BYTES_GCID))
        end
      end
      out_headers.set_is_otf_and_post_script(is_otf_and_post_script)

      # Check mandatory tables
      mandatory_tables = [
        HeaderTable::TAG,
        HorizontalHeaderTable::TAG,
        MaximumProfileTable::TAG,
        @is_embedded ? nil : PostScriptTable::TAG,
        is_otf_and_post_script ? nil : IndexToLocationTable::TAG,
        is_otf_and_post_script ? nil : GlyphTable::TAG,
        @is_embedded ? nil : NamingTable::TAG,
        HorizontalMetricsTable::TAG,
        @is_embedded ? nil : CmapTable::TAG,
      ].compact

      mandatory_tables.each do |tag|
        if !font.get_table(tag)
          out_headers.set_error("'#{tag}' table is mandatory")
          return out_headers
        end
      end

      out_headers
    end

    private def read_table_directory(raf : TTFDataStream) : TTFTable?
      table : TTFTable
      tag = raf.read_string(4)
      case tag
      when CmapTable::TAG
        table = CmapTable.new
      when GlyphTable::TAG
        table = GlyphTable.new
      when HeaderTable::TAG
        table = HeaderTable.new
      when HorizontalHeaderTable::TAG
        table = HorizontalHeaderTable.new
      when HorizontalMetricsTable::TAG
        table = HorizontalMetricsTable.new
      when IndexToLocationTable::TAG
        table = IndexToLocationTable.new
      when MaximumProfileTable::TAG
        table = MaximumProfileTable.new
      when NamingTable::TAG
        table = NamingTable.new
      when OS2WindowsMetricsTable::TAG
        table = OS2WindowsMetricsTable.new
      when PostScriptTable::TAG
        table = PostScriptTable.new
      when DigitalSignatureTable::TAG
        table = DigitalSignatureTable.new
      when KerningTable::TAG
        table = KerningTable.new
      when VerticalHeaderTable::TAG
        table = VerticalHeaderTable.new
      when VerticalMetricsTable::TAG
        table = VerticalMetricsTable.new
      when VerticalOriginTable::TAG
        table = VerticalOriginTable.new
      when GlyphSubstitutionTable::TAG
        table = GlyphSubstitutionTable.new
      when CFFTable::TAG
        table = CFFTable.new
      else
        # unknown table type but read it anyway.
        table = TTFTable.new
      end
      table.tag = tag
      table.check_sum = raf.read_unsigned_int.to_i64
      table.offset = raf.read_unsigned_int.to_i64
      table.length = raf.read_unsigned_int.to_i64

      # skip tables with zero length (except glyf)
      if table.length == 0 && tag != GlyphTable::TAG
        return
      end

      table
    end
  end
end

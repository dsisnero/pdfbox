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
  # A TrueType Collection, now more properly known as a "Font Collection" as it may contain either
  # TrueType or OpenType fonts.
  #
  # Ported from Apache PDFBox TrueTypeCollection.
  class TrueTypeCollection
    @stream : TTFDataStream
    @num_fonts : Int32
    @font_offsets : Array(Int64)

    # Creates a new TrueTypeCollection from a .ttc file.
    #
    # @param file The TTC file.
    # @raise IO::Error If the font could not be parsed.
    def initialize(file : ::File)
      initialize(create_buffered_data_stream(Pdfbox::IO::RandomAccessReadBufferedFile.new(file.path), true))
    end

    # Creates a new TrueTypeCollection from a .ttc input stream.
    #
    # @param stream A TTC input stream.
    # @raise IO::Error If the font could not be parsed.
    def initialize(stream : IO)
      initialize(create_buffered_data_stream(Pdfbox::IO::RandomAccessReadBuffer.create_buffer_from_stream(stream), false))
    end

    # Creates a new TrueTypeCollection from a TTFDataStream.
    #
    # @param stream A data stream to read.
    # @raise IO::Error If the font could not be parsed.
    private def initialize(stream : TTFDataStream)
      @stream = stream

      # TTC header
      tag = stream.read_tag
      if tag != "ttcf"
        raise IO::Error.new("Missing TTC header")
      end
      version = stream.read_32_fixed
      @num_fonts = stream.read_unsigned_int.to_i32
      if @num_fonts <= 0 || @num_fonts > 1024
        raise IO::Error.new("Invalid number of fonts #{@num_fonts}")
      end
      @font_offsets = Array(Int64).new(@num_fonts)
      @num_fonts.times do |i|
        @font_offsets[i] = stream.read_unsigned_int.to_i64
      end
      if version >= 2.0_f32
        # not used at this time
        _ul_dsig_tag = stream.read_unsigned_short
        _ul_dsig_length = stream.read_unsigned_short
        _ul_dsig_offset = stream.read_unsigned_short
      end
    end

    private def create_buffered_data_stream(random_access_read : Pdfbox::IO::RandomAccessRead, close_after_reading : Bool) : TTFDataStream
      RandomAccessReadDataStream.new(random_access_read)
    ensure
      if close_after_reading
        random_access_read.close
      end
    end

    # Close the underlying resources.
    def close : Nil
      @stream.close
    end

    # Run the callback for each TT font in the collection.
    #
    # @param true_type_font_processor the object with the callback method.
    # @raise IO::Error if something went wrong when parsing any font or calling the TrueTypeFontProcessor
    def process_all_fonts(true_type_font_processor : TrueTypeFontProcessor) : Nil
      @num_fonts.times do |i|
        font = get_font_at_index(i)
        true_type_font_processor.process(font)
      end
    end

    # Run the callback for each TT font in the collection.
    #
    # @param true_type_font_processor the object with the callback method.
    # @raise IO::Error if something went wrong when parsing any font
    def self.process_all_font_headers(ttc_file : ::File, true_type_font_processor : TrueTypeFontHeadersProcessor) : Nil
      read = Pdfbox::IO::RandomAccessReadBufferedFile.new(ttc_file.path)
      stream = RandomAccessReadUnbufferedDataStream.new(read)
      ttc = new(stream)
      begin
        ttc.@num_fonts.times do |i|
          parser = ttc.create_font_parser_at_index_and_seek(i)
          headers = parser.parse_table_headers(TTCDataStream.new(ttc.@stream))
          true_type_font_processor.process(headers)
        end
      ensure
        ttc.close
      end
    end

    private def get_font_at_index(idx : Int32) : TrueTypeFont
      parser = create_font_parser_at_index_and_seek(idx)
      parser.parse(TTCDataStream.new(@stream))
    end

    private def create_font_parser_at_index_and_seek(idx : Int32) : TTFParser
      @stream.seek(@font_offsets[idx])
      parser = if @stream.read_tag == "OTTO"
                 # TODO: Implement OTFParser
                 raise "OTFParser not implemented"
               else
                 TTFParser.new(false)
               end
      @stream.seek(@font_offsets[idx])
      parser
    end

    # Get a TT font from a collection.
    #
    # @param name The postscript name of the font.
    # @return The found font, or nil if none is found.
    # @raise IO::Error if there is an error reading the font data
    def get_font_by_name(name : String) : TrueTypeFont?
      @num_fonts.times do |i|
        font = get_font_at_index(i)
        if font.get_name == name
          return font
        end
      end
      nil
    end

    # Implement the callback method to call {#process_all_fonts}.
    alias TrueTypeFontProcessor = Proc(TrueTypeFont, Nil)

    # Implement the callback method to call {.process_all_font_headers}.
    alias TrueTypeFontHeadersProcessor = Proc(FontHeaders, Nil)
  end
end

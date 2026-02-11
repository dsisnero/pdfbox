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
  end
end

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

require "log"

module Fontbox::Pfb
  # Parser for a pfb-file.
  class PfbParser
    # the pfb header length.
    # (start-marker (1 byte), ascii-/binary-marker (1 byte), size (4 byte))
    # 3*6 == 18
    private PFB_HEADER_LENGTH = 18

    # the start marker.
    private START_MARKER = 0x80_u8

    # the ascii marker.
    private ASCII_MARKER = 0x01_u8

    # the binary marker.
    private BINARY_MARKER = 0x02_u8

    # the EOF marker.
    private EOF_MARKER = 0x03_u8

    # the parsed pfb-data.
    @pfbdata = [] of UInt8

    # the lengths of the records (ASCII, BINARY, ASCII)
    @lengths = [] of Int32

    # sample (pfb-file)
    # 00000000 80 01 8b 15  00 00 25 21  50 53 2d 41  64 6f 62 65
    #          ......%!PS-Adobe

    # Create a new object.
    # @param filename  the file name
    # @raises Exception if an IO-error occurs.
    def initialize(filename : String)
      initialize(File.read(filename).to_slice)
    end

    # Create a new object.
    # @param input   The input.
    # @raises Exception if an IO-error occurs.
    def initialize(input : IO)
      buffer = IO::Memory.new
      IO.copy(input, buffer)
      bytes = buffer.to_slice
      initialize(bytes)
    end

    # Create a new object.
    # @param bytes   The input.
    # @raises Exception if an IO-error occurs.
    def initialize(bytes : Bytes)
      parse_pfb(bytes)
    end

    # Parse the pfb-array.
    # @param pfb   The pfb-Array
    # @raises Exception in an IO-error occurs.
    private def parse_pfb(pfb : Bytes) : Nil
      if pfb.size < PFB_HEADER_LENGTH
        raise "PFB header missing"
      end

      type_list = [] of Int32
      barr_list = [] of Bytes
      io = IO::Memory.new(pfb)
      total = 0_i64

      loop do
        r = io.read_byte
        if r.nil? && total > 0
          break # EOF
        end
        if r.nil? || r != START_MARKER
          raise "Start marker missing"
        end

        record_type = io.read_byte
        if record_type.nil?
          raise "Unexpected EOF reading record type"
        end
        if record_type == EOF_MARKER
          break
        end
        if record_type != ASCII_MARKER && record_type != BINARY_MARKER
          raise "Incorrect record type: #{record_type}"
        end

        size = read_le_int32(io)
        Log.debug { "record type: #{record_type}, segment size: #{size}" }
        if size > pfb.size
          # PDFBOX-6044: avoid potential OOM
          raise "record size #{size} would be larger than the input"
        end

        ar = Bytes.new(size)
        got = io.read_fully(ar)
        if got != size
          raise "EOF while reading PFB font"
        end
        total += size
        type_list << record_type
        barr_list << ar
      end

      # We now have ASCII and binary segments. Lets arrange these so that the ASCII segments
      # come first, then the binary segments, then the last ASCII segment if it is
      # 0000... cleartomark

      if total > pfb.size
        # PDFBOX-6044: avoid potential OOM
        raise "total record size #{total} would be larger than the input"
      end

      @pfbdata = Array(UInt8).new(total.to_i32)
      cleartomark_segment = nil
      dst_pos = 0

      # copy the ASCII segments
      type_list.each_with_index do |type, i|
        next unless type == ASCII_MARKER
        ar = barr_list[i]
        if i == type_list.size - 1 && ar.size < 600 &&
           String.new(ar).includes?("cleartomark")
          cleartomark_segment = ar
          next
        end
        @pfbdata[dst_pos, ar.size] = ar.to_a
        dst_pos += ar.size
      end
      @lengths = [0, 0, 0]
      @lengths[0] = dst_pos

      # copy the binary segments
      type_list.each_with_index do |type, i|
        next unless type == BINARY_MARKER
        ar = barr_list[i]
        @pfbdata[dst_pos, ar.size] = ar.to_a
        dst_pos += ar.size
      end
      @lengths[1] = dst_pos - @lengths[0]

      if cleartomark_segment
        ar = cleartomark_segment
        @pfbdata[dst_pos, ar.size] = ar.to_a
        @lengths[2] = ar.size
      end
    end

    private def read_le_int32(io : IO) : Int32
      b1 = io.read_byte
      b2 = io.read_byte
      b3 = io.read_byte
      b4 = io.read_byte
      if b1.nil? || b2.nil? || b3.nil? || b4.nil?
        raise "Unexpected EOF reading size"
      end
      b1.to_i32 | (b2.to_i32 << 8) | (b3.to_i32 << 16) | (b4.to_i32 << 24)
    end

    # Returns the lengths.
    def lengths : Array(Int32)
      @lengths
    end

    # Returns the pfbdata.
    def pfbdata : Array(UInt8)
      @pfbdata
    end

    # Returns the pfb data as stream.
    def to_io : IO::Memory
      IO::Memory.new(@pfbdata)
    end

    # Returns the size of the pfb-data.
    def size : Int32
      @pfbdata.size
    end

    # Returns the first segment
    def segment1 : Array(UInt8)
      @pfbdata[0, @lengths[0]]
    end

    # Returns the second segment
    def segment2 : Array(UInt8)
      start = @lengths[0]
      @pfbdata[start, @lengths[1]]
    end
  end
end

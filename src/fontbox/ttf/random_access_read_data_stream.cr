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
  # An implementation of the TTFDataStream using RandomAccessRead as source.
  # The underlying RandomAccessRead can be any length, but this implementation supports
  # only buffer lengths up to Int32::MAX.
  class RandomAccessReadDataStream < TTFDataStream
    @length : Int64
    @data : Bytes
    @current_position : Int32 = 0

    # Constructor.
    #
    # @param random_access_read source to be read from. Caller should close it.
    # @raise IO::Error If there is a problem reading the source data.
    def initialize(random_access_read : Pdfbox::IO::RandomAccessRead)
      @length = random_access_read.length
      if @length > Int32::MAX - 8 # https://www.baeldung.com/java-arrays-max-size
        # PDFBOX-5991
        raise IO::Error.new("Stream is too long, size: #{@length}")
      end
      @data = Bytes.new(@length.to_i32)
      remaining_bytes = @data.size
      total_read = 0
      while remaining_bytes > 0
        amount_read = random_access_read.read(@data[total_read, remaining_bytes])
        break if amount_read <= 0
        total_read += amount_read
        remaining_bytes -= amount_read
      end
    end

    # Constructor.
    #
    # @param input_stream source to be read from. Caller should close it.
    # @raise IO::Error If there is a problem reading the source data.
    def initialize(input_stream : IO)
      @data = input_stream.gets_to_end.to_slice
      @length = @data.size.to_i64
    end

    # Get the current position in the stream.
    # @return The current position in the stream.
    def current_position : Int64
      @current_position.to_i64
    end

    # Close the underlying resources.
    def close : Nil
      # nothing to do
    end

    # Read an unsigned byte.
    # @return An unsigned byte, or -1, signalling 'no more data'
    def read : Int32
      if @current_position >= @length
        return -1
      end
      byte = @data[@current_position]
      @current_position += 1
      byte.to_i32
    end

    # Read a signed 64-bit integer.
    #
    # @return eight bytes interpreted as a long.
    def read_long : Int64
      (read_int.to_i64 << 32) + (read_int.to_i64 & 0xFFFFFFFF_i64)
    end

    # Read a signed 32-bit integer.
    #
    # @return 4 bytes interpreted as an int.
    private def read_int : Int32
      b1 = read
      b2 = read
      b3 = read
      b4 = read
      (b1 << 24) + (b2 << 16) + (b3 << 8) + b4
    end

    # Seek into the datasource.
    # When the requested `pos` is < 0, an IO::Error is raised.
    # When the requested `pos` is >= `#length`, the `@current_position`
    # is set to the first byte *after* the `@data`!
    #
    # @param pos The position to seek to.
    # @raise IO::Error If there is an error seeking to that position.
    def seek(pos : Int64) : Nil
      if pos < 0
        raise IO::Error.new("Invalid position #{pos}")
      end
      @current_position = pos < @length ? pos.to_i32 : @length.to_i32
    end

    # Read bytes into buffer.
    #
    # @param b The buffer to write to.
    # @param off The offset into the buffer.
    # @param len The length into the buffer.
    # @return The number of bytes read or -1, signalling 'no more data'
    # @raise IO::Error If there is an error reading from the stream.
    def read(b : Bytes, off : Int32, len : Int32) : Int32
      if @current_position >= @length
        return -1
      end
      remaining_bytes = (@length - @current_position).to_i32
      bytes_to_read = Math.min(remaining_bytes, len)
      b[off, bytes_to_read].copy_from(@data[@current_position, bytes_to_read])
      @current_position += bytes_to_read
      bytes_to_read
    end

    # Creates a view from current position to `pos + length`.
    # It can be faster than `read(length)` if you only need a few bytes.
    # `SubView.close()` should never close `TTFDataStream.this`, only itself.
    #
    # @return A view or nil (caller can use `read` instead). Please close the result
    def create_sub_view(length : Int64) : Pdfbox::IO::RandomAccessRead?
      Pdfbox::IO::RandomAccessReadBuffer.new(@data).create_view(@current_position, length)
    end

    # This will get the original data file that was used for this stream.
    #
    # @return The data that was read from.
    def original_data : IO
      IO::Memory.new(@data)
    end

    # This will get the original data size that was used for this stream.
    #
    # @return The size of the original data.
    def original_data_size : Int64
      @length
    end
  end
end

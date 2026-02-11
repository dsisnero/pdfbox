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
  # An abstract class to read a data stream.
  #
  # Ported from Apache PDFBox TTFDataStream.
  abstract class TTFDataStream
    # Read a 16.16 fixed value, where the first 16 bits are the decimal and the last 16 bits are the fraction.
    #
    # @return A 32 bit value.
    def read_32_fixed : Float32
      retval = read_signed_short.to_f32
      retval + (read_unsigned_short / 65536.0_f32)
    end

    # Read a fixed length ascii string.
    #
    # @param length The length of the string to read.
    # @return A string of the desired length.
    def read_string(length : Int32) : String
      read_string(length, "ISO-8859-1")
    end

    # Read a fixed length string.
    #
    # @param length The length of the string to read in bytes.
    # @param charset The expected character set of the string.
    # @return A string of the desired length.
    def read_string(length : Int32, charset : String) : String
      String.new(read(length), charset)
    end

    # Read an unsigned byte.
    #
    # @return An unsigned byte, or -1 if end of stream.
    abstract def read : Int32

    # Read a signed 64-bit integer.
    #
    # @return eight bytes interpreted as a long.
    abstract def read_long : Int64

    # Read a signed byte.
    #
    # @return A signed byte.
    def read_signed_byte : Int32
      signed_byte = read
      signed_byte <= 127 ? signed_byte : signed_byte - 256
    end

    # Read an unsigned byte. Similar to {#read}, but throws an exception if EOF is unexpectedly reached.
    #
    # @return An unsigned byte.
    # @raise IO::EOFError If there is an error reading the data.
    def read_unsigned_byte : Int32
      unsigned_byte = read
      if unsigned_byte == -1
        raise IO::EOFError.new("premature EOF")
      end
      unsigned_byte
    end

    # Read an unsigned integer.
    #
    # @return An unsigned integer.
    # @raise IO::EOFError If there is an error reading the data.
    def read_unsigned_int : UInt64
      byte1 = read.to_i64
      byte2 = read.to_i64
      byte3 = read.to_i64
      byte4 = read.to_i64
      if byte4 < 0
        raise IO::EOFError.new("EOF at #{get_current_position}, b1: #{byte1}, b2: #{byte2}, b3: #{byte3}, b4: #{byte4}")
      end
      ((byte1 << 24) + (byte2 << 16) + (byte3 << 8) + byte4).to_u64
    end

    # Read an unsigned short.
    #
    # @return An unsigned short.
    # @raise IO::EOFError If there is an error reading the data.
    def read_unsigned_short : UInt32
      b1 = read
      b2 = read
      if (b1 | b2) < 0
        raise IO::EOFError.new("EOF at #{get_current_position}, b1: #{b1}, b2: #{b2}")
      end
      ((b1 << 8) + b2).to_u32
    end

    # Read an unsigned byte array.
    #
    # @param length the length of the array to be read
    # @return An unsigned byte array.
    # @raise IO::EOFError If there is an error reading the data.
    def read_unsigned_byte_array(length : Int32) : Array(Int32)
      Array.new(length) do
        read_unsigned_byte
      end
    end

    # Read an unsigned short array.
    #
    # @param length The length of the array to read.
    # @return An unsigned short array.
    # @raise IO::EOFError If there is an error reading the data.
    def read_unsigned_short_array(length : Int32) : Array(Int32)
      Array.new(length) do
        read_unsigned_short.to_i32
      end
    end

    # Read a signed short.
    #
    # @return A signed short.
    def read_signed_short : Int16
      read_unsigned_short.to_i16!
    end

    # Read an eight byte international date.
    #
    # @return A signed short.
    # @raise IO::EOFError If there is an error reading the data.
    def read_international_date : Time
      seconds_since_1904 = read_long.to_i64
      # 1904-01-01 00:00:00 UTC
      epoch_1904 = Time.utc(1904, 1, 1, 0, 0, 0)
      epoch_1904 + seconds_since_1904.seconds
    end

    # Reads a tag, an array of four uint8s used to identify a script, language system, feature,
    # or baseline.
    def read_tag : String
      String.new(read(4), "US-ASCII")
    end

    # Seek into the datasource.
    #
    # @param pos The position to seek to.
    # @raise IO::Error If there is an error seeking to that position.
    abstract def seek(pos : Int64) : Nil

    # Read a specific number of bytes from the stream.
    #
    # @param number_of_bytes The number of bytes to read.
    # @return The byte buffer.
    # @raise IO::Error If there is an error while reading.
    def read(number_of_bytes : Int32) : Bytes
      data = Bytes.new(number_of_bytes)
      amount_read = 0
      total_amount_read = 0
      # read at most number_of_bytes bytes from the stream.
      while total_amount_read < number_of_bytes &&
            (amount_read = read(data, total_amount_read, number_of_bytes - total_amount_read)) != -1
        total_amount_read += amount_read
      end
      if total_amount_read == number_of_bytes
        data
      else
        raise IO::Error.new("Unexpected end of TTF stream reached")
      end
    end

    # Read bytes into buffer.
    #
    # @param b The buffer to write to.
    # @param off The offset into the buffer.
    # @param len The length into the buffer.
    # @return The number of bytes read, or -1 at the end of the stream
    # @raise IO::Error If there is an error reading from the stream.
    abstract def read(b : Bytes, off : Int32, len : Int32) : Int32

    # Creates a view from current position to `pos + length`.
    # It can be faster than `read(length)` if you only need a few bytes.
    # `SubView.close()` should never close `TTFDataStream.this`, only itself.
    #
    # @return A view or nil (caller can use `read` instead). Please close the result
    def create_sub_view(length : Int64) : Pdfbox::IO::RandomAccessRead?
      nil
    end

    # Get the current position in the stream.
    #
    # @return The current position in the stream.
    # @raise IO::Error If an error occurs while reading the stream.
    # ameba:disable Naming/AccessorMethodName
    abstract def get_current_position : Int64

    # This will get the original data file that was used for this stream.
    #
    # @return The data that was read from.
    # @raise IO::Error If there is an issue reading the data.
    # ameba:disable Naming/AccessorMethodName
    abstract def get_original_data : IO

    # This will get the original data size that was used for this stream.
    #
    # @return The size of the original data.
    # ameba:disable Naming/AccessorMethodName
    abstract def get_original_data_size : Int64

    # Close the underlying resources.
    abstract def close : Nil
  end
end

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

require "../../pdfbox/io"

module Fontbox::CFF
  # This class implements the DataInput interface using a RandomAccessRead as source.
  #
  # Note: things can get hairy when the underlying buffer is larger than Int32::MAX.
  # Straight forward reading may work, but #position and #position= may have problems.
  class DataInputRandomAccessRead < DataInput
    @random_access_read : Pdfbox::IO::RandomAccessRead

    # Constructor.
    #
    # @param random_access_read the source to be read from
    def initialize(@random_access_read : Pdfbox::IO::RandomAccessRead)
    end

    private def remaining : Int64
      @random_access_read.length - @random_access_read.position
    end

    # Determines if there are any bytes left to read or not.
    #
    # @return true if there are any bytes left to read.
    def has_remaining? : Bool
      remaining > 0
    end

    # Returns the current position.
    #
    # @return current position.
    def position : Int32
      @random_access_read.position.to_i32
    end

    # Sets the current *absolute* position to the given value. You *cannot* use
    # `position = -20` to move 20 bytes back!
    #
    # @param position the given position, must be 0 <= position < length.
    # @raise Exception if the new position is out of range
    def position=(position : Int32) : Nil
      if position < 0
        raise "position is negative"
      end
      if position >= @random_access_read.length
        raise "New position is out of range #{position} >= #{@random_access_read.length}"
      end
      @random_access_read.seek(position.to_i64)
    end

    # Read one single byte from the buffer.
    #
    # @return the byte.
    # @raise Exception when there are no bytes to read
    def read_byte : Int8
      if !has_remaining?
        raise "End of buffer reached!"
      end
      byte = @random_access_read.read
      raise "Unexpected EOF" if byte.nil?
      byte.to_i8!
    end

    # Read one single unsigned byte from the buffer.
    #
    # @return the unsigned byte as int.
    # @raise Exception when there are no bytes to read
    def read_unsigned_byte : Int32
      if !has_remaining?
        raise "End of buffer reached!"
      end
      byte = @random_access_read.read
      raise "Unexpected EOF" if byte.nil?
      byte.to_i32
    end

    # Peeks one single unsigned byte from the buffer.
    #
    # @param offset offset to the byte to be peeked, must be 0 <= offset.
    # @return the unsigned byte as int.
    # @raise Exception when the offset is negative or beyond end_of_buffer
    def peek_unsigned_byte(offset : Int32) : Int32
      if offset < 0
        raise "offset is negative"
      end
      if offset == 0
        byte = @random_access_read.peek
        if byte.nil?
          raise "EOF"
        else
          return byte.to_i32
        end
      end
      current_position = @random_access_read.position
      if current_position + offset >= @random_access_read.length
        raise "Offset position is out of range #{current_position + offset} >= #{@random_access_read.length}"
      end
      @random_access_read.seek(current_position + offset)
      peek_value = @random_access_read.read
      @random_access_read.seek(current_position)
      raise "Unexpected EOF" if peek_value.nil?
      peek_value.to_i32
    end

    # Read a number of single byte values from the buffer.
    #
    # Note: when `read_bytes(5)` is called, but there are only 3 bytes available, the
    # caller gets an Exception, not the 3 bytes!
    #
    # @param length the number of bytes to be read, must be 0 <= length.
    # @return an array with containing the bytes from the buffer.
    # @raise Exception when there are less than `length` bytes available
    def read_bytes(length : Int32) : Bytes
      if length < 0
        raise "length is negative"
      end
      if remaining < length.to_i64
        raise "End of buffer reached! Requested #{length} bytes but only #{remaining} available"
      end
      bytes = Bytes.new(length)
      # read exactly length bytes (guaranteed by remaining check)
      read = @random_access_read.read(bytes)
      # Should never happen if remaining check is correct, but safeguard
      if read != length
        raise "Failed to read #{length} bytes, got #{read}"
      end
      bytes
    end

    def length : Int32
      @random_access_read.length.to_i32
    end
  end
end

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

module Fontbox::CFF
  # This class implements the DataInput interface using a byte buffer as source.
  class DataInputByteArray < DataInput
    @input_buffer : Bytes
    @buffer_position : Int32 = 0

    # Constructor.
    def initialize(buffer : Bytes)
      @input_buffer = buffer
    end

    # Determines if there are any bytes left to read or not.
    def has_remaining? : Bool
      @buffer_position < @input_buffer.size
    end

    # Returns the current position.
    def position : Int32
      @buffer_position
    end

    # Sets the current position to the given value.
    def position=(position : Int32) : Nil
      if position < 0
        raise Exception.new("position is negative")
      end
      if position >= @input_buffer.size
        raise Exception.new("New position is out of range #{position} >= #{@input_buffer.size}")
      end
      @buffer_position = position
    end

    # Read one single byte from the buffer.
    def read_byte : Int8
      unless has_remaining?
        raise Exception.new("End off buffer reached")
      end
      ptr = @input_buffer.to_unsafe.as(Int8*)
      byte = ptr[@buffer_position]
      @buffer_position += 1
      byte
    end

    # Read one single unsigned byte from the buffer.
    def read_unsigned_byte : Int32
      unless has_remaining?
        raise Exception.new("End off buffer reached")
      end
      byte = @input_buffer[@buffer_position].to_i32
      @buffer_position += 1
      byte
    end

    # Peeks one single unsigned byte from the buffer.
    def peek_unsigned_byte(offset : Int32) : Int32
      if offset < 0
        raise Exception.new("offset is negative")
      end
      if @buffer_position + offset >= @input_buffer.size
        raise Exception.new("Offset position is out of range #{@buffer_position + offset} >= #{@input_buffer.size}")
      end
      @input_buffer[@buffer_position + offset].to_i32
    end

    # Read a number of single byte values from the buffer.
    def read_bytes(length : Int32) : Bytes
      if length < 0
        raise Exception.new("length is negative")
      end
      if @input_buffer.size - @buffer_position < length
        raise Exception.new("Premature end of buffer reached")
      end
      bytes = @input_buffer[@buffer_position, length]
      @buffer_position += length
      bytes
    end

    def length : Int32
      @input_buffer.size
    end
  end
end

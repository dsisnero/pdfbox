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
  # This interface defines some functionality to read a CFF font.
  abstract class DataInput
    # Determines if there are any bytes left to read or not.
    abstract def has_remaining? : Bool

    # Returns the current position.
    abstract def position : Int32

    # Sets the current position to the given value.
    abstract def position=(position : Int32) : Nil

    # Read one single byte from the buffer.
    abstract def read_byte : Int8

    # Read one single unsigned byte from the buffer.
    abstract def read_unsigned_byte : Int32

    # Peeks one single unsigned byte from the buffer.
    abstract def peek_unsigned_byte(offset : Int32) : Int32

    # Read one single short value from the buffer.
    def read_short : Int16
      read_unsigned_short.to_i16!
    end

    # Read one single unsigned short (2 bytes) value from the buffer.
    def read_unsigned_short : Int32
      b1 = read_unsigned_byte
      b2 = read_unsigned_byte
      b1 << 8 | b2
    end

    # Read one single int (4 bytes) from the buffer.
    def read_int : Int32
      b1 = read_unsigned_byte
      b2 = read_unsigned_byte
      b3 = read_unsigned_byte
      b4 = read_unsigned_byte
      b1 << 24 | b2 << 16 | b3 << 8 | b4
    end

    # Read a number of single byte values from the buffer.
    abstract def read_bytes(length : Int32) : Bytes

    abstract def length : Int32

    # Read the offset from the buffer.
    def read_offset(off_size : Int32) : Int32
      value = 0
      off_size.times do
        value = value << 8 | read_unsigned_byte
      end
      value
    end
  end
end

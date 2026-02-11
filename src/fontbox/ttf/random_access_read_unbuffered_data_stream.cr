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
  # In contrast to RandomAccessReadDataStream,
  # this class doesn't pre-load RandomAccessRead into a byte[],
  # it works with RandomAccessRead directly.
  #
  # Performance: it is much faster if most of the buffer is skipped, and slower if whole buffer is read()
  #
  # Ported from Apache PDFBox RandomAccessReadUnbufferedDataStream.
  class RandomAccessReadUnbufferedDataStream < TTFDataStream
    @length : Int64
    @random_access_read : Pdfbox::IO::RandomAccessRead

    # @raise IO::Error If there is a problem reading the source length.
    def initialize(random_access_read : Pdfbox::IO::RandomAccessRead)
      @length = random_access_read.length
      @random_access_read = random_access_read
    end

    def get_current_position : Int64
      @random_access_read.position
    end

    # Close the underlying resources.
    def close : Nil
      @random_access_read.close
    end

    def read : Int32
      byte = @random_access_read.read
      byte.nil? ? -1 : byte.to_i32
    end

    def read_long : Int64
      ((read_int.to_i64 << 32) | (read_int.to_i64 & 0xFFFFFFFF_i64))
    end

    private def read_int : Int32
      b1 = read
      b2 = read
      b3 = read
      b4 = read
      (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
    end

    def seek(pos : Int64) : Nil
      @random_access_read.seek(pos)
    end

    def read(b : Bytes, off : Int32, len : Int32) : Int32
      @random_access_read.read(b[off, len])
    end

    # Lifetime of returned IO is bound by `this` lifetime, it won't close underlying `RandomAccessRead`.
    def get_original_data : IO
      view = @random_access_read.create_view(0, @length)
      IO::Memory.new(view.read_all)
    end

    def get_original_data_size : Int64
      @length
    end

    def create_sub_view(length : Int64) : Pdfbox::IO::RandomAccessRead?
      @random_access_read.create_view(get_current_position, length)
    end
  end
end

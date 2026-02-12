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
  # A wrapper for a TTF stream inside a TTC file, does not close the underlying shared stream.
  #
  # Ported from Apache PDFBox TTCDataStream.
  class TTCDataStream < TTFDataStream
    @stream : TTFDataStream

    def initialize(stream : TTFDataStream)
      @stream = stream
    end

    def read : Int32
      @stream.read
    end

    def read_long : Int64
      @stream.read_long
    end

    def close : Nil
      # don't close the underlying stream, as it is shared by all fonts from the same TTC
      # TrueTypeCollection.close() must be called instead
    end

    def seek(pos : Int64) : Nil
      @stream.seek(pos)
    end

    def read(b : Bytes, off : Int32, len : Int32) : Int32
      @stream.read(b, off, len)
    end

    def current_position : Int64
      @stream.current_position
    end

    def original_data : IO
      @stream.original_data
    end

    def original_data_size : Int64
      @stream.original_data_size
    end

    def create_sub_view(length : Int64) : Pdfbox::IO::RandomAccessRead?
      @stream.create_sub_view(length)
    end
  end
end

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
  # A table in a true type font.
  #
  # Ported from Apache PDFBox TTFTable.
  class TTFTable
    @tag : String
    @check_sum : Int64
    @offset : Int64
    @length : Int64
    @initialized : Bool = false

    # Constructor.
    def initialize
      @tag = ""
      @check_sum = 0_i64
      @offset = 0_i64
      @length = 0_i64
    end

    # Gets the check sum.
    def check_sum : Int64
      @check_sum
    end

    # Sets the check sum.
    def check_sum=(check_sum_value : Int64)
      @check_sum = check_sum_value
    end

    # Gets the length.
    def length : Int64
      @length
    end

    # Sets the length.
    def length=(length_value : Int64)
      @length = length_value
    end

    # Gets the offset.
    def offset : Int64
      @offset
    end

    # Sets the offset.
    def offset=(offset_value : Int64)
      @offset = offset_value
    end

    # Gets the tag.
    def tag : String
      @tag
    end

    # Sets the tag.
    def tag=(tag_value : String)
      @tag = tag_value
    end

    # Indicates if the table is already initialized.
    #
    # @return true if the table is initialized
    # ameba:disable Naming/AccessorMethodName
    def get_initialized : Bool
      @initialized
    end

    # This will read the required data from the stream.
    #
    # @param ttf The font that is being read.
    # @param data The stream to read the data from.
    def read(ttf : TrueTypeFont, data : TTFDataStream) : Nil
      # Default implementation does nothing
    end

    # This will read required headers from the stream into out_headers.
    #
    # @param ttf The font that is being read.
    # @param data The stream to read the data from.
    # @param out_headers The class to write the data to.
    def read_headers(ttf : TrueTypeFont, data : TTFDataStream, out_headers : FontHeaders) : Nil
      # Default implementation does nothing
    end
  end
end

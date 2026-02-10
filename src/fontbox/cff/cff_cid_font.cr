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
  # A CID-keyed font program represented in a CFF file.
  class CFFCIDFont < CFFFont
    @registry : String = ""
    @ordering : String = ""
    @supplement : Int32 = 0
    @font_dicts = Array(Hash(String, CFFDictValue?)).new
    @priv_dicts = Array(Hash(String, CFFPrivateDictValue?)).new
    @fd_select : FDSelect?

    def cid_font? : Bool
      true
    end

    # Registry getter/setter
    def registry : String
      @registry
    end

    protected def registry=(value : String)
      @registry = value
    end

    def ordering : String
      @ordering
    end

    protected def ordering=(value : String)
      @ordering = value
    end

    def supplement : Int32
      @supplement
    end

    protected def supplement=(value : Int32)
      @supplement = value
    end

    def font_dicts : Array(Hash(String, CFFDictValue?))
      @font_dicts
    end

    protected def font_dicts=(value : Array(Hash(String, CFFDictValue?)))
      @font_dicts = value
    end

    def priv_dicts : Array(Hash(String, CFFPrivateDictValue?))
      @priv_dicts
    end

    protected def priv_dicts=(value : Array(Hash(String, CFFPrivateDictValue?)))
      @priv_dicts = value
    end

    def fd_select : FDSelect?
      @fd_select
    end

    protected def fd_select=(value : FDSelect?)
      @fd_select = value
    end
  end

  # FDSelect interface
  abstract class FDSelect
    abstract def get_fd_index(gid : Int32) : Int32
  end

  # Format 0 FDSelect
  private class Format0FDSelect < FDSelect
    def initialize(@fds : Array(Int32))
    end

    def get_fd_index(gid : Int32) : Int32
      gid < @fds.size ? @fds[gid] : 0
    end
  end

  # Format 3 FDSelect Range3 structure
  private class Range3
    getter first : Int32
    getter fd : Int32

    def initialize(@first : Int32, @fd : Int32)
    end
  end

  # Format 3 FDSelect
  private class Format3FDSelect < FDSelect
    def initialize(@range3 : Array(Range3), @sentinel : Int32)
    end

    def get_fd_index(gid : Int32) : Int32
      @range3.each_with_index do |range, i|
        if range.first <= gid
          if i + 1 < @range3.size
            if @range3[i + 1].first > gid
              return range.fd
            end
            # go to next range
          else
            # last range reach, the sentinel must be greater than gid
            if @sentinel > gid
              return range.fd
            end
            return -1
          end
        end
      end
      0
    end
  end
end

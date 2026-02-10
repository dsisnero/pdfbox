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
    @font_dicts = Array(Hash(String, CFFDictValue)).new
    @priv_dicts = Array(Hash(String, CFFDictValue)).new
    @fd_select : FDSelect?

    def cid_font? : Bool
      true
    end

    # Registry getter/setter
    def registry : String
      @registry
    end

    def registry=(value : String)
      @registry = value
    end

    def ordering : String
      @ordering
    end

    def ordering=(value : String)
      @ordering = value
    end

    def supplement : Int32
      @supplement
    end

    def supplement=(value : Int32)
      @supplement = value
    end

    def font_dicts : Array(Hash(String, CFFDictValue))
      @font_dicts
    end

    def font_dicts=(value : Array(Hash(String, CFFDictValue)))
      @font_dicts = value
    end

    def priv_dicts : Array(Hash(String, CFFDictValue))
      @priv_dicts
    end

    def priv_dicts=(value : Array(Hash(String, CFFDictValue)))
      @priv_dicts = value
    end

    def fd_select : FDSelect?
      @fd_select
    end

    def fd_select=(value : FDSelect?)
      @fd_select = value
    end
  end

  # FDSelect interface (stub)
  abstract class FDSelect
    abstract def get_fd_index(gid : Int32) : Int32
  end
end

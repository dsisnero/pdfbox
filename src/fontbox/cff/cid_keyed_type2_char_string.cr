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
  # A CID-Keyed Type 2 CharString.
  class CIDKeyedType2CharString < Type2CharString
    @cid : Int32

    # Constructor.
    #
    # @param font Parent CFF font
    # @param font_name font name
    # @param cid CID
    # @param gid GID
    # @param sequence Type 2 char string sequence
    # @param default_width_x default width
    # @param nom_width_x nominal width
    def initialize(font : Type1CharStringReader, font_name : String, cid : Int32, gid : Int32,
                   sequence : Array(CharStringCommand | Int32 | Float64), default_width_x : Int32, nom_width_x : Int32)
      # glyph name is for debugging only
      glyph_name = "%04x" % cid
      super(font, font_name, glyph_name, gid, sequence, default_width_x, nom_width_x)
      @cid = cid
    end

    # Returns the CID (character id) of this charstring.
    #
    # @return the CID of this charstring
    def cid : Int32
      @cid
    end
  end
end

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
  # This class represents a CFF operator.
  # Port of org.apache.fontbox.cff.CFFOperator.
  class CFFOperator
    @@key_map : Hash(Int32, String)? = nil

    # Returns the operator name corresponding to the given one byte representation.
    def self.get_operator(b0 : Int32) : String?
      get_operator(b0, 0)
    end

    # Returns the operator name corresponding to the given two byte representation.
    def self.get_operator(b0 : Int32, b1 : Int32) : String?
      key_map[calculate_key(b0, b1)]?
    end

    private def self.calculate_key(b0 : Int32, b1 : Int32) : Int32
      (b1 << 8) + b0
    end

    private def self.register(map : Hash(Int32, String), b0 : Int32, name : String) : Nil
      register(map, b0, 0, name)
    end

    private def self.register(map : Hash(Int32, String), b0 : Int32, b1 : Int32, name : String) : Nil
      map[calculate_key(b0, b1)] = name
    end

    private def self.key_map : Hash(Int32, String)
      @@key_map ||= begin
        map = Hash(Int32, String).new

        # Top DICT
        register(map, 0, "version")
        register(map, 1, "Notice")
        register(map, 12, 0, "Copyright")
        register(map, 2, "FullName")
        register(map, 3, "FamilyName")
        register(map, 4, "Weight")
        register(map, 12, 1, "isFixedPitch")
        register(map, 12, 2, "ItalicAngle")
        register(map, 12, 3, "UnderlinePosition")
        register(map, 12, 4, "UnderlineThickness")
        register(map, 12, 5, "PaintType")
        register(map, 12, 6, "CharstringType")
        register(map, 12, 7, "FontMatrix")
        register(map, 13, "UniqueID")
        register(map, 5, "FontBBox")
        register(map, 12, 8, "StrokeWidth")
        register(map, 14, "XUID")
        register(map, 15, "charset")
        register(map, 16, "Encoding")
        register(map, 17, "CharStrings")
        register(map, 18, "Private")
        register(map, 12, 20, "SyntheticBase")
        register(map, 12, 21, "PostScript")
        register(map, 12, 22, "BaseFontName")
        register(map, 12, 23, "BaseFontBlend")
        register(map, 12, 30, "ROS")
        register(map, 12, 31, "CIDFontVersion")
        register(map, 12, 32, "CIDFontRevision")
        register(map, 12, 33, "CIDFontType")
        register(map, 12, 34, "CIDCount")
        register(map, 12, 35, "UIDBase")
        register(map, 12, 36, "FDArray")
        register(map, 12, 37, "FDSelect")
        register(map, 12, 38, "FontName")

        # Private DICT
        register(map, 6, "BlueValues")
        register(map, 7, "OtherBlues")
        register(map, 8, "FamilyBlues")
        register(map, 9, "FamilyOtherBlues")
        register(map, 12, 9, "BlueScale")
        register(map, 12, 10, "BlueShift")
        register(map, 12, 11, "BlueFuzz")
        register(map, 10, "StdHW")
        register(map, 11, "StdVW")
        register(map, 12, 12, "StemSnapH")
        register(map, 12, 13, "StemSnapV")
        register(map, 12, 14, "ForceBold")
        register(map, 12, 15, "LanguageGroup")
        register(map, 12, 16, "ExpansionFactor")
        register(map, 12, 17, "initialRandomSeed")
        register(map, 19, "Subrs")
        register(map, 20, "defaultWidthX")
        register(map, 21, "nominalWidthX")

        map
      end
    end
  end
end

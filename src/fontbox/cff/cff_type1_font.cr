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
  alias CFFPrivateDictValue = CFFDictValue | Array(Bytes)

  # A Type 1-equivalent font program represented in a CFF file. Thread safe.
  class CFFType1Font < CFFFont
    @private_dict = Hash(String, CFFPrivateDictValue).new
    @encoding : CFFEncoding?

    # Returns true if this is a CIDFont.
    def cid_font? : Bool
      false
    end

    # Returns the private dictionary.
    def private_dict : Hash(String, CFFPrivateDictValue)
      @private_dict
    end

    # Adds the given key/value pair to the private dictionary.
    protected def add_to_private_dict(name : String, value : CFFPrivateDictValue?) : Nil
      @private_dict[name] = value unless value.nil?
    end

    # Returns the CFFEncoding of the font.
    def encoding : CFFEncoding?
      @encoding
    end

    # Sets the CFFEncoding of the font.
    protected def encoding=(encoding : CFFEncoding) : Nil
      @encoding = encoding
    end
  end
end

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

require "../encoding/encoding"

module Fontbox::CFF
  # A CFF Type 1-equivalent Encoding. An encoding is an array of codes associated with some or all
  # glyphs in a font
  abstract class CFFEncoding < Fontbox::Encoding
    # Package-private constructor for subclasses.
    protected def initialize
      super
    end

    # Adds a new code/SID combination to the encoding.
    def add(code : Int32, sid : Int32, name : String) : Nil
      add_character_encoding(code, name)
    end

    # For use by subclasses only.
    protected def add(code : Int32, sid : Int32) : Nil
      add_character_encoding(code, StandardString.name(sid))
    end
  end
end

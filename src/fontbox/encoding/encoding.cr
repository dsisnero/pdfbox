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

module Fontbox
  # A PostScript Encoding vector.
  abstract class Encoding
    # This is a mapping from a character code to a character name.
    @code_to_name = Hash(Int32, String).new

    # This is a mapping from a character name to a character code.
    @name_to_code = Hash(String, Int32).new

    # This will add a character encoding.
    protected def add_character_encoding(code : Int32, name : String) : Nil
      @code_to_name[code] = name
      @name_to_code[name] = code
    end

    # This will get the character code for the name.
    def get_code(name : String) : Int32?
      @name_to_code[name]?
    end

    # This will take a character code and get the name from the code. This method will never return
    # nil.
    def get_name(code : Int32) : String
      @code_to_name[code]? || ".notdef"
    end

    # Returns an unmodifiable view of the code to name mapping.
    def code_to_name_map : Hash(Int32, String)
      @code_to_name.dup
    end
  end
end

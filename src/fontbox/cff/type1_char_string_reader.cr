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
  # Something which can read Type 1 CharStrings, namely Type 1 and CFF fonts.
  abstract class Type1CharStringReader
    # Returns the Type 1 CharString for the character with the given name.
    #
    # @param name the character name of the Type1 charstring
    # @return Type 1 CharString
    abstract def get_type1_char_string(name : String) : Type1CharString
  end
end

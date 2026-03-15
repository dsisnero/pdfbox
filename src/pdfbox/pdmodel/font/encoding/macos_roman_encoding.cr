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

require "./mac_roman_encoding"

module Pdfbox::Pdmodel::Font
  # This is the Mac OS Roman encoding, which is similar to the
  # MacRomanEncoding with the addition of 15 entries
  # Corresponds to org.apache.pdfbox.pdmodel.font.encoding.MacOSRomanEncoding in Apache PDFBox.
  class MacOSRomanEncoding < MacRomanEncoding
    # Singleton instance of this class.
    INSTANCE = new

    # Table of octal character codes and their corresponding names
    # on top of MacRomanEncoding.
    private MAC_OS_ROMAN_ENCODING_TABLE = [
      {0o255, "notequal"},
      {0o260, "infinity"},
      {0o262, "lessequal"},
      {0o263, "greaterequal"},
      {0o266, "partialdiff"},
      {0o267, "summation"},
      {0o270, "product"},
      {0o271, "pi"},
      {0o272, "integral"},
      {0o275, "Omega"},
      {0o303, "radical"},
      {0o305, "approxequal"},
      {0o306, "Delta"},
      {0o327, "lozenge"},
      {0o333, "Euro"},
      {0o360, "apple"},
    ]

    def initialize
      super
      MAC_OS_ROMAN_ENCODING_TABLE.each do |code, name|
        add(code, name)
      end
    end
  end
end

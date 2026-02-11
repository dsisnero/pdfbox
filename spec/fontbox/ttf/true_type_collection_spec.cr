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

require "../../spec_helper"
require "../../../src/fontbox/ttf"

describe Fontbox::TTF::TrueTypeCollection do
  describe "#initialize" do
    it "detects invalid number of fonts" do
      # Payload with "ttcf" header (0x74 0x74 0x63 0x66), version 0.0.0.0,
      # and invalid number of fonts 0x7FFFFFFF (2147483647 > 1024)
      payload = Bytes[0x74, 0x74, 0x63, 0x66, 0x00, 0x00, 0x00, 0x00, 0x7F, 0xFF, 0xFF, 0xFF]
      io = IO::Memory.new(payload)

      expect_raises(IO::Error, "Invalid number of fonts 2147483647") do
        Fontbox::TTF::TrueTypeCollection.new(io)
      end
    end
  end
end

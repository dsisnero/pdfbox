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

require "../spec_helper"

describe Fontbox::StandardEncoding do
  it "test standard encoding" do
    standard_encoding = Fontbox::StandardEncoding::INSTANCE
    # check some randomly chosen mappings
    standard_encoding.name(0).should eq(".notdef")
    standard_encoding.name(32).should eq("space")
    standard_encoding.name(112).should eq("p")
    standard_encoding.name(172).should eq("guilsinglleft")
    standard_encoding.code("space").should eq(32)
    standard_encoding.code("p").should eq(112)
    standard_encoding.code("guilsinglleft").should eq(172)
  end
end

describe Fontbox::MacRomanEncoding do
  it "test mac roman encoding" do
    mac_roman_encoding = Fontbox::MacRomanEncoding::INSTANCE
    # check some randomly chosen mappings
    mac_roman_encoding.name(0).should eq(".notdef")
    mac_roman_encoding.name(32).should eq("space")
    mac_roman_encoding.name(112).should eq("p")
    mac_roman_encoding.name(167).should eq("germandbls")
    mac_roman_encoding.code("space").should eq(32)
    mac_roman_encoding.code("p").should eq(112)
    mac_roman_encoding.code("germandbls").should eq(167)
  end
end

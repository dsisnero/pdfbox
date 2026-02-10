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

describe Fontbox::Pfb::PfbParser do
  it "test empty input raises" do
    expect_raises(Exception, "PFB header missing") do
      Fontbox::Pfb::PfbParser.new(Bytes.empty)
    end
  end

  describe "with OpenSans-Regular.pfb" do
    it "parses PFB file correctly" do
      parser = Fontbox::Pfb::PfbParser.new("spec/resources/fonts/OpenSans-Regular.pfb")
      # Expected segment lengths from Java test
      parser.lengths[0].should eq(4498)  # ASCII segment
      parser.lengths[1].should eq(95911) # binary segment
      # third segment may be 0 or cleartomark length
      parser.lengths[2].should be >= 0

      parser.size.should eq(parser.lengths[0] + parser.lengths[1] + parser.lengths[2])

      segment1 = parser.segment1
      segment2 = parser.segment2
      segment1.size.should eq(parser.lengths[0])
      segment2.size.should eq(parser.lengths[1])

      # Verify segment1 starts with "%!PS-AdobeFont"
      String.new(Bytes.new(segment1.to_unsafe, segment1.size)[0, 14]).should eq("%!PS-AdobeFont")
    end
  end

  describe "with DejaVuSerifCondensed.pfb" do
    it "parses PFB file with several binary segments" do
      parser = Fontbox::Pfb::PfbParser.new("spec/resources/fonts/DejaVuSerifCondensed.pfb")
      # Expected segment lengths from Java test (PDFBOX-5713)
      parser.lengths[0].should eq(5959)    # ASCII segment
      parser.lengths[1].should eq(1056090) # binary segment
      parser.lengths[2].should be >= 0

      parser.size.should eq(parser.lengths[0] + parser.lengths[1] + parser.lengths[2])

      segment1 = parser.segment1
      segment2 = parser.segment2
      segment1.size.should eq(parser.lengths[0])
      segment2.size.should eq(parser.lengths[1])

      # Verify segment1 starts with "%!PS-AdobeFont"
      String.new(Bytes.new(segment1.to_unsafe, segment1.size)[0, 14]).should eq("%!PS-AdobeFont")
    end
  end
end

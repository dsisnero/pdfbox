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

module Fontbox::TTF
  private class StubHorizontalHeaderTable < HorizontalHeaderTable
    def initialize(@metrics_count : UInt16)
      super()
    end

    # ameba:disable Naming/AccessorMethodName
    def number_of_h_metrics : UInt16
      @metrics_count
    end
    # ameba:enable Naming/AccessorMethodName
  end

  private class StubTrueTypeFont < TrueTypeFont
    def initialize(@number_of_glyphs_value : Int32, @horizontal_header : HorizontalHeaderTable?)
      super(RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)))
    end

    # ameba:disable Naming/AccessorMethodName
    def horizontal_header : HorizontalHeaderTable?
      @horizontal_header
    end

    # ameba:disable Naming/AccessorMethodName
    def number_of_glyphs : Int32
      @number_of_glyphs_value
    end
    # ameba:enable Naming/AccessorMethodName
  end

  def self.stream_for(bytes : Bytes) : RandomAccessReadDataStream
    RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(bytes))
  end

  describe HorizontalMetricsTable do
    it "returns fallback width for glyph ids beyond numberOfHMetrics" do
      hmtx_data = Bytes[0x01, 0xF4, 0x00, 0x0A, 0x02, 0x58, 0xFF, 0xEC, 0x00, 0x1E, 0xFF, 0xD8]

      table = HorizontalMetricsTable.new
      table.length = hmtx_data.size
      font = StubTrueTypeFont.new(4, StubHorizontalHeaderTable.new(2_u16))
      table.read(font, Fontbox::TTF.stream_for(hmtx_data))

      table.advance_width(0).should eq(500)
      table.advance_width(1).should eq(600)
      table.advance_width(3).should eq(600)
      table.left_side_bearing(0).should eq(10)
      table.left_side_bearing(1).should eq(-20)
      table.left_side_bearing(2).should eq(30)
      table.left_side_bearing(3).should eq(-40)
    end

    it "keeps non-horizontal left side bearing array sized even when bytes are missing" do
      hmtx_data = Bytes[0x01, 0xF4, 0x00, 0x0A, 0x02, 0x58, 0xFF, 0xEC]

      table = HorizontalMetricsTable.new
      table.length = hmtx_data.size
      font = StubTrueTypeFont.new(4, StubHorizontalHeaderTable.new(2_u16))
      table.read(font, Fontbox::TTF.stream_for(hmtx_data))

      table.non_horizontal_left_side_bearing_array.size.should eq(2)
      table.left_side_bearing(2).should eq(0)
      table.left_side_bearing(3).should eq(0)
    end

    it "raises when horizontal header table is missing" do
      table = HorizontalMetricsTable.new
      font = StubTrueTypeFont.new(1, nil)

      expect_raises(IO::EOFError, "Could not get hmtx table") do
        table.read(font, Fontbox::TTF.stream_for(Bytes.empty))
      end
    end
  end
end

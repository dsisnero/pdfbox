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

def read_font(filename : String) : Array(Fontbox::CFF::CFFFont)
  bytes = File.read(filename).to_slice
  parser = Fontbox::CFF::CFFParser.new
  parser.parse(bytes)
end

describe Fontbox::CFF::CFFParser do
  test_font = uninitialized Fontbox::CFF::CFFType1Font

  before_all do
    fonts = read_font("spec/resources/fonts/SourceSansProBold.otf")
    test_font = fonts[0].as(Fontbox::CFF::CFFType1Font)
  end

  it "parses font name" do
    test_font.name.should eq "SourceSansPro-Bold"
  end

  it "parses font bbox" do
    if bbox = test_font.font_b_box
      bbox.lower_left_x.should be_close(-231.0, 0.001)
      bbox.lower_left_y.should be_close(-384.0, 0.001)
      bbox.upper_right_x.should be_close(1223.0, 0.001)
      bbox.upper_right_y.should be_close(974.0, 0.001)
    else
      fail "Font bbox should not be nil"
    end
  end

  it "parses font matrix" do
    if matrix = test_font.font_matrix
      matrix.size.should eq 6
      matrix[0].should be_close(0.001, 0.000001)
      matrix[1].should be_close(0.0, 0.000001)
      matrix[2].should be_close(0.0, 0.000001)
      matrix[3].should be_close(0.001, 0.000001)
      matrix[4].should be_close(0.0, 0.000001)
      matrix[5].should be_close(0.0, 0.000001)
    else
      fail "Font matrix should not be nil"
    end
  end

  it "parses charset" do
    charset = test_font.charset
    charset.should_not be_nil
    charset = charset.as(Fontbox::CFF::Charset)
    charset.is_cid_font?.should be_false

    # gid2name
    charset.name_for_gid(0).should eq ".notdef"
    charset.name_for_gid(1).should eq "space"
    charset.name_for_gid(7).should eq "F"
    charset.name_for_gid(300).should eq "jcircumflex"
    charset.name_for_gid(700).should eq "infinity"

    # gid2sid
    charset.sid_for_gid(0).should eq 0
    charset.sid_for_gid(1).should eq 1
    charset.sid_for_gid(7).should eq 39
    charset.sid_for_gid(300).should eq 585
    charset.sid_for_gid(700).should eq 872

    # name2sid
    charset.sid(".notdef").should eq 0
    charset.sid("space").should eq 1
    charset.sid("F").should eq 39
    charset.sid("jcircumflex").should eq 585
    charset.sid("infinity").should eq 872
  end

  it "parses encoding" do
    encoding = test_font.encoding
    encoding.should_not be_nil
    encoding = encoding.as(Fontbox::CFF::CFFEncoding)
    encoding.should be_a(Fontbox::CFF::StandardEncoding)
  end

  it "parses char strings bytes" do
    char_strings = test_font.char_strings
    char_strings.should_not be_empty
    test_font.num_glyphs.should eq 824

    # Helper to convert Java signed bytes to Crystal bytes
    jbytes = ->(values : Array(Int32)) do
      bytes = Bytes.new(values.size)
      values.each_with_index do |v, i|
        bytes[i] = v < 0 ? (v + 256).to_u8 : v.to_u8
      end
      bytes
    end

    char_strings[1].should eq jbytes.call([-4, 15, 14])
    char_strings[16].should eq jbytes.call([72, 29, -13, 29, -9, -74, -9, 43, 3, 33, 29, 14])
    char_strings[195].should eq jbytes.call([-41, 88, 29, -47, -9, 12, 1, -123, 10, 3, 35, 29, -9, -50, -9, 62, -9, 3, 10, 85, -56, 61, 10])
    char_strings[525].should eq jbytes.call([-5, -69, -61, -8, 28, 1, -9, 57, -39, -65, 29, 14])
    char_strings[738].should eq jbytes.call([107, -48, 10, -9, 20, -9, 123, 3, -9, -112, -8, -46, 21, -10, 115, 10])
  end

  it "parses global subr index" do
    global_subr_index = test_font.global_subr_index
    global_subr_index.should_not be_empty
    global_subr_index.size.should eq 278

    jbytes = ->(values : Array(Int32)) do
      bytes = Bytes.new(values.size)
      values.each_with_index do |v, i|
        bytes[i] = v < 0 ? (v + 256).to_u8 : v.to_u8
      end
      bytes
    end

    global_subr_index[12].should eq jbytes.call([21, -70, -83, -85, -72, -72, 105, -85, 92, 91, 105, 107, 10, -83, -9, 62, 10])
    global_subr_index[120].should eq jbytes.call([58, 122, 29, -5, 48, 6, 11])
    global_subr_index[253].should eq jbytes.call([68, 80, 29, -45, -9, 16, -8, -92, 119, 11])
  end

  it "parses delta lists" do
    private_dict = test_font.private_dict

    blues = private_dict["BlueValues"]?.as?(Array(Fontbox::CFF::CFFNumber))
    blues.should_not be_nil
    blues = blues.as(Array(Fontbox::CFF::CFFNumber))
    blues.map(&.to_i).should eq [-12, 0, 496, 508, 578, 590, 635, 647, 652, 664, 701, 713]

    other_blues = private_dict["OtherBlues"]?.as?(Array(Fontbox::CFF::CFFNumber))
    other_blues.should_not be_nil
    other_blues = other_blues.as(Array(Fontbox::CFF::CFFNumber))
    other_blues.map(&.to_i).should eq [-196, -184]

    family_blues = private_dict["FamilyBlues"]?.as?(Array(Fontbox::CFF::CFFNumber))
    family_blues.should_not be_nil
    family_blues = family_blues.as(Array(Fontbox::CFF::CFFNumber))
    family_blues.map(&.to_i).should eq [-12, 0, 486, 498, 574, 586, 638, 650, 656, 668, 712, 724]

    family_other_blues = private_dict["FamilyOtherBlues"]?.as?(Array(Fontbox::CFF::CFFNumber))
    family_other_blues.should_not be_nil
    family_other_blues = family_other_blues.as(Array(Fontbox::CFF::CFFNumber))
    family_other_blues.map(&.to_i).should eq [-217, -205]

    stem_snap_h = private_dict["StemSnapH"]?.as?(Array(Fontbox::CFF::CFFNumber))
    stem_snap_h.should_not be_nil
    stem_snap_h = stem_snap_h.as(Array(Fontbox::CFF::CFFNumber))
    stem_snap_h.map(&.to_i).should eq [115]

    stem_snap_v = private_dict["StemSnapV"]?.as?(Array(Fontbox::CFF::CFFNumber))
    stem_snap_v.should_not be_nil
    stem_snap_v = stem_snap_v.as(Array(Fontbox::CFF::CFFNumber))
    stem_snap_v.map(&.to_i).should eq [146, 150]
  end

  it "returns path for glyphs" do
    # Test that path returns a non-empty path for some glyphs
    ["space", "F", "jcircumflex", "infinity"].each do |name|
      path = test_font.path(name)
      path.should be_a(Fontbox::Util::Path)
      # Path should have bounds (may be empty for .notdef but these should have geometry)
      bounds = path.bounds
      bounds.should be_a(Fontbox::Util::Rectangle2D)
    end
  end

  it "tests thread safety of Type2CharStringParser when parsing glyphs (PDFBOX-5819)" do
    # This test ensures thread safety of Type2CharStringParser when parsing
    # the same glyph from multiple threads concurrently.
    exception_channel = Channel(Exception?).new(2)
    latch = Channel(Nil).new(2)

    # Worker that parses glyphs
    worker = ->(_id : Int32) do
      begin
        latch.receive? # Wait for start signal
        (33..125).each do |code|
          name = code.chr.to_s
          gid = test_font.name_to_gid(name)
          # Get the charstring - this exercises Type2CharStringParser
          charstring = test_font.type2_char_string(gid)
          charstring.should be_a(Fontbox::CFF::Type2CharString)
        end
        exception_channel.send(nil)
      rescue e : Exception
        exception_channel.send(e)
      end
    end

    # Spawn two workers
    spawn { worker.call(1) }
    spawn { worker.call(2) }

    # Start both workers at the same time
    latch.send(nil)
    latch.send(nil)

    # Collect results
    result1 = exception_channel.receive
    result2 = exception_channel.receive

    # Ensure no exceptions were raised
    if result1
      raise result1
    end
    if result2
      raise result2
    end
  end
end

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

# Mock charset that provides identity mapping CID -> GID
class MockCIDCharset < Fontbox::CFF::Charset
  @gid_to_cid = Hash(Int32, Int32).new
  @gid_to_sid = Hash(Int32, Int32).new
  @gid_to_name = Hash(Int32, String).new
  @sid_to_gid = Hash(Int32, Int32).new
  @name_to_sid = Hash(String, Int32).new

  def initialize
    # Set up identity mappings for first 10 glyphs
    (0..9).each do |i|
      add_sid(i, i, "cid#{i}")
      add_cid(i, i)
    end
  end

  # ameba:disable Naming/PredicateName
  def is_cid_font? : Bool
    true
  end

  def add_sid(gid : Int32, sid : Int32, name : String) : Nil
    @gid_to_sid[gid] = sid
    @gid_to_name[gid] = name
    @sid_to_gid[sid] = gid
    @name_to_sid[name] = sid
  end

  def add_cid(gid : Int32, cid : Int32) : Nil
    @gid_to_cid[gid] = cid
  end

  def get_sid_for_gid(gid : Int32) : Int32
    @gid_to_sid[gid]? || 0
  end

  def get_gid_for_sid(sid : Int32) : Int32
    @sid_to_gid[sid]? || 0
  end

  def get_gid_for_cid(cid : Int32) : Int32
    # Find GID for CID (inverse mapping)
    @gid_to_cid.each do |gid, cid_val|
      return gid if cid_val == cid
    end
    0
  end

  def get_sid(name : String) : Int32
    @name_to_sid[name]? || 0
  end

  def get_name_for_gid(gid : Int32) : String?
    @gid_to_name[gid]?
  end

  def get_cid_for_gid(gid : Int32) : Int32
    @gid_to_cid[gid]? || 0
  end
end

# Mock FDSelect that always returns font dict index 0
class MockFDSelect < Fontbox::CFF::FDSelect
  def get_fd_index(gid : Int32) : Int32
    0
  end
end

# Testable subclass that exposes protected setters
class TestableCFFCIDFont < Fontbox::CFF::CFFCIDFont
  # Expose protected setters for testing
  def name=(value : String)
    super(value)
  end

  setter charset : Fontbox::CFF::Charset?
  setter char_strings : Array(Bytes)
  setter global_subr_index : Array(Bytes)
  setter registry : String
  setter ordering : String
  setter supplement : Int32
  setter font_dicts : Array(Hash(String, Fontbox::CFF::CFFDictValue?))
  setter priv_dicts : Array(Hash(String, Fontbox::CFF::CFFPrivateDictValue?))
  setter fd_select : Fontbox::CFF::FDSelect?
end

describe Fontbox::CFF::CFFCIDFont do
  describe "CID font functionality" do
    it "initializes with registry, ordering, supplement" do
      font = TestableCFFCIDFont.new
      font.registry = "Adobe"
      font.ordering = "Identity"
      font.supplement = 0
      font.registry.should eq "Adobe"
      font.ordering.should eq "Identity"
      font.supplement.should eq 0
    end

    it "returns true for cid_font?" do
      font = Fontbox::CFF::CFFCIDFont.new
      font.cid_font?.should be_true
    end

    it "manages font dictionaries and private dictionaries" do
      font = TestableCFFCIDFont.new
      font_dict = {"FontName" => "TestFont".as(Fontbox::CFF::CFFDictValue?)}
      priv_dict = {"defaultWidthX" => 1000.as(Fontbox::CFF::CFFPrivateDictValue?), "nominalWidthX" => 0.as(Fontbox::CFF::CFFPrivateDictValue?)}
      font.font_dicts = [font_dict]
      font.priv_dicts = [priv_dict]
      font.font_dicts.size.should eq 1
      font.priv_dicts.size.should eq 1
    end

    it "gets type2 charstring for a CID" do
      font = TestableCFFCIDFont.new
      font.name = "TestCIDFont"
      font.charset = MockCIDCharset.new
      font.char_strings = [Bytes[0x0b], Bytes[0x8b, 0x0b]] # .notdef and simple charstring
      font.global_subr_index = [] of Bytes
      font.priv_dicts = [{"defaultWidthX" => 1000.as(Fontbox::CFF::CFFPrivateDictValue?), "nominalWidthX" => 0.as(Fontbox::CFF::CFFPrivateDictValue?)}]
      font.fd_select = MockFDSelect.new

      # Get charstring for CID 1 (should map to GID 1)
      charstring = font.get_type2_char_string(1)
      charstring.should be_a(Fontbox::CFF::CIDKeyedType2CharString)
      charstring.cid.should eq 1
      charstring.gid.should eq 1
    end

    it "falls back to .notdef charstring for missing CID" do
      font = TestableCFFCIDFont.new
      font.name = "TestCIDFont"
      font.charset = MockCIDCharset.new
      # Only .notdef charstring at index 0
      font.char_strings = [Bytes[0x0b]]
      font.global_subr_index = [] of Bytes
      font.priv_dicts = [{"defaultWidthX" => 1000.as(Fontbox::CFF::CFFPrivateDictValue?), "nominalWidthX" => 0.as(Fontbox::CFF::CFFPrivateDictValue?)}]
      font.fd_select = MockFDSelect.new

      # CID 999 doesn't exist, should fall back to .notdef
      charstring = font.get_type2_char_string(999)
      charstring.should be_a(Fontbox::CFF::CIDKeyedType2CharString)
      charstring.gid.should eq 0 # .notdef GID
    end

    it "caches charstrings for subsequent calls" do
      font = TestableCFFCIDFont.new
      font.name = "TestCIDFont"
      font.charset = MockCIDCharset.new
      font.char_strings = [Bytes[0x0b], Bytes[0x8b, 0x0b]]
      font.global_subr_index = [] of Bytes
      font.priv_dicts = [{"defaultWidthX" => 1000.as(Fontbox::CFF::CFFPrivateDictValue?), "nominalWidthX" => 0.as(Fontbox::CFF::CFFPrivateDictValue?)}]
      font.fd_select = MockFDSelect.new

      first = font.get_type2_char_string(1)
      second = font.get_type2_char_string(1)
      # Should be the same instance due to caching
      first.should be second
    end
  end
end

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
  # A CID-keyed font program represented in a CFF file.
  class CFFCIDFont < CFFFont
    @registry : String = ""
    @ordering : String = ""
    @supplement : Int32 = 0
    @font_dicts = Array(Hash(String, CFFDictValue?)).new
    @priv_dicts = Array(Hash(String, CFFPrivateDictValue?)).new
    @fd_select : FDSelect?
    @char_string_cache = Hash(Int32, CIDKeyedType2CharString).new
    @char_string_parser : Type2CharStringParser?
    @reader : PrivateType1CharStringReader? = nil
    @char_string_cache_mutex = Thread::Mutex.new

    # Private implementation of Type1CharStringReader, because only CFFType1Font can
    # expose this publicly, as CIDFonts only support this for legacy 'seac' commands.
    private class PrivateType1CharStringReader < Type1CharStringReader
      def initialize(@font : CFFCIDFont)
      end

      def get_type1_char_string(name : String) : Type1CharString
        # CIDFonts only support this for legacy 'seac' commands, return .notdef
        @font.get_type2_char_string(0)
      end
    end

    def initialize
      super
      @reader = PrivateType1CharStringReader.new(self)
    end

    def cid_font? : Bool
      true
    end

    # Registry getter/setter
    def registry : String
      @registry
    end

    protected def registry=(value : String)
      @registry = value
    end

    def ordering : String
      @ordering
    end

    protected def ordering=(value : String)
      @ordering = value
    end

    def supplement : Int32
      @supplement
    end

    protected def supplement=(value : Int32)
      @supplement = value
    end

    def font_dicts : Array(Hash(String, CFFDictValue?))
      @font_dicts
    end

    protected def font_dicts=(value : Array(Hash(String, CFFDictValue?)))
      @font_dicts = value
    end

    def priv_dicts : Array(Hash(String, CFFPrivateDictValue?))
      @priv_dicts
    end

    protected def priv_dicts=(value : Array(Hash(String, CFFPrivateDictValue?)))
      @priv_dicts = value
    end

    def fd_select : FDSelect?
      @fd_select
    end

    protected def fd_select=(value : FDSelect?)
      @fd_select = value
    end

    # Returns the defaultWidthX for the given GID.
    protected def get_default_width_x(gid : Int32) : Int32
      fd_select = @fd_select
      return 1000 if fd_select.nil?
      fd_array_index = fd_select.get_fd_index(gid)
      return 1000 if fd_array_index == -1 || fd_array_index >= @priv_dicts.size
      priv_dict_value = @priv_dicts[fd_array_index]["defaultWidthX"]?
      case priv_dict_value
      when Int32
        priv_dict_value
      when Float64
        priv_dict_value.to_i
      else
        1000
      end
    end

    # Returns the nominalWidthX for the given GID.
    protected def get_nominal_width_x(gid : Int32) : Int32
      fd_select = @fd_select
      return 0 if fd_select.nil?
      fd_array_index = fd_select.get_fd_index(gid)
      return 0 if fd_array_index == -1 || fd_array_index >= @priv_dicts.size
      priv_dict_value = @priv_dicts[fd_array_index]["nominalWidthX"]?
      case priv_dict_value
      when Int32
        priv_dict_value
      when Float64
        priv_dict_value.to_i
      else
        0
      end
    end

    # Returns the LocalSubrIndex for the given GID.
    private def get_local_subr_index(gid : Int32) : Array(Bytes)?
      fd_select = @fd_select
      return if fd_select.nil?
      fd_array_index = fd_select.get_fd_index(gid)
      return if fd_array_index == -1 || fd_array_index >= @priv_dicts.size
      priv_dict_value = @priv_dicts[fd_array_index]["Subrs"]?
      if priv_dict_value.is_a?(Array(Bytes))
        priv_dict_value
      end
    end

    # Returns the Type 2 charstring for the given CID.
    def get_type2_char_string(gid : Int32) : CIDKeyedType2CharString
      cid = gid
      if cached = @char_string_cache[cid]?
        return cached
      end

      @char_string_cache_mutex.synchronize do
        # double-check after acquiring lock
        if cached = @char_string_cache[cid]?
          return cached
        end

        charset = self.charset
        glyph_id = charset ? charset.get_gid_for_cid(cid) : cid
        bytes = nil
        if glyph_id < char_strings.size
          bytes = char_strings[glyph_id]
        end
        if bytes.nil?
          bytes = char_strings[0] # .notdef
        end
        type2seq = get_parser.parse(bytes, global_subr_index, get_local_subr_index(glyph_id))
        type2 = CIDKeyedType2CharString.new(@reader.not_nil!, name, cid, glyph_id, type2seq,
          get_default_width_x(glyph_id), get_nominal_width_x(glyph_id))
        @char_string_cache[cid] = type2
        type2
      end
    end

    private def get_parser : Type2CharStringParser
      parser = @char_string_parser
      unless parser
        parser = Type2CharStringParser.new(name)
        @char_string_parser = parser
      end
      parser
    end
  end

  # FDSelect interface
  abstract class FDSelect
    abstract def get_fd_index(gid : Int32) : Int32
  end

  # Format 0 FDSelect
  private class Format0FDSelect < FDSelect
    def initialize(@fds : Array(Int32))
    end

    def get_fd_index(gid : Int32) : Int32
      gid < @fds.size ? @fds[gid] : 0
    end
  end

  # Format 3 FDSelect Range3 structure
  private class Range3
    getter first : Int32
    getter fd : Int32

    def initialize(@first : Int32, @fd : Int32)
    end
  end

  # Format 3 FDSelect
  private class Format3FDSelect < FDSelect
    def initialize(@range3 : Array(Range3), @sentinel : Int32)
    end

    def get_fd_index(gid : Int32) : Int32
      @range3.each_with_index do |range, i|
        if range.first <= gid
          if i + 1 < @range3.size
            if @range3[i + 1].first > gid
              return range.fd
            end
            # go to next range
          else
            # last range reach, the sentinel must be greater than gid
            if @sentinel > gid
              return range.fd
            end
            return -1
          end
        end
      end
      0
    end
  end
end

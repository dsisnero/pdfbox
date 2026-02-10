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
  alias CFFPrivateDictValue = CFFDictValue | Array(Bytes)

  # A Type 1-equivalent font program represented in a CFF file. Thread safe.
  class CFFType1Font < CFFFont
    @private_dict = Hash(String, CFFPrivateDictValue).new
    @encoding : CFFEncoding?
    @char_string_cache = Hash(Int32, Type2CharString).new
    @char_string_parser : Type2CharStringParser?
    @default_width_x : Int32?
    @nominal_width_x : Int32?
    @local_subr_index : Array(Bytes)?
    @reader : PrivateType1CharStringReader? = nil
    @char_string_cache_mutex = Thread::Mutex.new

    def initialize
      super
      @reader = PrivateType1CharStringReader.new(self)
    end

    # Private implementation of Type1CharStringReader, because only CFFType1Font can
    # expose this publicly, as CIDFonts only support this for legacy 'seac' commands.
    private class PrivateType1CharStringReader < Type1CharStringReader
      def initialize(@font : CFFType1Font)
      end

      def get_type1_char_string(name : String) : Type1CharString
        @font.get_type1_char_string(name)
      end
    end

    # Returns true if this is a CIDFont.
    def cid_font? : Bool
      false
    end

    # Returns the private dictionary.
    def private_dict : Hash(String, CFFPrivateDictValue)
      @private_dict
    end

    # Adds the given key/value pair to the private dictionary.
    protected def add_to_private_dict(name : String, value : CFFPrivateDictValue?) : Nil
      @private_dict[name] = value unless value.nil?
    end

    # Returns the CFFEncoding of the font.
    def encoding : CFFEncoding?
      @encoding
    end

    # Sets the CFFEncoding of the font.
    protected def encoding=(encoding : CFFEncoding) : Nil
      @encoding = encoding
    end

    # Returns the GID for the given PostScript glyph name.
    def name_to_gid(name : String) : Int32
      charset = self.charset
      return 0 unless charset
      sid = charset.get_sid(name)
      charset.get_gid_for_sid(sid)
    end

    # Returns the Type 1 charstring for the given PostScript glyph name.
    def get_type1_char_string(name : String) : Type1CharString
      gid = name_to_gid(name)
      get_type2_char_string(gid, name)
    end

    # Returns the path of the glyph for the given PostScript glyph name.
    def get_path(name : String) : Fontbox::Util::Path
      get_type1_char_string(name).path
    end

    # Returns the Type 2 charstring for the given GID.
    def get_type2_char_string(gid : Int32) : Type2CharString
      get_type2_char_string(gid, "GID+" + gid.to_s)
    end

    private def get_type2_char_string(gid : Int32, name : String) : Type2CharString
      if cached = @char_string_cache[gid]?
        return cached
      end

      @char_string_cache_mutex.synchronize do
        # double-check after acquiring lock
        if cached = @char_string_cache[gid]?
          return cached
        end

        bytes = nil
        if gid < char_strings.size
          bytes = char_strings[gid]
        end
        if bytes.nil?
          bytes = char_strings[0] # .notdef
        end
        type2seq = get_parser.parse(bytes, global_subr_index, get_local_subr_index)
        type2 = Type2CharString.new(@reader.not_nil!, self.name, name, gid, type2seq, get_default_width_x, get_nominal_width_x)
        @char_string_cache[gid] = type2
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

    private def get_local_subr_index : Array(Bytes)?
      local_subr = @local_subr_index
      unless local_subr
        subrs = @private_dict["Subrs"]?
        if subrs.is_a?(Array(Bytes))
          local_subr = subrs
          @local_subr_index = local_subr
        end
      end
      local_subr
    end

    # helper for looking up keys/values
    private def get_property(name : String) : CFFDictValue | CFFPrivateDictValue | Nil
      top_dict_value = top_dict[name]?
      return top_dict_value unless top_dict_value.nil?
      @private_dict[name]?
    end

    private def get_default_width_x : Int32
      width = @default_width_x
      unless width
        num = get_property("defaultWidthX")
        case num
        when Int32
          width = num
        when Float64
          width = num.to_i
        else
          width = 1000
        end
        @default_width_x = width
      end
      width
    end

    private def get_nominal_width_x : Int32
      width = @nominal_width_x
      unless width
        num = get_property("nominalWidthX")
        case num
        when Int32
          width = num
        when Float64
          width = num.to_i
        else
          width = 0
        end
        @nominal_width_x = width
      end
      width
    end
  end
end

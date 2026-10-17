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
  alias CFFNumber = Int32 | Float64
  alias CFFDictValue = String | CFFNumber | Bool | Array(CFFNumber)

  # An Adobe Compact Font Format (CFF) font. Thread safe.
  abstract class CFFFont
    @font_name : String = ""
    @charset : Charset?
    @source : CFFParser::ByteSource?
    @top_dict = Hash(String, CFFDictValue).new
    @char_strings : Array(Bytes) = [] of Bytes
    @global_subr_index : Array(Bytes) = [] of Bytes

    # The name of the font.
    def name : String
      @font_name
    end

    # Sets the name of the font.
    protected def name=(name : String) : Nil
      @font_name = name
    end

    # Adds the given key/value pair to the top dictionary.
    def add_value_to_top_dict(name : String, value : CFFDictValue?) : Nil
      @top_dict[name] = value unless value.nil?
    end

    # Returns the top dictionary.
    def top_dict : Hash(String, CFFDictValue)
      @top_dict
    end

    # Returns the FontMatrix.
    def font_matrix : Array(CFFNumber)?
      @top_dict["FontMatrix"]?.as?(Array(CFFNumber))
    end

    # Returns the FontBBox.
    def font_b_box : Util::BoundingBox?
      bbox_array = @top_dict["FontBBox"]?.as?(Array(CFFNumber))
      return unless bbox_array && bbox_array.size == 4

      llx = bbox_array[0]
      lly = bbox_array[1]
      urx = bbox_array[2]
      ury = bbox_array[3]

      llx_f = llx.is_a?(Int32) ? llx.to_f32 : llx.as(Float64).to_f32
      lly_f = lly.is_a?(Int32) ? lly.to_f32 : lly.as(Float64).to_f32
      urx_f = urx.is_a?(Int32) ? urx.to_f32 : urx.as(Float64).to_f32
      ury_f = ury.is_a?(Int32) ? ury.to_f32 : ury.as(Float64).to_f32

      Util::BoundingBox.new(llx_f, lly_f, urx_f, ury_f)
    end

    # Sets the charset.
    protected def charset=(charset : Charset) : Nil
      @charset = charset
    end

    # Returns the charset.
    def charset : Charset?
      @charset
    end

    # Sets the source.
    protected def source=(source : CFFParser::ByteSource) : Nil
      @source = source
    end

    # Returns the source.
    def source : CFFParser::ByteSource?
      @source
    end

    # Returns the raw CFF data (Java CFFFont#getData).
    def data : Bytes
      source = @source
      raise "CFF source is not set" unless source
      source.bytes
    end

    # Sets the global subroutine index.
    protected def global_subr_index=(global_subr_index : Array(Bytes)) : Nil
      @global_subr_index = global_subr_index
    end

    # Returns the global subroutine index.
    def global_subr_index : Array(Bytes)
      @global_subr_index
    end

    # Sets the char strings.
    protected def char_strings=(char_strings : Array(Bytes)) : Nil
      @char_strings = char_strings
    end

    # Returns the char strings.
    def char_strings : Array(Bytes)
      @char_strings
    end

    # Returns true if this is a CIDFont.
    abstract def cid_font? : Bool

    # Returns the Type 2 charstring for the given GID.
    abstract def type2_char_string(gid : Int32) : Type2CharString

    # Returns the number of glyphs in the font.
    def num_glyphs : Int32
      @char_strings.size
    end

    # Returns the number of charstrings (Java CFFFont#getNumCharStrings).
    def num_char_strings : Int32
      @char_strings.size
    end

    # Java CFFFont#toString: `<simple class name>[name=..., topDict=...,
    # charset=..., charStrings=...]`.
    #
    # The Java string uses `LinkedHashMap.toString` (so `{key=value, ...}`) and
    # `Arrays.deepToString` (signed decimal byte values); the same shape is
    # reproduced here. `charset` keeps its default object representation (Java
    # `Class@identityHash` is not reproducible), and floating-point values use
    # Crystal's shortest representation (diverges from `Double.toString` only in
    # scientific notation, e.g. `1.0e-05` vs `1.0E-5`).
    def to_s(io : ::IO) : Nil
      io << self.class.name.split("::").last
      io << "[name=" << @font_name
      io << ", topDict=" << java_map_string(@top_dict)
      io << ", charset=" << (@charset ? @charset.to_s : "null")
      io << ", charStrings=" << deep_to_string(@char_strings)
      io << "]"
    end

    private def java_map_string(map : Hash(String, CFFDictValue)) : String
      return "{}" if map.empty?

      "{" + map.join(", ") { |key, value| "#{key}=#{java_value_string(value)}" } + "}"
    end

    private def java_value_string(value : CFFDictValue) : String
      case item = value
      when String           then item
      when Bool             then item ? "true" : "false"
      when Int32            then item.to_s
      when Float64          then item.to_s
      when Array(CFFNumber) then "[" + item.map { |number| java_value_string(number) }.join(", ") + "]"
      else                       item.to_s
      end
    end

    private def deep_to_string(char_strings : Array(Bytes)) : String
      return "[]" if char_strings.empty?

      "[" + char_strings.map { |bytes| deep_bytes_to_string(bytes) }.join(", ") + "]"
    end

    private def deep_bytes_to_string(bytes : Bytes) : String
      return "[]" if bytes.empty?

      "[" + bytes.map { |byte| signed_byte_string(byte) }.join(", ") + "]"
    end

    # Java renders `byte` values as signed decimals.
    private def signed_byte_string(byte : UInt8) : String
      byte < 128 ? byte.to_s : (byte.to_i32 - 256).to_s
    end
  end
end

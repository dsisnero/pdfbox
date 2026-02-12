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
  end
end

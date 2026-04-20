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

require "../encoding"
require "./type1_font"

module Fontbox::Type1
  class Type1Parser
    EEXEC_KEY      = 55_665
    CHARSTRING_KEY =  4_330

    @lexer : Type1Lexer?
    @font : Type1Font?

    def parse(segment1 : Bytes, segment2 : Bytes) : Type1Font
      @font = Type1Font.new(segment1, segment2)
      parse_ascii(segment1)
      parse_binary(segment2) unless segment2.empty?
      font
    rescue ex : ArgumentError
      raise IO::Error.new(ex.message)
    end

    private def font : Type1Font
      font = @font
      raise "Type1 font was not initialized" unless font
      font
    end

    private def lexer : Type1Lexer
      lexer = @lexer
      raise "Type1 lexer was not initialized" unless lexer
      lexer
    end

    private def current_token : Token
      token = lexer.peek_token
      raise IO::Error.new("Expected token but reached end of input") unless token
      token
    end

    private def next_token : Token
      token = lexer.next_token
      raise IO::Error.new("Expected token but reached end of input") unless token
      token
    end

    private def parse_ascii(bytes : Bytes) : Nil
      raise IO::Error.new("ASCII segment of type 1 font is empty") if bytes.empty?
      if bytes.size < 2 || (bytes[0] != '%'.ord || bytes[1] != '!'.ord)
        raise IO::Error.new("Invalid start of ASCII segment of type 1 font")
      end

      @lexer = Type1Lexer.new(bytes)

      if lexer.peek_token.try(&.text) == "FontDirectory"
        read(Kind::NAME, "FontDirectory")
        read(Kind::LITERAL)
        read(Kind::NAME, "known")
        read(Kind::START_PROC)
        read_proc_void
        read(Kind::START_PROC)
        read_proc_void
        read(Kind::NAME, "ifelse")
      end

      length = read(Kind::INTEGER).int_value
      read(Kind::NAME, "dict")
      read_maybe(Kind::NAME, "dup")
      read(Kind::NAME, "begin")

      length.times do
        token = lexer.peek_token
        break unless token
        if token.kind == Kind::NAME && {"currentdict", "end"}.includes?(token.text)
          break
        end

        key = read(Kind::LITERAL).text.to_s
        case key
        when "FontInfo", "Fontinfo"
          read_font_info(read_simple_dict)
        when "Metrics"
          read_simple_dict
        when "Encoding"
          read_encoding
        else
          read_simple_value(key)
        end
      end

      read_maybe(Kind::NAME, "currentdict")
      read(Kind::NAME, "end")
      read(Kind::NAME, "currentfile")
      read(Kind::NAME, "eexec")
    end

    private def read_simple_value(key : String) : Nil
      value = read_dict_value
      first = value.first?
      return unless first

      case key
      when "FontName"
        font.font_name = first.text.to_s
      when "PaintType"
        font.paint_type = first.int_value
      when "FontType"
        font.font_type = first.int_value
      when "FontMatrix"
        font.font_matrix_values = array_to_numbers(value)
      when "FontBBox"
        font.font_bbox_values = array_to_numbers(value)
      when "UniqueID"
        font.unique_id = first.int_value
      when "StrokeWidth"
        font.stroke_width = first.float_value
      when "FID"
        font.font_id = first.text.to_s
      end
    end

    private def read_encoding : Nil
      if lexer.peek_kind(Kind::NAME)
        name = next_token.text.to_s
        case name
        when "StandardEncoding"
          font.encoding = Fontbox::StandardEncoding::INSTANCE
        else
          raise IO::Error.new("Unknown encoding: #{name}")
        end
        read_maybe(Kind::NAME, "readonly")
        read(Kind::NAME, "def")
      else
        read(Kind::INTEGER)
        read_maybe(Kind::NAME, "array")
        until lexer.peek_token.nil? ||
              (lexer.peek_kind(Kind::NAME) &&
              {"dup", "readonly", "def"}.includes?(current_token.text))
          lexer.next_token
        end

        code_to_name = Hash(Int32, String).new
        while lexer.peek_kind(Kind::NAME) &&
              current_token.text == "dup"
          read(Kind::NAME, "dup")
          code = read(Kind::INTEGER).int_value
          name = read(Kind::LITERAL).text.to_s
          read(Kind::NAME, "put")
          code_to_name[code] = name
        end
        font.encoding = Fontbox::BuiltInEncoding.new(code_to_name)
        read_maybe(Kind::NAME, "readonly")
        read(Kind::NAME, "def")
      end
    end

    private def array_to_numbers(value : Array(Token)) : Array(Float32)
      numbers = [] of Float32
      (1...(value.size - 1)).each do |i|
        token = value[i]
        case token.kind
        when Kind::REAL, Kind::INTEGER
          numbers << token.float_value
        else
          raise IO::Error.new("Expected INTEGER or REAL but got #{token} at array position #{i}")
        end
      end
      numbers
    end

    private def read_font_info(font_info : Hash(String, Array(Token))) : Nil
      font_info.each do |key, value|
        next if value.empty?
        first = value.first
        case key
        when "version"
          font.version = first.text.to_s
        when "Notice"
          font.notice = first.text.to_s
        when "FullName"
          font.full_name = first.text.to_s
        when "FamilyName"
          font.family_name = first.text.to_s
        when "Weight"
          font.weight = first.text.to_s
        when "ItalicAngle"
          font.italic_angle = first.float_value
        when "isFixedPitch"
          font.fixed_pitch = first.boolean_value
        when "UnderlinePosition"
          font.underline_position = first.float_value
        when "UnderlineThickness"
          font.underline_thickness = first.float_value
        end
      end
    end

    private def read_simple_dict : Hash(String, Array(Token))
      dict = Hash(String, Array(Token)).new
      length = read(Kind::INTEGER).int_value
      read(Kind::NAME, "dict")
      read_maybe(Kind::NAME, "dup")
      return dict if read_maybe(Kind::NAME, "def")

      read(Kind::NAME, "begin")
      length.times do
        break unless lexer.peek_token
        read(Kind::NAME) if lexer.peek_kind(Kind::NAME) && current_token.text != "end"
        break unless lexer.peek_token
        break if lexer.peek_kind(Kind::NAME) && current_token.text == "end"

        key = read(Kind::LITERAL).text.to_s
        dict[key] = read_dict_value
      end

      read(Kind::NAME, "end")
      read_maybe(Kind::NAME, "readonly")
      read(Kind::NAME, "def")
      dict
    end

    private def read_dict_value : Array(Token)
      value = read_value
      read_def
      value
    end

    private def read_value : Array(Token)
      value = [] of Token
      token = lexer.next_token
      return value unless token
      value << token

      case token.kind
      when Kind::START_ARRAY
        open_array = 1
        until open_array == 0
          next_token = lexer.next_token || return value
          open_array += 1 if next_token.kind == Kind::START_ARRAY
          value << next_token
          open_array -= 1 if next_token.kind == Kind::END_ARRAY
        end
      when Kind::START_PROC
        value.concat(read_proc)
      when Kind::START_DICT
        read(Kind::END_DICT)
        return value
      end

      read_post_script_wrapper(value)
      value
    end

    private def read_post_script_wrapper(value : Array(Token)) : Nil
      raise IO::Error.new("Missing start token for the system dictionary") unless lexer.peek_token
      return unless current_token.text == "systemdict"

      read(Kind::NAME, "systemdict")
      read(Kind::LITERAL, "internaldict")
      read(Kind::NAME, "known")
      read(Kind::START_PROC)
      read_proc_void
      read(Kind::START_PROC)
      read_proc_void
      read(Kind::NAME, "ifelse")
      read(Kind::START_PROC)
      read(Kind::NAME, "pop")
      value.clear
      value.concat(read_value)
      read(Kind::END_PROC)
      read(Kind::NAME, "if")
    end

    private def read_proc : Array(Token)
      value = [] of Token
      open_proc = 1
      until open_proc == 0
        raise IO::Error.new("Malformed procedure: missing token") unless lexer.peek_token
        open_proc += 1 if lexer.peek_kind(Kind::START_PROC)
        token = next_token
        value << token
        open_proc -= 1 if token.kind == Kind::END_PROC
      end
      if execute_only = read_maybe(Kind::NAME, "executeonly")
        value << execute_only
      end
      value
    end

    private def read_proc_void : Nil
      open_proc = 1
      until open_proc == 0
        raise IO::Error.new("Malformed procedure: missing token") unless lexer.peek_token
        open_proc += 1 if lexer.peek_kind(Kind::START_PROC)
        token = next_token
        open_proc -= 1 if token.kind == Kind::END_PROC
      end
      read_maybe(Kind::NAME, "executeonly")
    end

    private def parse_binary(bytes : Bytes) : Nil
      decrypted = decrypt_binary(bytes)
      @lexer = Type1Lexer.new(decrypted)

      while lexer.peek_token && current_token.text != "Private"
        lexer.next_token
      end
      raise IO::Error.new("/Private token not found") unless lexer.peek_token

      read(Kind::LITERAL, "Private")
      length = read(Kind::INTEGER).int_value
      read(Kind::NAME, "dict")
      read_maybe(Kind::NAME, "dup")
      read(Kind::NAME, "begin")

      len_iv = 4
      length.times do
        break unless lexer.peek_kind(Kind::LITERAL)
        key = read(Kind::LITERAL).text.to_s
        len_iv = handle_private_dict_entry(key, len_iv)
      end

      until lexer.peek_kind(Kind::LITERAL) &&
            current_token.text == "CharStrings"
        raise IO::Error.new("Missing 'CharStrings' dictionary in type 1 font") unless lexer.next_token
      end

      read(Kind::LITERAL, "CharStrings")
      read_char_strings(len_iv)
    end

    private def decrypt_binary(bytes : Bytes) : Bytes
      if binary?(bytes)
        decrypt(bytes, EEXEC_KEY, 4)
      else
        decrypt(hex_to_binary(bytes), EEXEC_KEY, 4)
      end
    end

    private def handle_private_dict_entry(key : String, len_iv : Int32) : Int32
      case key
      when "Subrs"
        read_subrs(len_iv)
      when "OtherSubrs"
        read_other_subrs
      when "lenIV"
        return read_dict_value.first.int_value
      when "ND"
        read_nd_definition
      when "NP"
        read_np_definition
      when "RD"
        read_rd_definition
      else
        read_private(key, read_dict_value)
      end
      len_iv
    end

    private def read_nd_definition : Nil
      read(Kind::START_PROC)
      read_maybe(Kind::NAME, "noaccess")
      read(Kind::NAME, "def")
      read(Kind::END_PROC)
      read_maybe(Kind::NAME, "executeonly")
      read_maybe(Kind::NAME, "readonly")
      read(Kind::NAME, "def")
    end

    private def read_np_definition : Nil
      read(Kind::START_PROC)
      read_maybe(Kind::NAME, "noaccess")
      read(Kind::NAME)
      read(Kind::END_PROC)
      read_maybe(Kind::NAME, "executeonly")
      read_maybe(Kind::NAME, "readonly")
      read(Kind::NAME, "def")
    end

    private def read_rd_definition : Nil
      read(Kind::START_PROC)
      read_proc_void
      read_maybe(Kind::NAME, "bind")
      read_maybe(Kind::NAME, "executeonly")
      read_maybe(Kind::NAME, "readonly")
      read(Kind::NAME, "def")
    end

    private def read_private(key : String, value : Array(Token)) : Nil
      first = value.first?
      case key
      when "BlueValues", "OtherBlues", "FamilyBlues", "FamilyOtherBlues",
           "StdHW", "StdVW", "StemSnapH", "StemSnapV"
        read_private_array(key, value)
      when "BlueScale", "BlueShift", "BlueFuzz", "ForceBold", "LanguageGroup"
        read_private_scalar(key, first)
      end
    end

    private def read_private_array(key : String, value : Array(Token)) : Nil
      numbers = array_to_numbers(value)
      case key
      when "BlueValues"       then font.blue_values = numbers
      when "OtherBlues"       then font.other_blues = numbers
      when "FamilyBlues"      then font.family_blues = numbers
      when "FamilyOtherBlues" then font.family_other_blues = numbers
      when "StdHW"            then font.std_hw = numbers
      when "StdVW"            then font.std_vw = numbers
      when "StemSnapH"        then font.stem_snap_h = numbers
      when "StemSnapV"        then font.stem_snap_v = numbers
      end
    end

    private def read_private_scalar(key : String, first : Token?) : Nil
      return unless first

      case key
      when "BlueScale"     then font.blue_scale = first.float_value
      when "BlueShift"     then font.blue_shift = first.int_value
      when "BlueFuzz"      then font.blue_fuzz = first.int_value
      when "ForceBold"     then font.force_bold = first.boolean_value
      when "LanguageGroup" then font.language_group = first.int_value
      end
    end

    private def read_subrs(len_iv : Int32) : Nil
      length = read(Kind::INTEGER).int_value
      font.subrs = Array(Bytes?).new(length, nil)
      read(Kind::NAME, "array")

      length.times do
        break unless lexer.peek_token
        break unless lexer.peek_kind(Kind::NAME) && current_token.text == "dup"
        read(Kind::NAME, "dup")
        index = read(Kind::INTEGER).int_value
        read(Kind::INTEGER)
        charstring = read(Kind::CHARSTRING)
        data = charstring.data
        if data && index < font.subrs.size
          font.subrs[index] = decrypt(data, CHARSTRING_KEY, len_iv)
        end
        read_put
      end
      read_def
    end

    private def read_other_subrs : Nil
      raise IO::Error.new("Missing start token of OtherSubrs procedure") unless lexer.peek_token
      if lexer.peek_kind(Kind::START_ARRAY)
        read_value
        read_def
      else
        length = read(Kind::INTEGER).int_value
        read(Kind::NAME, "array")
        length.times do
          read(Kind::NAME, "dup")
          read(Kind::INTEGER)
          read_value
          read_put
        end
        read_def
      end
    end

    private def read_char_strings(len_iv : Int32) : Nil
      length = read(Kind::INTEGER).int_value
      read(Kind::NAME, "dict")
      read(Kind::NAME, "dup")
      read(Kind::NAME, "begin")

      length.times do
        break unless lexer.peek_token
        break if lexer.peek_kind(Kind::NAME) && current_token.text == "end"
        name = read(Kind::LITERAL).text.to_s
        read(Kind::INTEGER)
        charstring = read(Kind::CHARSTRING)
        data = charstring.data
        raise IO::Error.new("CharString data missing for #{name}") unless data
        font.charstrings[name] = decrypt(data, CHARSTRING_KEY, len_iv)
        read_def
      end

      read(Kind::NAME, "end")
    end

    private def read_def : Nil
      read_maybe(Kind::NAME, "readonly")
      read_maybe(Kind::NAME, "noaccess")
      token = read(Kind::NAME)
      case token.text
      when "ND", "|-"
        return
      when "noaccess"
        token = read(Kind::NAME)
      end
      return if token.text == "def"
      raise IO::Error.new("Found #{token} but expected ND")
    end

    private def read_put : Nil
      read_maybe(Kind::NAME, "readonly")
      token = read(Kind::NAME)
      case token.text
      when "NP", "|"
        return
      when "noaccess"
        token = read(Kind::NAME)
      end
      return if token.text == "put"
      raise IO::Error.new("Found #{token} but expected NP")
    end

    private def read(kind : Kind) : Token
      token = lexer.next_token
      if token.nil? || token.kind != kind
        raise IO::Error.new("Found #{token} but expected #{kind}")
      end
      token
    end

    private def read(kind : Kind, name : String) : Nil
      token = read(kind)
      if token.text != name
        raise IO::Error.new("Found #{token} but expected #{name}")
      end
    end

    private def read_maybe(kind : Kind, name : String) : Token?
      token = lexer.peek_token
      if token && token.kind == kind && token.text == name
        return lexer.next_token
      end
      nil
    end

    private def decrypt(cipher_bytes : Bytes, r : Int32, n : Int32) : Bytes
      return cipher_bytes if n == -1
      return Bytes.empty if cipher_bytes.empty? || n > cipher_bytes.size

      c1 = 52_845
      c2 = 22_719
      plain = Bytes.new(cipher_bytes.size - n)
      cipher_bytes.each_with_index do |cipher_byte, i|
        cipher = cipher_byte.to_i
        decoded = cipher ^ (r >> 8)
        plain[i - n] = decoded.to_u8 if i >= n
        r = ((((cipher + r).to_i64 * c1) + c2) & 0xffff).to_i32
      end
      plain
    end

    private def binary?(bytes : Bytes) : Bool
      return true if bytes.size < 4
      4.times do |i|
        byte = bytes[i]
        next if {0x0a, 0x0d, 0x20, '\t'.ord}.includes?(byte)
        return true if byte.unsafe_chr.to_i?(16).nil?
      end
      false
    end

    private def hex_to_binary(bytes : Bytes) : Bytes
      digits = bytes.select { |byte| !byte.unsafe_chr.to_i?(16).nil? }
      out = Bytes.new(digits.size // 2)
      prev = nil.as(Int32?)
      index = 0
      digits.each do |byte|
        digit = byte.unsafe_chr.to_i(16)
        if prev.nil?
          prev = digit
        else
          high = prev || 0
          out[index] = (high * 16 + digit).to_u8
          index += 1
          prev = nil
        end
      end
      out
    end
  end
end

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

require "log"
require "./cff_font"

module Fontbox::CFF
  # This class represents a parser for a CFF font.
  class CFFParser
    Log = ::Log.for(self)

    private TAG_OTTO    = "OTTO"
    private TAG_TTCF    = "ttcf"
    private TAG_TTFONLY = "\u0000\u0001\u0000\u0000"

    private OPERATORS = Hash(Int32, String).new.tap do |hash|
      # Top DICT
      hash[0] = "version"
      hash[1] = "Notice"
      hash[2] = "FullName"
      hash[3] = "FamilyName"
      hash[4] = "Weight"
      hash[5] = "FontBBox"
      hash[13] = "UniqueID"
      hash[14] = "XUID"
      hash[15] = "charset"
      hash[16] = "Encoding"
      hash[17] = "CharStrings"
      hash[18] = "Private"
      # 2-byte operators: key = (b1 << 8) + b0 where b0 = 12
      hash[(0 << 8) + 12] = "Copyright"
      hash[(1 << 8) + 12] = "isFixedPitch"
      hash[(2 << 8) + 12] = "ItalicAngle"
      hash[(3 << 8) + 12] = "UnderlinePosition"
      hash[(4 << 8) + 12] = "UnderlineThickness"
      hash[(5 << 8) + 12] = "PaintType"
      hash[(6 << 8) + 12] = "CharstringType"
      hash[(7 << 8) + 12] = "FontMatrix"
      hash[(8 << 8) + 12] = "StrokeWidth"
      hash[(9 << 8) + 12] = "BlueScale"
      hash[(10 << 8) + 12] = "BlueShift"
      hash[(11 << 8) + 12] = "BlueFuzz"
      hash[(12 << 8) + 12] = "StemSnapH"
      hash[(13 << 8) + 12] = "StemSnapV"
      hash[(14 << 8) + 12] = "ForceBold"
      hash[(15 << 8) + 12] = "LanguageGroup"
      hash[(16 << 8) + 12] = "ExpansionFactor"
      hash[(17 << 8) + 12] = "initialRandomSeed"
      hash[(20 << 8) + 12] = "SyntheticBase"
      hash[(21 << 8) + 12] = "PostScript"
      hash[(22 << 8) + 12] = "BaseFontName"
      hash[(23 << 8) + 12] = "BaseFontBlend"
      hash[(30 << 8) + 12] = "ROS"
      hash[(31 << 8) + 12] = "CIDFontVersion"
      hash[(32 << 8) + 12] = "CIDFontRevision"
      hash[(33 << 8) + 12] = "CIDFontType"
      hash[(34 << 8) + 12] = "CIDCount"
      hash[(35 << 8) + 12] = "UIDBase"
      hash[(36 << 8) + 12] = "FDArray"
      hash[(37 << 8) + 12] = "FDSelect"
      hash[(38 << 8) + 12] = "FontName"
      # Private DICT single-byte operators
      hash[6] = "BlueValues"
      hash[7] = "OtherBlues"
      hash[8] = "FamilyBlues"
      hash[9] = "FamilyOtherBlues"
      hash[10] = "StdHW"
      hash[11] = "StdVW"
      hash[19] = "Subrs"
      hash[20] = "defaultWidthX"
      hash[21] = "nominalWidthX"
    end

    private def operator_name(b0 : Int32, b1 : Int32 = 0) : String?
      key = b1 == 0 ? b0 : (b1 << 8) + b0
      OPERATORS[key]?
    end

    @string_index : Array(String)?
    @source : ByteSource?

    # for debugging only
    @debug_font_name : String?

    # Source from which bytes may be read in the future.
    abstract class ByteSource
      # Returns the source bytes. May be called more than once.
      abstract def bytes : Bytes
    end

    # Simple byte source implementation.
    class SimpleByteSource < ByteSource
      def initialize(@bytes : Bytes)
      end

      def bytes : Bytes
        @bytes
      end
    end

    # Parse CFF font using a RandomAccessRead as input.
    #
    # @param random_access_read the source to be parsed
    # @return the parsed CFF fonts
    # @raises Exception If there is an error reading from the stream
    def parse(random_access_read : Pdfbox::IO::RandomAccessRead) : Array(CFFFont)
      # TODO do we need to store the source data of the font? It isn't used at all
      bytes = Bytes.new(random_access_read.size.to_i32)
      random_access_read.position = 0
      random_access_read.read_fully(bytes)
      random_access_read.position = 0
      @source = SimpleByteSource.new(bytes)
      parse(bytes)
    end

    # Parse CFF font using bytes as input.
    #
    # @param bytes the source to be parsed
    # @return the parsed CFF fonts
    # @raises Exception If there is an error reading from the stream
    def parse(bytes : Bytes) : Array(CFFFont)
      @source = SimpleByteSource.new(bytes)
      input = DataInputByteArray.new(bytes)
      parse(input)
    end

    private def parse(input : DataInput) : Array(CFFFont)
      input = skip_header(input)
      name_index = read_string_index_data(input)
      if name_index.empty?
        raise "Name index missing in CFF font"
      end
      top_dict_index = read_index_data(input)
      if top_dict_index.empty?
        raise "Top DICT INDEX missing in CFF font"
      end

      @string_index = read_string_index_data(input)
      global_subr_index = read_index_data(input)

      fonts = Array(CFFFont).new(name_index.size)
      name_index.each_with_index do |name, i|
        font = parse_font(input, name, top_dict_index[i])
        font.global_subr_index = global_subr_index
        font.source = @source.not_nil!
        fonts << font
      end
      fonts
    end

    private def skip_header(input : DataInput) : DataInput
      first_tag = read_tag_name(input)
      # try to determine which kind of font we have
      case first_tag
      when TAG_OTTO
        input = create_tagged_cff_data_input(input)
      when TAG_TTCF
        raise "True Type Collection fonts are not supported."
      when TAG_TTFONLY
        raise "OpenType fonts containing a true type font are not supported."
      else
        input.position = 0
      end

      # read header and discard
      read_header(input)
      input
    end

    private def read_tag_name(input : DataInput) : String
      bytes = input.read_bytes(4)
      String.new(bytes)
    end

    private def read_long(input : DataInput) : UInt32
      (input.read_unsigned_short.to_u32 << 16) | input.read_unsigned_short.to_u32
    end

    private def read_off_size(input : DataInput) : Int32
      off_size = input.read_unsigned_byte
      if off_size < 1 || off_size > 4
        raise "Illegal (< 1 or > 4) offSize value #{off_size} in CFF font at position #{input.position - 1}"
      end
      off_size
    end

    private def read_header(input : DataInput) : Header
      major = input.read_unsigned_byte
      minor = input.read_unsigned_byte
      hdr_size = input.read_unsigned_byte
      off_size = read_off_size(input)
      Header.new(major, minor, hdr_size, off_size)
    end

    private def create_tagged_cff_data_input(input : DataInput) : DataInput
      # this is OpenType font containing CFF data
      # so find CFF tag
      num_tables = input.read_short
      _ = input.read_short
      _ = input.read_short
      _ = input.read_short
      num_tables.times do
        tag_name = read_tag_name(input)
        _ = read_long(input)
        offset = read_long(input)
        length = read_long(input)
        if tag_name == "CFF "
          input.position = offset.to_i32
          bytes = input.read_bytes(length.to_i32)
          return DataInputByteArray.new(bytes)
        end
      end
      raise "CFF tag not found in this OpenType font."
    end

    private def read_index_data_offsets(input : DataInput) : Array(Int32)
      count = input.read_unsigned_short
      return [] of Int32 if count == 0
      off_size = read_off_size(input)
      offsets = Array(Int32).new(count + 1)
      (count + 1).times do |_|
        offset = input.read_offset(off_size)
        if offset > input.length
          raise "illegal offset value #{offset} in CFF font"
        end
        offsets << offset
      end
      offsets
    end

    private def read_index_data(input : DataInput) : Array(Bytes)
      offsets = read_index_data_offsets(input)
      return [] of Bytes if offsets.empty?
      count = offsets.size - 1
      index_data_values = Array(Bytes).new(count)
      count.times do |i|
        length = offsets[i + 1] - offsets[i]
        index_data_values << input.read_bytes(length)
      end
      index_data_values
    end

    private def read_string_index_data(input : DataInput) : Array(String)
      offsets = read_index_data_offsets(input)
      return [] of String if offsets.empty?
      count = offsets.size - 1
      index_data_values = Array(String).new(count)
      count.times do |i|
        length = offsets[i + 1] - offsets[i]
        if length < 0
          raise "Negative index data length #{length} at #{i}: offsets[#{i + 1}]=#{offsets[i + 1]}, offsets[#{i}]=#{offsets[i]}"
        end
        bytes = input.read_bytes(length)
        # Java uses StandardCharsets.ISO_8859_1
        index_data_values << String.new(bytes)
      end
      index_data_values
    end

    private def read_dict_data(input : DataInput) : DictData
      dict = DictData.new
      while input.has_remaining?
        dict.add(read_entry(input))
      end
      dict
    end

    private def read_entry(input : DataInput) : DictData::Entry
      entry = DictData::Entry.new
      loop do
        b0 = input.read_unsigned_byte
        if b0 >= 0 && b0 <= 21
          entry.operator_name = read_operator(input, b0)
          break
        elsif b0 == 28 || b0 == 29
          entry.add_operand(read_integer_number(input, b0))
        elsif b0 == 30
          entry.add_operand(read_real_number(input))
        elsif b0 >= 32 && b0 <= 254
          entry.add_operand(read_integer_number(input, b0))
        else
          raise "invalid DICT data b0 byte: #{b0}"
        end
      end
      entry
    end

    private def read_operator(input : DataInput, b0 : Int32) : String
      if b0 == 12
        b1 = input.read_unsigned_byte
        name = operator_name(b0, b1)
      else
        name = operator_name(b0)
      end
      name || raise "Unknown operator b0=#{b0}"
    end

    private def read_integer_number(input : DataInput, b0 : Int32) : CFFNumber
      if b0 == 28
        input.read_short.to_i32
      elsif b0 == 29
        input.read_int
      elsif b0 >= 32 && b0 <= 246
        b0 - 139
      elsif b0 >= 247 && b0 <= 250
        b1 = input.read_unsigned_byte
        (b0 - 247) * 256 + b1 + 108
      elsif b0 >= 251 && b0 <= 254
        b1 = input.read_unsigned_byte
        -(b0 - 251) * 256 - b1 - 108
      else
        raise "Invalid integer number b0=#{b0}"
      end
    end

    private def read_real_number(input : DataInput) : Float64
      sb = String::Builder.new
      done = false
      exponent_missing = false
      has_exponent = false
      nibbles = uninitialized Int32[2]
      while !done
        b = input.read_unsigned_byte
        nibbles[0] = b // 16
        nibbles[1] = b % 16
        nibbles.each do |nibble|
          case nibble
          when 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9
            sb << nibble.to_s
            exponent_missing = false
          when 0xa
            sb << '.'
          when 0xb
            if has_exponent
              Log.warn { "duplicate 'E' ignored after #{sb}" }
              next
            end
            sb << 'E'
            exponent_missing = true
            has_exponent = true
          when 0xc
            if has_exponent
              Log.warn { "duplicate 'E-' ignored after #{sb}" }
              next
            end
            sb << "E-"
            exponent_missing = true
            has_exponent = true
          when 0xd
            # no-op
          when 0xe
            sb << '-'
          when 0xf
            done = true
          else
            raise "illegal nibble #{nibble}"
          end
        end
      end
      if exponent_missing
        # the exponent is missing, just append "0" to avoid an exception
        # not sure if 0 is the correct value, but it seems to fit
        # see PDFBOX-1522
        sb << '0'
      end
      if sb.empty?
        return 0.0
      end
      begin
        sb.to_s.to_f64
      rescue ex : ArgumentError
        raise "Failed to parse real number: #{sb}"
      end
    end

    private def read_string(index : Int32) : String
      if index < 0
        raise "Invalid negative index when reading a string"
      end
      if index <= 390
        return StandardString.get_name(index)
      end
      if string_index = @string_index
        if index - 391 < string_index.size
          return string_index[index - 391]
        end
      end
      # technically this maps to .notdef, but we need a unique sid name
      "SID#{index}"
    end

    private def get_string(dict : DictData, name : String) : String?
      entry = dict.get_entry(name)
      if entry && entry.has_operands?
        read_string(entry.get_number(0).to_i)
      end
    end

    private def parse_ros(top_dict : DictData) : CFFCIDFont?
      # determine if this is a Type 1-equivalent font or a CIDFont
      ros_entry = top_dict.get_entry("ROS")
      if ros_entry
        if ros_entry.size < 3
          raise "ROS entry must have 3 elements"
        end
        cff_cid_font = CFFCIDFont.new
        cff_cid_font.registry = read_string(ros_entry.get_number(0).to_i)
        cff_cid_font.ordering = read_string(ros_entry.get_number(1).to_i)
        cff_cid_font.supplement = ros_entry.get_number(2).to_i
        return cff_cid_font
      end
      nil
    end

    private def parse_font(input : DataInput, name : String, top_dict_index : Bytes) : CFFFont
      # top dict
      top_dict_input = DataInputByteArray.new(top_dict_index)
      top_dict = read_dict_data(top_dict_input)

      # we don't support synthetic fonts
      synthetic_base_entry = top_dict.get_entry("SyntheticBase")
      if synthetic_base_entry
        raise "Synthetic Fonts are not supported"
      end

      # determine if this is a Type 1-equivalent font or a CIDFont
      font : CFFFont
      cff_cid_font = parse_ros(top_dict)
      is_cid_font = !cff_cid_font.nil?
      if cff_cid_font
        font = cff_cid_font
      else
        font = CFFType1Font.new
      end

      # name
      @debug_font_name = name
      font.name = name

      # top dict
      font.add_value_to_top_dict("version", get_string(top_dict, "version"))
      font.add_value_to_top_dict("Notice", get_string(top_dict, "Notice"))
      font.add_value_to_top_dict("Copyright", get_string(top_dict, "Copyright"))
      font.add_value_to_top_dict("FullName", get_string(top_dict, "FullName"))
      font.add_value_to_top_dict("FamilyName", get_string(top_dict, "FamilyName"))
      font.add_value_to_top_dict("Weight", get_string(top_dict, "Weight"))
      font.add_value_to_top_dict("isFixedPitch", top_dict.get_boolean("isFixedPitch", false))
      font.add_value_to_top_dict("ItalicAngle", top_dict.get_number("ItalicAngle", 0))
      font.add_value_to_top_dict("UnderlinePosition", top_dict.get_number("UnderlinePosition", -100))
      font.add_value_to_top_dict("UnderlineThickness", top_dict.get_number("UnderlineThickness", 50))
      font.add_value_to_top_dict("PaintType", top_dict.get_number("PaintType", 0))
      font.add_value_to_top_dict("CharstringType", top_dict.get_number("CharstringType", 2))
      font.add_value_to_top_dict("FontMatrix", top_dict.get_array("FontMatrix", [0.001, 0.0, 0.0, 0.001, 0.0, 0.0] of CFFNumber))
      font.add_value_to_top_dict("UniqueID", top_dict.get_number("UniqueID", nil))
      font.add_value_to_top_dict("FontBBox", top_dict.get_array("FontBBox", [0, 0, 0, 0] of CFFNumber))
      font.add_value_to_top_dict("StrokeWidth", top_dict.get_number("StrokeWidth", 0))
      font.add_value_to_top_dict("XUID", top_dict.get_array("XUID", nil))

      # charstrings index
      char_strings_entry = top_dict.get_entry("CharStrings")
      if char_strings_entry.nil? || !char_strings_entry.has_operands?
        raise "CharStrings is missing or empty"
      end
      char_strings_offset = char_strings_entry.get_number(0).to_i
      input.position = char_strings_offset
      char_strings_index = read_index_data(input)

      # charset
      charset_entry = top_dict.get_entry("charset")
      charset : Charset
      if charset_entry && charset_entry.has_operands?
        charset_id = charset_entry.get_number(0).to_i
        if !is_cid_font && charset_id == 0
          charset = ISOAdobeCharset.instance
        elsif !is_cid_font && charset_id == 1
          charset = ExpertCharset.instance
        elsif !is_cid_font && charset_id == 2
          charset = ExpertSubsetCharset.instance
        elsif char_strings_index.size > 0
          input.position = charset_id
          charset = read_charset(input, char_strings_index.size, is_cid_font)
        else
          # that should not happen
          Log.debug { "Couldn't read CharStrings index - returning empty charset instead" }
          charset = EmptyCharsetType1.new
        end
      else
        if is_cid_font
          # a CID font with no charset does not default to any predefined charset
          charset = EmptyCharsetCID.new(char_strings_index.size)
        else
          charset = ISOAdobeCharset.instance
        end
      end
      font.charset = charset

      # charstrings dict
      font.char_strings = char_strings_index

      # format-specific dictionaries
      if is_cid_font
        parse_cid_font_dicts(input, top_dict, font.as(CFFCIDFont), char_strings_index.size)
      else
        parse_type1_dicts(input, top_dict, font.as(CFFType1Font), charset)
      end

      font
    end

    private def read_charset(data_input : DataInput, n_glyphs : Int32, is_cid_font : Bool) : Charset
      format = data_input.read_unsigned_byte
      case format
      when 0
        read_format0_charset(data_input, n_glyphs, is_cid_font)
      when 1
        read_format1_charset(data_input, n_glyphs, is_cid_font)
      when 2
        read_format2_charset(data_input, n_glyphs, is_cid_font)
      else
        # we can't return new EmptyCharset(0), because this will bring more mayhem
        raise "Incorrect charset format #{format}"
      end
    end

    private def read_format0_charset(data_input : DataInput, n_glyphs : Int32, is_cid_font : Bool) : Charset
      charset = Format0Charset.new(is_cid_font)
      if is_cid_font
        charset.add_cid(0, 0)
        (1...n_glyphs).each do |gid|
          charset.add_cid(gid, data_input.read_unsigned_short)
        end
      else
        charset.add_sid(0, 0, ".notdef")
        (1...n_glyphs).each do |gid|
          sid = data_input.read_unsigned_short
          charset.add_sid(gid, sid, read_string(sid))
        end
      end
      charset
    end

    private def read_format1_charset(data_input : DataInput, n_glyphs : Int32, is_cid_font : Bool) : Charset
      charset = Format1Charset.new(is_cid_font)
      if is_cid_font
        charset.add_cid(0, 0)
        gid = 1
        while gid < n_glyphs
          range_first = data_input.read_unsigned_short
          range_left = data_input.read_unsigned_byte
          charset.add_range_mapping(RangeMapping.new(gid, range_first, range_left))
          gid += range_left + 1
        end
      else
        charset.add_sid(0, 0, ".notdef")
        gid = 1
        while gid < n_glyphs
          range_first = data_input.read_unsigned_short
          range_left = data_input.read_unsigned_byte + 1
          range_left.times do |j|
            sid = range_first + j
            charset.add_sid(gid + j, sid, read_string(sid))
          end
          gid += range_left
        end
      end
      charset
    end

    private def read_format2_charset(data_input : DataInput, n_glyphs : Int32, is_cid_font : Bool) : Charset
      charset = Format2Charset.new(is_cid_font)
      if is_cid_font
        charset.add_cid(0, 0)
        gid = 1
        while gid < n_glyphs
          first = data_input.read_unsigned_short
          n_left = data_input.read_unsigned_short
          charset.add_range_mapping(RangeMapping.new(gid, first, n_left))
          gid += n_left + 1
        end
      else
        charset.add_sid(0, 0, ".notdef")
        gid = 1
        while gid < n_glyphs
          first = data_input.read_unsigned_short
          n_left = data_input.read_unsigned_short + 1
          n_left.times do |j|
            sid = first + j
            charset.add_sid(gid + j, sid, read_string(sid))
          end
          gid += n_left
        end
      end
      charset
    end

    private def parse_type1_dicts(input : DataInput, top_dict : DictData, font : CFFType1Font, charset : Charset)
      # encoding
      encoding_entry = top_dict.get_entry("Encoding")
      encoding : CFFEncoding
      encoding_id = encoding_entry && encoding_entry.has_operands? ? encoding_entry.get_number(0).to_i : 0
      case encoding_id
      when 0
        encoding = StandardEncoding.instance
      when 1
        encoding = ExpertEncoding.instance
      else
        input.position = encoding_id
        encoding = read_encoding(input, charset)
      end
      font.encoding = encoding

      # read private dict
      private_entry = top_dict.get_entry("Private")
      if private_entry.nil? || private_entry.size < 2
        raise "Private dictionary entry missing for font #{font.name}"
      end
      private_offset = private_entry.get_number(1).to_i
      private_size = private_entry.get_number(0).to_i
      private_dict = read_dict_data(input, private_offset, private_size)

      # populate private dict
      priv_dict = read_private_dict(private_dict)
      priv_dict.each do |name, value|
        font.add_to_private_dict(name, value)
      end

      # local subrs
      local_subr_offset = private_dict.get_number("Subrs", 0)
      if local_subr_offset.is_a?(Int32) && local_subr_offset > 0
        input.position = private_offset + local_subr_offset
        font.add_to_private_dict("Subrs", read_index_data(input))
      end
    end

    private def parse_cid_font_dicts(input : DataInput, top_dict : DictData, font : CFFCIDFont, nr_of_char_strings : Int32)
      # In a CIDKeyed Font, the Private dictionary isn't in the Top Dict but in the Font dict
      # which can be accessed by a lookup using FDArray and FDSelect
      fd_array_entry = top_dict.get_entry("FDArray")
      if fd_array_entry.nil? || !fd_array_entry.has_operands?
        raise "FDArray is missing for a CIDKeyed Font."
      end

      # font dict index
      font_dict_offset = fd_array_entry.get_number(0).to_i
      input.position = font_dict_offset
      fd_index = read_index_data(input)
      if fd_index.empty?
        raise "Font dict index is missing for a CIDKeyed Font"
      end

      private_dictionaries = Array(Hash(String, CFFPrivateDictValue?)).new
      font_dictionaries = Array(Hash(String, CFFDictValue?)).new

      private_dict_populated = false
      fd_index.each do |bytes|
        font_dict_input = DataInputByteArray.new(bytes)
        font_dict = read_dict_data(font_dict_input)

        # font dict
        font_dict_map = Hash(String, CFFDictValue?).new
        font_dict_map["FontName"] = get_string(font_dict, "FontName")
        font_dict_map["FontType"] = font_dict.get_number("FontType", 0)
        font_dict_map["FontBBox"] = font_dict.get_array("FontBBox", nil)
        font_dict_map["FontMatrix"] = font_dict.get_array("FontMatrix", nil)
        # TODO OD-4 : Add here other keys
        font_dictionaries << font_dict_map

        # read private dict
        private_entry = font_dict.get_entry("Private")
        if private_entry.nil? || private_entry.size < 2
          # PDFBOX-5843 don't abort here, and don't skip empty bytes entries, because
          # getLocalSubrIndex() expects subr at a specific index
          private_dictionaries << Hash(String, CFFPrivateDictValue?).new
          next
        end

        private_offset = private_entry.get_number(1).to_i
        private_size = private_entry.get_number(0).to_i
        private_dict = read_dict_data(input, private_offset, private_size)

        # populate private dict
        private_dict_populated = true
        priv_dict = read_private_dict(private_dict)
        private_dictionaries << priv_dict

        # local subrs
        local_subr_offset = private_dict.get_number("Subrs", 0)
        if local_subr_offset.is_a?(Int32) && local_subr_offset > 0
          input.position = private_offset + local_subr_offset
          priv_dict["Subrs"] = read_index_data(input)
        end
      end

      if !private_dict_populated
        raise "Font DICT invalid without \"Private\" entry"
      end

      # font-dict (FD) select
      fd_select_entry = top_dict.get_entry("FDSelect")
      if fd_select_entry.nil? || !fd_select_entry.has_operands?
        raise "FDSelect is missing or empty"
      end
      fd_select_pos = fd_select_entry.get_number(0).to_i
      input.position = fd_select_pos
      fd_select = read_fd_select(input, nr_of_char_strings)

      # TODO almost certainly erroneous - CIDFonts do not have a top-level private dict
      # font.add_value_to_private_dict("defaultWidthX", 1000)
      # font.add_value_to_private_dict("nominalWidthX", 0)

      font.font_dicts = font_dictionaries
      font.priv_dicts = private_dictionaries
      font.fd_select = fd_select
    end

    private def read_dict_data(input : DataInput, offset : Int32, dict_size : Int32) : DictData
      dict = DictData.new
      if dict_size > 0
        input.position = offset
        end_position = offset + dict_size
        while input.position < end_position
          dict.add(read_entry(input))
        end
      end
      dict
    end

    private def read_private_dict(private_dict : DictData) : Hash(String, CFFPrivateDictValue?)
      priv_dict = Hash(String, CFFPrivateDictValue?).new
      priv_dict["BlueValues"] = private_dict.get_delta("BlueValues", nil)
      priv_dict["OtherBlues"] = private_dict.get_delta("OtherBlues", nil)
      priv_dict["FamilyBlues"] = private_dict.get_delta("FamilyBlues", nil)
      priv_dict["FamilyOtherBlues"] = private_dict.get_delta("FamilyOtherBlues", nil)
      priv_dict["BlueScale"] = private_dict.get_number("BlueScale", 0.039625)
      priv_dict["BlueShift"] = private_dict.get_number("BlueShift", 7)
      priv_dict["BlueFuzz"] = private_dict.get_number("BlueFuzz", 1)
      priv_dict["StdHW"] = private_dict.get_number("StdHW", nil)
      priv_dict["StdVW"] = private_dict.get_number("StdVW", nil)
      priv_dict["StemSnapH"] = private_dict.get_delta("StemSnapH", nil)
      priv_dict["StemSnapV"] = private_dict.get_delta("StemSnapV", nil)
      priv_dict["ForceBold"] = private_dict.get_boolean("ForceBold", false)
      priv_dict["LanguageGroup"] = private_dict.get_number("LanguageGroup", 0)
      priv_dict["ExpansionFactor"] = private_dict.get_number("ExpansionFactor", 0.06)
      priv_dict["initialRandomSeed"] = private_dict.get_number("initialRandomSeed", 0)
      priv_dict["defaultWidthX"] = private_dict.get_number("defaultWidthX", 0)
      priv_dict["nominalWidthX"] = private_dict.get_number("nominalWidthX", 0)
      priv_dict
    end

    private def read_fd_select(data_input : DataInput, n_glyphs : Int32) : FDSelect
      format = data_input.read_unsigned_byte
      case format
      when 0
        read_format0_fd_select(data_input, n_glyphs)
      when 3
        read_format3_fd_select(data_input)
      else
        raise "Invalid FDSelect format #{format}"
      end
    end

    private def read_format0_fd_select(data_input : DataInput, n_glyphs : Int32) : FDSelect
      fds = Array(Int32).new(n_glyphs)
      n_glyphs.times do
        fds << data_input.read_unsigned_byte
      end
      Format0FDSelect.new(fds)
    end

    private def read_format3_fd_select(data_input : DataInput) : FDSelect
      nb_ranges = data_input.read_unsigned_short
      range3 = Array(Range3).new(nb_ranges)
      nb_ranges.times do
        first = data_input.read_unsigned_short
        fd = data_input.read_unsigned_byte
        range3 << Range3.new(first, fd)
      end
      sentinel = data_input.read_unsigned_short
      Format3FDSelect.new(range3, sentinel)
    end

    private def read_encoding(data_input : DataInput, charset : Charset) : CFFEncoding
      format = data_input.read_unsigned_byte
      base_format = format & 0x7f
      case base_format
      when 0
        read_format0_encoding(data_input, charset, format)
      when 1
        read_format1_encoding(data_input, charset, format)
      else
        raise "Invalid encoding base format #{base_format}"
      end
    end

    private def read_format0_encoding(data_input : DataInput, charset : Charset, format : Int32) : CFFEncoding
      encoding = Format0Encoding.new(data_input.read_unsigned_byte)
      encoding.add(0, 0, ".notdef")
      (1..encoding.n_codes).each do |gid|
        code = data_input.read_unsigned_byte
        sid = charset.get_sid_for_gid(gid)
        encoding.add(code, sid, read_string(sid))
      end
      if (format & 0x80) != 0
        read_supplement(data_input, encoding)
      end
      encoding
    end

    private def read_format1_encoding(data_input : DataInput, charset : Charset, format : Int32) : CFFEncoding
      encoding = Format1Encoding.new(data_input.read_unsigned_byte)
      encoding.add(0, 0, ".notdef")
      gid = 1
      encoding.n_ranges.times do
        range_first = data_input.read_unsigned_byte
        range_left = data_input.read_unsigned_byte
        (0..range_left).each do |j|
          sid = charset.get_sid_for_gid(gid)
          encoding.add(range_first + j, sid, read_string(sid))
          gid += 1
        end
      end
      if (format & 0x80) != 0
        read_supplement(data_input, encoding)
      end
      encoding
    end

    private def read_supplement(data_input : DataInput, encoding : CFFBuiltInEncoding) : Nil
      n_sups = data_input.read_unsigned_byte
      supplement = Array(CFFBuiltInEncoding::Supplement).new(n_sups)
      n_sups.times do
        code = data_input.read_unsigned_byte
        sid = data_input.read_unsigned_short
        supplement << CFFBuiltInEncoding::Supplement.new(code, sid, read_string(sid))
      end
      encoding.supplement = supplement
      supplement.each do |sup|
        encoding.add(sup)
      end
    end

    private class Header
      getter major : Int32
      getter minor : Int32
      getter hdr_size : Int32
      getter off_size : Int32

      def initialize(@major, @minor, @hdr_size, @off_size)
      end

      def to_s(io : IO) : Nil
        io << "Header[major=" << @major << ", minor=" << @minor << ", hdrSize=" << @hdr_size << ", offSize=" << @off_size << "]"
      end
    end

    private class DictData
      @entries = Hash(String, Entry).new

      def add(entry : Entry) : Nil
        if name = entry.operator_name
          @entries[name] = entry
        end
      end

      def get_entry(name : String) : Entry?
        @entries[name]?
      end

      def get_boolean(name : String, default_value : Bool) : Bool
        entry = get_entry(name)
        return default_value unless entry && entry.has_operands?
        entry.get_boolean(0, default_value)
      end

      def get_number(name : String, default_value : CFFNumber? = nil) : CFFNumber?
        entry = get_entry(name)
        return default_value unless entry && entry.has_operands?
        entry.get_number(0)
      end

      def get_array(name : String, default_value : Array(CFFNumber)? = nil) : Array(CFFNumber)?
        entry = get_entry(name)
        return default_value unless entry && entry.has_operands?
        entry.get_operands
      end

      def get_delta(name : String, default_value : Array(CFFNumber)? = nil) : Array(CFFNumber)?
        entry = get_entry(name)
        return default_value unless entry && entry.has_operands?
        entry.get_delta
      end

      class Entry
        property operands : Array(CFFNumber) = [] of CFFNumber
        property operator_name : String?

        def add_operand(operand : CFFNumber) : Nil
          @operands << operand
        end

        def has_operands? : Bool
          !@operands.empty?
        end

        def size : Int32
          @operands.size
        end

        def get_number(index : Int32) : CFFNumber
          @operands[index]
        end

        def get_boolean(index : Int32, default_value : Bool) : Bool
          operand = @operands[index]
          if operand.is_a?(Int32)
            case operand
            when 0
              return false
            when 1
              return true
            end
          end
          default_value
        end

        def get_operands : Array(CFFNumber)
          @operands
        end

        def get_delta : Array(CFFNumber)
          result = @operands.dup
          (1...result.size).each do |i|
            result[i] = result[i - 1].to_i + result[i].to_i
          end
          result
        end
      end
    end

    # Abstract base class for built-in CFF encodings with supplement support
    private abstract class CFFBuiltInEncoding < CFFEncoding
      property supplement : Array(Supplement)?

      protected def initialize
        super
      end

      def add(supplement : Supplement) : Nil
        add(supplement.code, supplement.sid, supplement.name)
      end

      class Supplement
        getter code : Int32
        getter sid : Int32
        getter name : String

        def initialize(@code, @sid, @name)
        end

        def to_s(io : IO) : Nil
          io << "Supplement[code=" << @code << ", sid=" << @sid << "]"
        end
      end
    end

    private class Format0Encoding < CFFBuiltInEncoding
      getter n_codes : Int32

      def initialize(@n_codes)
        super()
      end

      def to_s(io : IO) : Nil
        io << "Format0Encoding[nCodes=" << @n_codes << ", supplement=" << @supplement << "]"
      end
    end

    private class Format1Encoding < CFFBuiltInEncoding
      getter n_ranges : Int32

      def initialize(@n_ranges)
        super()
      end

      def to_s(io : IO) : Nil
        io << "Format1Encoding[nRanges=" << @n_ranges << ", supplement=" << @supplement << "]"
      end
    end

    private class RangeMapping
      @start_value : Int32
      @end_value : Int32
      @start_mapped_value : Int32
      @end_mapped_value : Int32

      def initialize(start_gid : Int32, first : Int32, n_left : Int32)
        @start_value = start_gid
        @end_value = @start_value + n_left
        @start_mapped_value = first
        @end_mapped_value = @start_mapped_value + n_left
      end

      def is_in_range(value : Int32) : Bool
        value >= @start_value && value <= @end_value
      end

      def is_in_reverse_range(value : Int32) : Bool
        value >= @start_mapped_value && value <= @end_mapped_value
      end

      def map_value(value : Int32) : Int32
        is_in_range(value) ? @start_mapped_value + (value - @start_value) : 0
      end

      def map_reverse_value(value : Int32) : Int32
        is_in_reverse_range(value) ? @start_value + (value - @start_mapped_value) : 0
      end

      def to_s(io : IO) : Nil
        io << "RangeMapping[start value=" << @start_value << ", end value=" << @end_value << ", start mapped-value=" << @start_mapped_value << ", end mapped-value=" << @end_mapped_value << "]"
      end
    end

    private class Format0Charset < EmbeddedCharset
      def initialize(is_cid_font : Bool)
        super(is_cid_font)
      end
    end

    private class Format1Charset < EmbeddedCharset
      @ranges_cid2gid : Array(RangeMapping)

      def initialize(is_cid_font : Bool)
        super(is_cid_font)
        @ranges_cid2gid = [] of RangeMapping
      end

      def add_range_mapping(range_mapping : RangeMapping) : Nil
        @ranges_cid2gid << range_mapping
      end

      def get_cid_for_gid(gid : Int32) : Int32
        if is_cid_font?
          @ranges_cid2gid.each do |mapping|
            return mapping.map_value(gid) if mapping.is_in_range(gid)
          end
        end
        super
      end

      def get_gid_for_cid(cid : Int32) : Int32
        if is_cid_font?
          @ranges_cid2gid.each do |mapping|
            return mapping.map_reverse_value(cid) if mapping.is_in_reverse_range(cid)
          end
        end
        super
      end
    end

    private class Format2Charset < EmbeddedCharset
      @ranges_cid2gid : Array(RangeMapping)

      def initialize(is_cid_font : Bool)
        super(is_cid_font)
        @ranges_cid2gid = [] of RangeMapping
      end

      def add_range_mapping(range_mapping : RangeMapping) : Nil
        @ranges_cid2gid << range_mapping
      end

      def get_cid_for_gid(gid : Int32) : Int32
        @ranges_cid2gid.each do |mapping|
          return mapping.map_value(gid) if mapping.is_in_range(gid)
        end
        super
      end

      def get_gid_for_cid(cid : Int32) : Int32
        @ranges_cid2gid.each do |mapping|
          return mapping.map_reverse_value(cid) if mapping.is_in_reverse_range(cid)
        end
        super
      end
    end
  end
end

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

module Pdfbox::Pdmodel::Font
  # Writes ToUnicode Mapping Files.
  # Corresponds to org.apache.pdfbox.pdmodel.font.ToUnicodeWriter in Apache PDFBox.
  class ToUnicodeWriter
    # To test corner case of PDFBOX-4302.
    MAX_ENTRIES_PER_OPERATOR = 100

    @cid_to_unicode = Hash(Int32, String).new
    @w_mode = 0

    # Creates a new ToUnicode CMap writer.
    def initialize
      @w_mode = 0
    end

    # Sets the WMode (writing mode) of this CMap.
    #
    # @param w_mode 1 for vertical, 0 for horizontal (default)
    def set_w_mode(w_mode : Int32) : Nil
      @w_mode = w_mode
    end

    # Adds the given CID to Unicode mapping.
    #
    # @param cid CID
    # @param text Unicode text, up to 512 bytes.
    def add(cid : Int32, text : String) : Nil
      if cid < 0 || cid > 0xFFFF
        raise ArgumentError.new("CID is not valid")
      end

      if text.nil? || text.empty?
        raise ArgumentError.new("Text is null or empty")
      end

      @cid_to_unicode[cid] = text
    end

    # Writes the CMap as ASCII to the given output stream.
    #
    # @param io ASCII output stream
    # @throws IOException if the stream could not be written
    def write_to(io : ::IO) : Nil
      writer = io

      write_line(writer, "/CIDInit /ProcSet findresource begin")
      write_line(writer, "12 dict begin\n")

      write_line(writer, "begincmap")
      write_line(writer, "/CIDSystemInfo")
      write_line(writer, "<< /Registry (Adobe)")
      write_line(writer, "/Ordering (UCS)")
      write_line(writer, "/Supplement 0")
      write_line(writer, ">> def\n")

      write_line(writer, "/CMapName /Adobe-Identity-UCS def")
      write_line(writer, "/CMapType 2 def\n") # 2 = ToUnicode

      if @w_mode != 0
        write_line(writer, "/WMode /#{@w_mode} def")
      end

      # ToUnicode always uses 16-bit CIDs
      write_line(writer, "1 begincodespacerange")
      write_line(writer, "<0000> <FFFF>")
      write_line(writer, "endcodespacerange\n")

      # CID -> Unicode mappings, we use ranges to generate a smaller CMap
      src_from = [] of Int32
      src_to = [] of Int32
      dst_string = [] of String

      prev = nil

      # Sort entries by CID
      sorted_entries = @cid_to_unicode.to_a.sort_by { |cid, _| cid }

      sorted_entries.each do |cid, text|
        if prev && allow_cid_to_unicode_range(prev, {cid, text})
          # extend range
          src_to[src_to.size - 1] = cid
        else
          # begin range
          src_from << cid
          src_to << cid
          dst_string << text
        end
        prev = {cid, text}
      end

      # limit entries per operator
      batch_count = (src_from.size.to_f / MAX_ENTRIES_PER_OPERATOR).ceil.to_i
      batch_count.times do |batch|
        count = batch == batch_count - 1 ? src_from.size - MAX_ENTRIES_PER_OPERATOR * batch : MAX_ENTRIES_PER_OPERATOR
        writer << count << " beginbfrange\n"
        count.times do |j|
          index = batch * MAX_ENTRIES_PER_OPERATOR + j
          writer << '<' << hex4(src_from[index]) << "> "
          writer << '<' << hex4(src_to[index]) << "> "
          writer << '<' << hex_utf16be(dst_string[index]) << ">\n"
        end
        write_line(writer, "endbfrange\n")
      end

      # footer
      write_line(writer, "endcmap")
      write_line(writer, "CMapName currentdict /CMap defineresource pop")
      write_line(writer, "end")
      write_line(writer, "end")

      writer.flush
    end

    private def write_line(writer : ::IO, text : String) : Nil
      writer << text << '\n'
    end

    # allow_cid_to_unicode_range returns true if the CID and Unicode destination string are allowed to follow one another
    # according to the Adobe 1.7 specification as described in Section 5.9, Example 5.16.
    private def allow_cid_to_unicode_range(prev : Tuple(Int32, String)?, next_entry : Tuple(Int32, String)?) : Bool
      return false if prev.nil? || next_entry.nil?

      prev_cid, prev_text = prev.not_nil!
      next_cid, next_text = next_entry.not_nil!

      allow_code_range(prev_cid, next_cid) && allow_destination_range(prev_text, next_text)
    end

    # allow_code_range returns true if the 16-bit values are sequential and differ only in the low-order byte.
    private def allow_code_range(prev : Int32, next_code : Int32) : Bool
      return false if (prev + 1) != next_code

      prev_h = (prev >> 8) & 0xFF
      prev_l = prev & 0xFF
      next_h = (next_code >> 8) & 0xFF
      next_l = next_code & 0xFF

      prev_h == next_h && prev_l < next_l
    end

    # allow_destination_range returns true if the code points represented by the strings are sequential and differ
    # only in the low-order byte.
    private def allow_destination_range(prev : String, next_str : String) : Bool
      return false if prev.empty? || next_str.empty?

      prev_code = prev.each_char.first.ord
      next_code = next_str.each_char.first.ord

      # Allow the new destination string if:
      # 1. It is sequential with the previous one and differs only in the low-order byte
      # 2. The previous string does not contain any UTF-16 surrogates
      allow_code_range(prev_code, next_code) && prev.size == 1 && prev.each_char.first.ord < 0x10000
    end

    # Convert a 16-bit integer to 4-digit hexadecimal string
    private def hex4(value : Int32) : String
      value.to_s(16).upcase.rjust(4, '0')
    end

    # Convert string to UTF-16BE hexadecimal representation
    private def hex_utf16be(text : String) : String
      result = String.build do |str|
        text.each_char do |char|
          codepoint = char.ord
          if codepoint <= 0xFFFF
            # Basic Multilingual Plane
            str << codepoint.to_s(16).upcase.rjust(4, '0')
          else
            # Supplementary planes - encode as UTF-16 surrogate pair
            high = ((codepoint - 0x10000) >> 10) + 0xD800
            low = ((codepoint - 0x10000) & 0x3FF) + 0xDC00
            str << high.to_s(16).upcase.rjust(4, '0')
            str << low.to_s(16).upcase.rjust(4, '0')
          end
        end
      end
      result
    end
  end
end

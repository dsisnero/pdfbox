module Fontbox
  module CMap
    class CMap
      property wmode : Int32
      property cmap_name : String?
      property cmap_version : String?
      property cmap_type : Int32
      property registry : String?
      property ordering : String?
      property supplement : Int32
      property min_code_length : Int32
      property max_code_length : Int32
      property min_cid_length : Int32
      property max_cid_length : Int32

      property codespace_ranges : Array(CodespaceRange)
      property char_to_unicode_one_byte : Hash(Int32, String)
      property char_to_unicode_two_bytes : Hash(Int32, String)
      property char_to_unicode_more_bytes : Hash(Int32, String)
      property code_to_cid : Hash(Int32, Hash(Int32, Int32))
      property code_to_cid_ranges : Array(CIDRange)
      property unicode_to_byte_codes : Hash(String, Bytes)
      property space_mapping : Int32

      def self.to_int(bytes : Bytes | Array(UInt8)) : Int32
        code = 0
        bytes.each do |byte|
          code <<= 8
          code |= (byte & 0xFF)
        end
        code
      end

      def initialize
        @wmode = 0
        @cmap_name = nil
        @cmap_version = nil
        @cmap_type = -1
        @registry = nil
        @ordering = nil
        @supplement = 0
        @min_code_length = 4
        @max_code_length = 0
        @min_cid_length = 4
        @max_cid_length = 0

        @codespace_ranges = [] of CodespaceRange
        @char_to_unicode_one_byte = {} of Int32 => String
        @char_to_unicode_two_bytes = {} of Int32 => String
        @char_to_unicode_more_bytes = {} of Int32 => String
        @code_to_cid = {} of Int32 => Hash(Int32, Int32)
        @code_to_cid_ranges = [] of CIDRange
        @unicode_to_byte_codes = {} of String => Bytes
        @space_mapping = -1
      end

      def name : String?
        @cmap_name
      end

      def name=(name : String)
        @cmap_name = name
      end

      def wmode : Int32
        @wmode
      end

      def wmode=(wmode : Int32)
        @wmode = wmode
      end

      def version : String?
        @cmap_version
      end

      def version=(version : String)
        @cmap_version = version
      end

      def type : Int32
        @cmap_type
      end

      def type=(type : Int32)
        @cmap_type = type
      end

      def registry : String?
        @registry
      end

      def registry=(registry : String)
        @registry = registry
      end

      def ordering : String?
        @ordering
      end

      def ordering=(ordering : String)
        @ordering = ordering
      end

      def supplement : Int32
        @supplement
      end

      def supplement=(supplement : Int32)
        @supplement = supplement
      end

      def space_mapping : Int32
        @space_mapping
      end

      def has_cid_mappings? : Bool
        !@code_to_cid.empty? || !@code_to_cid_ranges.empty?
      end

      def has_unicode_mappings? : Bool
        !@char_to_unicode_one_byte.empty? || !@char_to_unicode_two_bytes.empty? || !@char_to_unicode_more_bytes.empty?
      end

      def to_unicode(code : Int32, length : Int32) : String?
        case length
        when 1
          @char_to_unicode_one_byte[code]?
        when 2
          @char_to_unicode_two_bytes[code]?
        else
          @char_to_unicode_more_bytes[code]?
        end
      end

      def to_unicode(code : Int32) : String?
        unicode = code < 256 ? to_unicode(code, 1) : nil
        return unicode if unicode
        if code <= 0xFFFF
          to_unicode(code, 2)
        elsif code <= 0xFFFFFF
          to_unicode(code, 3)
        else
          to_unicode(code, 4)
        end
      end

      def to_unicode(bytes : Bytes | Array(UInt8)) : String?
        to_unicode(bytes_to_int(bytes), bytes.size)
      end

      def to_cid(bytes : Bytes | Array(UInt8)) : Int32
        return 0 if !has_cid_mappings? || bytes.size < @min_cid_length || bytes.size > @max_cid_length
        code = bytes_to_int(bytes)
        code_to_cid_map = @code_to_cid[bytes.size]?
        if code_to_cid_map
          cid = code_to_cid_map[code]?
          return cid if cid
        end
        to_cid_from_ranges(bytes)
      end

      def to_cid(code : Int32) : Int32
        return 0 if !has_cid_mappings?
        cid = 0
        length = @min_cid_length
        while cid == 0 && length <= @max_cid_length
          cid = to_cid(code, length)
          length += 1
        end
        cid
      end

      def to_cid(code : Int32, length : Int32) : Int32
        return 0 if !has_cid_mappings? || length < @min_cid_length || length > @max_cid_length
        code_to_cid_map = @code_to_cid[length]?
        if code_to_cid_map
          cid = code_to_cid_map[code]?
          return cid if cid
        end
        to_cid_from_ranges(code, length)
      end

      private def to_cid_from_ranges(bytes : Bytes | Array(UInt8)) : Int32
        @code_to_cid_ranges.each do |range|
          ch = range.map(bytes)
          return ch if ch != -1
        end
        0
      end

      private def to_cid_from_ranges(code : Int32, length : Int32) : Int32
        @code_to_cid_ranges.each do |range|
          ch = range.map(code, length)
          return ch if ch != -1
        end
        0
      end

      def add_char_mapping(bytes : Bytes | Array(UInt8), unicode : String)
        case bytes.size
        when 1
          index = CMapStrings.get_index_value(bytes)
          return unless index
          @char_to_unicode_one_byte[index] = unicode
          @unicode_to_byte_codes[unicode] = CMapStrings.get_byte_value(bytes).not_nil!
        when 2
          index = CMapStrings.get_index_value(bytes)
          return unless index
          @char_to_unicode_two_bytes[index] = unicode
          @unicode_to_byte_codes[unicode] = CMapStrings.get_byte_value(bytes).not_nil!
        when 3, 4
          code = bytes_to_int(bytes)
          @char_to_unicode_more_bytes[code] = unicode
          slice = bytes.is_a?(Array) ? Slice(UInt8).new(bytes.size) { |i| bytes[i] } : bytes
          @unicode_to_byte_codes[unicode] = slice.dup
        else
          # warn "Mappings with more than 4 bytes (here: #{bytes.size}) aren't supported yet"
          return
        end
        # fixme: ugly little hack
        if unicode == " "
          @space_mapping = bytes_to_int(bytes)
        end
      end

      def codes_from_unicode(unicode : String) : Bytes?
        @unicode_to_byte_codes[unicode]?
      end

      def add_cid_mapping(bytes : Bytes | Array(UInt8), cid : Int32)
        length = bytes.size
        code_to_cid_map = @code_to_cid[length]?
        if code_to_cid_map.nil?
          code_to_cid_map = {} of Int32 => Int32
          @code_to_cid[length] = code_to_cid_map
          @min_cid_length = Math.min(@min_cid_length, length)
          @max_cid_length = Math.max(@max_cid_length, length)
        end
        code_to_cid_map[bytes_to_int(bytes)] = cid
      end

      def add_cid_range(from : Bytes | Array(UInt8), to : Bytes | Array(UInt8), cid : Int32)
        add_cid_range_internal(@code_to_cid_ranges, bytes_to_int(from), bytes_to_int(to), cid, from.size)
      end

      private def add_cid_range_internal(cid_ranges : Array(CIDRange), from : Int32, to : Int32, cid : Int32, length : Int32)
        last_range = cid_ranges.last?
        if last_range.nil? || !last_range.extend(from, to, cid, length)
          cid_ranges << CIDRange.new(from, to, cid, length)
          @min_cid_length = Math.min(@min_cid_length, length)
          @max_cid_length = Math.max(@max_cid_length, length)
        end
      end

      def add_codespace_range(range : CodespaceRange)
        @codespace_ranges << range
        code_length = range.code_length
        @max_code_length = Math.max(@max_code_length, code_length)
        @min_code_length = Math.min(@min_code_length, code_length)
      end

      def use_cmap(cmap : CMap)
        cmap.codespace_ranges.each { |range| add_codespace_range(range) }
        @char_to_unicode_one_byte.merge!(cmap.char_to_unicode_one_byte)
        @char_to_unicode_two_bytes.merge!(cmap.char_to_unicode_two_bytes)
        @char_to_unicode_more_bytes.merge!(cmap.char_to_unicode_more_bytes)
        cmap.char_to_unicode_one_byte.each do |k, v|
          @unicode_to_byte_codes[v] = Bytes.new(1) { k.to_u8 }
        end
        cmap.char_to_unicode_two_bytes.each do |k, v|
          @unicode_to_byte_codes[v] = Bytes.new(2) { |i| i == 0 ? (k >> 8).to_u8 : k.to_u8 }
        end
        cmap.char_to_unicode_more_bytes.each do |k, v|
          bytes = if k <= 0xFFFFFF
                    Bytes.new(3) { |i|
                      case i
                      when 0 then (k >> 16).to_u8
                      when 1 then (k >> 8).to_u8
                      else        k.to_u8
                      end
                    }
                  else
                    Bytes.new(4) { |i|
                      case i
                      when 0 then (k >> 24).to_u8
                      when 1 then (k >> 16).to_u8
                      when 2 then (k >> 8).to_u8
                      else        k.to_u8
                      end
                    }
                  end
          @unicode_to_byte_codes[v] = bytes
        end
        cmap.code_to_cid.each do |key, value|
          existing = @code_to_cid[key]?
          if existing
            existing.merge!(value)
          else
            @code_to_cid[key] = value.dup
          end
        end
        @code_to_cid_ranges.concat(cmap.code_to_cid_ranges)
        @max_code_length = Math.max(@max_code_length, cmap.max_code_length)
        @min_code_length = Math.min(@min_code_length, cmap.min_code_length)
        @max_cid_length = Math.max(@max_cid_length, cmap.max_cid_length)
        @min_cid_length = Math.min(@min_cid_length, cmap.min_cid_length)
      end

      private def bytes_to_int(bytes : Bytes | Array(UInt8)) : Int32
        self.class.to_int(bytes)
      end

      def to_s : String
        @cmap_name || "CMap"
      end
    end
  end
end

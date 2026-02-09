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

      def add_char_mapping(bytes : Bytes | Array(UInt8), unicode : String)
        code = bytes_to_int(bytes)
        case bytes.size
        when 1
          @char_to_unicode_one_byte[code] = unicode
        when 2
          @char_to_unicode_two_bytes[code] = unicode
        else
          @char_to_unicode_more_bytes[code] = unicode
        end
        # Also store reverse mapping
        slice = bytes.is_a?(Array) ? Slice(UInt8).new(bytes.size) { |i| bytes[i] } : bytes
        @unicode_to_byte_codes[unicode] = slice.dup
      end

      def to_unicode(bytes : Bytes | Array(UInt8)) : String?
        code = bytes_to_int(bytes)
        case bytes.size
        when 1
          @char_to_unicode_one_byte[code]?
        when 2
          @char_to_unicode_two_bytes[code]?
        else
          @char_to_unicode_more_bytes[code]?
        end
      end

      private def bytes_to_int(bytes : Bytes | Array(UInt8)) : Int32
        self.class.to_int(bytes)
      end
    end
  end
end
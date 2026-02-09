module Fontbox
  module CMap
    class CMapStrings
      private ONE_BYTE_MAPPINGS = Array(String).new(256)
      private TWO_BYTE_MAPPINGS = Array(String).new(256 * 256)

      private INDEX_VALUES = Array(Int32).new(256 * 256)
      private ONE_BYTE_VALUES = Array(Bytes).new(256)
      private TWO_BYTE_VALUES = Array(Bytes).new(256 * 256)

      private REPLACEMENT_CHAR = '\uFFFD'

      private def self.fill_mappings
        # Two-byte mappings
        (0...256).each do |i|
          (0...256).each do |j|
            bytes = Slice(UInt8).new(2) { |k| k == 0 ? i.to_u8 : j.to_u8 }
            codepoint = (i << 8) | j
            # Check if codepoint is a valid Unicode scalar value (not a surrogate)
            if (codepoint >= 0xD800 && codepoint <= 0xDFFF) || codepoint > 0x10FFFF
              TWO_BYTE_MAPPINGS << REPLACEMENT_CHAR.to_s
            else
              TWO_BYTE_MAPPINGS << codepoint.chr.to_s
            end
            TWO_BYTE_VALUES << bytes
            INDEX_VALUES << codepoint
          end
        end
        # One-byte mappings
        (0...256).each do |i|
          bytes = Slice(UInt8).new(1) { i.to_u8 }
          ONE_BYTE_MAPPINGS << i.chr.to_s
          ONE_BYTE_VALUES << bytes
        end
      end

      fill_mappings

      private def self.to_int(bytes : Bytes | Array(UInt8)) : Int32
        code = 0
        bytes.each do |byte|
          code <<= 8
          code |= (byte & 0xFF)
        end
        code
      end

      def self.get_mapping(bytes : Bytes | Array(UInt8)) : String?
        return nil if bytes.size > 2
        if bytes.size == 1
          ONE_BYTE_MAPPINGS[to_int(bytes)]
        else
          TWO_BYTE_MAPPINGS[to_int(bytes)]
        end
      end

      def self.get_index_value(bytes : Bytes | Array(UInt8)) : Int32?
        return nil if bytes.size > 2
        INDEX_VALUES[to_int(bytes)]
      end

      def self.get_byte_value(bytes : Bytes | Array(UInt8)) : Bytes?
        return nil if bytes.size > 2
        if bytes.size == 1
          ONE_BYTE_VALUES[to_int(bytes)]
        else
          TWO_BYTE_VALUES[to_int(bytes)]
        end
      end
    end
  end
end
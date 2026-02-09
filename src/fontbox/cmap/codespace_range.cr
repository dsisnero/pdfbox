module Fontbox
  module CMap
    class CodespaceRange
      property start : Array(Int32)
      property range_end : Array(Int32)
      property code_length : Int32

      def initialize(start_bytes : Array(UInt8) | Bytes, end_bytes : Array(UInt8) | Bytes)
        corrected_start_bytes = start_bytes
        if start_bytes.size != end_bytes.size && start_bytes.size == 1 && start_bytes[0] == 0
          corrected_start_bytes = Array(UInt8).new(end_bytes.size, 0_u8)
        elsif start_bytes.size != end_bytes.size
          raise ArgumentError.new("The start and the end values must not have different lengths.")
        end

        length = end_bytes.size
        @start = Array.new(length) { |i| (corrected_start_bytes[i] & 0xFF).to_i32 }
        @range_end = Array.new(length) { |i| (end_bytes[i] & 0xFF).to_i32 }
        @code_length = length
      end

      def matches(code : Array(UInt8) | Bytes) : Bool
        is_full_match(code, code.size)
      end

      def is_full_match(code : Array(UInt8) | Bytes, code_len : Int32) : Bool
        return false if @code_length != code_len

        (0...@code_length).each do |i|
          code_as_int = code[i] & 0xFF
          return false if code_as_int < @start[i] || code_as_int > @range_end[i]
        end
        true
      end
    end
  end
end

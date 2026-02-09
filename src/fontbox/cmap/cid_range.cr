module Fontbox
  module CMap
    class CIDRange
      property from : Int32
      property to : Int32
      property unicode : Int32
      property code_length : Int32

      def initialize(@from : Int32, @to : Int32, @unicode : Int32, @code_length : Int32)
      end

      def map(bytes : Bytes | Array(UInt8)) : Int32
        if bytes.size == code_length
          ch = bytes_to_int(bytes)
          if from <= ch && ch <= to
            return unicode + (ch - from)
          end
        end
        -1
      end

      def map(code : Int32, length : Int32) : Int32
        if length == code_length && from <= code && code <= to
          return unicode + (code - from)
        end
        -1
      end

      def unmap(code : Int32) : Int32
        if unicode <= code && code <= unicode + (to - from)
          return from + (code - unicode)
        end
        -1
      end

      def extend(new_from : Int32, new_to : Int32, new_cid : Int32, length : Int32) : Bool
        if code_length == length && (new_from == to + 1) && (new_cid == unicode + to - from + 1)
          @to = new_to
          return true
        end
        false
      end

      private def bytes_to_int(bytes : Bytes | Array(UInt8)) : Int32
        code = 0
        bytes.each do |byte|
          code <<= 8
          code |= (byte & 0xFF)
        end
        code
      end
    end
  end
end

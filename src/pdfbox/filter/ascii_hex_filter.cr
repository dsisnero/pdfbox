require "log"

module Pdfbox::Filter
  # Decodes data encoded in ASCII hexadecimal form, reproducing the original
  # binary data. Java: org.apache.pdfbox.filter.ASCIIHexFilter
  class ASCIIHexFilter < Filter
    Log = ::Log.for(self)

    # Reverse lookup: ASCII character -> hex value (or -1 if not a hex digit).
    private REVERSE_HEX = begin
      arr = Array.new(256, -1)
      arr['0'.ord] = 0
      arr['1'.ord] = 1
      arr['2'.ord] = 2
      arr['3'.ord] = 3
      arr['4'.ord] = 4
      arr['5'.ord] = 5
      arr['6'.ord] = 6
      arr['7'.ord] = 7
      arr['8'.ord] = 8
      arr['9'.ord] = 9
      arr['A'.ord] = 10
      arr['B'.ord] = 11
      arr['C'.ord] = 12
      arr['D'.ord] = 13
      arr['E'.ord] = 14
      arr['F'.ord] = 15
      arr['a'.ord] = 10
      arr['b'.ord] = 11
      arr['c'.ord] = 12
      arr['d'.ord] = 13
      arr['e'.ord] = 14
      arr['f'.ord] = 15
      arr
    end

    def decode(encoded : Bytes) : Bytes
      output = ::IO::Memory.new
      index = 0
      while index < encoded.size
        first_byte = encoded[index].to_i
        index += 1

        # always after first char
        while whitespace?(first_byte)
          break if index >= encoded.size
          first_byte = encoded[index].to_i
          index += 1
        end

        if first_byte == -1 || eod?(first_byte)
          break
        end

        if REVERSE_HEX[first_byte] == -1
          Log.error { "Invalid hex, int: #{first_byte} char: #{first_byte.chr}" }
        end
        value = REVERSE_HEX[first_byte] * 16

        second_byte = if index < encoded.size
                        encoded[index].to_i
                      else
                        -1
                      end
        index += 1 if index < encoded.size

        if second_byte == -1 || eod?(second_byte)
          # second value behaves like 0 in case of EOD
          output.write_byte(value.to_u8)
          break
        end
        if REVERSE_HEX[second_byte] == -1
          Log.error { "Invalid hex, int: #{second_byte} char: #{second_byte.chr}" }
        end
        value += REVERSE_HEX[second_byte]
        output.write_byte(value.to_u8)
      end
      output.to_slice
    end

    def encode(input : Bytes) : Bytes
      Pdfbox::Util::Hex.get_bytes(input)
    end

    # Whitespace: NUL, tab, LF, FF, CR, space
    private def whitespace?(c : Int32) : Bool
      case c
      when 0, 9, 10, 12, 13, 32
        true
      else
        false
      end
    end

    private def eod?(c : Int32) : Bool
      c == '>'.ord
    end
  end
end

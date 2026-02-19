module Pdfbox::Filter
  class ASCII85Filter < Filter
    def encode(input : Bytes) : Bytes
      encoded = ::String.build do |io|
        index = 0
        while index + 4 <= input.size
          value = (input[index].to_u32 << 24) |
                  (input[index + 1].to_u32 << 16) |
                  (input[index + 2].to_u32 << 8) |
                  input[index + 3].to_u32
          if value == 0
            io << 'z'
          else
            chunk = StaticArray(UInt8, 5).new(0_u8)
            4.downto(0) do |position|
              chunk[position] = (value % 85 + 33).to_u8
              value //= 85
            end
            5.times { |i| io.write_byte(chunk[i]) }
          end
          index += 4
        end

        remaining = input.size - index
        if remaining > 0
          value = 0_u32
          4.times do |offset|
            value <<= 8
            value |= input[index + offset].to_u32 if offset < remaining
          end

          chunk = StaticArray(UInt8, 5).new(0_u8)
          4.downto(0) do |position|
            chunk[position] = (value % 85 + 33).to_u8
            value //= 85
          end
          (remaining + 1).times { |i| io.write_byte(chunk[i]) }
        end

        io << '~' << '>'
      end
      encoded.to_slice
    end

    def decode(encoded : Bytes) : Bytes
      output = [] of UInt8
      tuple = [] of UInt32
      index = 0

      while index < encoded.size
        char = encoded[index].chr
        index += 1

        next if char.whitespace?

        if char == 'z'
          raise Pdfbox::Error.new("Invalid ASCII85 'z' inside tuple") unless tuple.empty?
          output.concat([0_u8, 0_u8, 0_u8, 0_u8])
          next
        end

        break if char == '~'

        unless char >= '!' && char <= 'u'
          raise Pdfbox::Error.new("Invalid ASCII85 character: #{char.inspect}")
        end

        tuple << (char.ord - 33).to_u32
        next unless tuple.size == 5

        value = 0_u32
        tuple.each { |digit| value = value * 85 + digit }
        output << ((value >> 24) & 0xFF).to_u8
        output << ((value >> 16) & 0xFF).to_u8
        output << ((value >> 8) & 0xFF).to_u8
        output << (value & 0xFF).to_u8
        tuple.clear
      end

      unless tuple.empty?
        tuple_length = tuple.size
        raise Pdfbox::Error.new("Invalid ASCII85 tuple length") if tuple_length == 1
        while tuple.size < 5
          tuple << 84_u32
        end
        value = 0_u32
        tuple.each { |digit| value = value * 85 + digit }
        decoded = StaticArray(UInt8, 4).new(0_u8)
        decoded[0] = ((value >> 24) & 0xFF).to_u8
        decoded[1] = ((value >> 16) & 0xFF).to_u8
        decoded[2] = ((value >> 8) & 0xFF).to_u8
        decoded[3] = (value & 0xFF).to_u8
        (tuple_length - 1).times { |i| output << decoded[i] }
      end

      Bytes.new(output.size) { |i| output[i] }
    end
  end
end

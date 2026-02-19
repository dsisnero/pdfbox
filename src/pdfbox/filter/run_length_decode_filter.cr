module Pdfbox::Filter
  class RunLengthDecodeFilter < Filter
    RUN_LENGTH_EOD = 128_u8

    def decode(encoded : Bytes) : Bytes
      input = ::IO::Memory.new(encoded)
      output = ::IO::Memory.new
      decode(input, output)
      output.to_slice
    end

    def encode(input : Bytes) : Bytes
      source = ::IO::Memory.new(input)
      encoded = ::IO::Memory.new
      encode(source, encoded)
      encoded.to_slice
    end

    def decode(encoded : ::IO, decoded : ::IO) : Nil
      buffer = Bytes.new(128)

      while dup_amount = encoded.read_byte
        break if dup_amount == RUN_LENGTH_EOD

        if dup_amount <= 127
          amount_to_copy = dup_amount.to_i + 1
          while amount_to_copy > 0
            compressed_read = encoded.read(buffer[0, amount_to_copy])
            break if compressed_read == 0
            decoded.write(buffer[0, compressed_read])
            amount_to_copy -= compressed_read
          end
        else
          dup_byte = encoded.read_byte
          break unless dup_byte
          (257 - dup_amount.to_i).times { decoded.write_byte(dup_byte) }
        end
      end
    end

    # Not used in PDFBox except for testing the decoder.
    def encode(input : ::IO, encoded : ::IO) : Nil
      last_val = -1
      count = 0
      equality = false
      buf = Bytes.new(128)

      while byt = input.read_byte
        byte_value = byt.to_i

        if last_val == -1
          last_val = byte_value
          count = 1
        elsif count == 128
          if equality
            encoded.write_byte(129_u8) # 257 - 128
            encoded.write_byte(last_val.to_u8)
          else
            encoded.write_byte(127_u8)
            encoded.write(buf[0, 128])
          end
          equality = false
          last_val = byte_value
          count = 1
        elsif count == 1
          if byte_value == last_val
            equality = true
          else
            buf[0] = last_val.to_u8
            buf[1] = byte_value.to_u8
            last_val = byte_value
          end
          count = 2
        elsif byte_value == last_val
          if equality
            count += 1
          else
            encoded.write_byte((count - 2).to_u8)
            encoded.write(buf[0, count - 1])
            count = 2
            equality = true
          end
        else
          if equality
            encoded.write_byte((257 - count).to_u8)
            encoded.write_byte(last_val.to_u8)
            equality = false
            count = 1
          else
            buf[count] = byte_value.to_u8
            count += 1
          end
          last_val = byte_value
        end
      end

      if count > 0
        if count == 1
          encoded.write_byte(0_u8)
          encoded.write_byte(last_val.to_u8)
        elsif equality
          encoded.write_byte((257 - count).to_u8)
          encoded.write_byte(last_val.to_u8)
        else
          encoded.write_byte((count - 1).to_u8)
          encoded.write(buf[0, count])
        end
      end
      encoded.write_byte(RUN_LENGTH_EOD)
    end
  end
end

module Pdfbox::Filter
  module Predictor
    # Number of bytes in a single row (Java Predictor#calculateRowLength).
    def self.calculate_row_length(colors : Int32, bits_per_component : Int32, columns : Int32) : Int32
      bits_per_pixel = colors * bits_per_component
      (columns * bits_per_pixel + 7) // 8
    end

    # Applies the predictor given by decode_params to already-inflated data.
    # Java Predictor#wrapPredictor + PredictorOutputStream.
    def self.decode_data(data : Bytes, decode_params : Pdfbox::Cos::Dictionary?) : Bytes
      return data unless decode_params

      predictor = decode_params.get_int(Pdfbox::Cos::Name.new("Predictor"), 1_i64).to_i
      return data if predictor <= 1

      colors = Math.min(decode_params.get_int(Pdfbox::Cos::Name.new("Colors"), 1_i64).to_i, 32)
      bits_per_component = decode_params.get_int(Pdfbox::Cos::Name.new("BitsPerComponent"), 8_i64).to_i
      columns = decode_params.get_int(Pdfbox::Cos::Name.new("Columns"), 1_i64).to_i

      apply(data, predictor, colors, bits_per_component, columns)
    end

    private def self.apply(data : Bytes, predictor : Int32, colors : Int32, bits_per_component : Int32,
                           columns : Int32) : Bytes
      row_length = calculate_row_length(colors, bits_per_component, columns)
      raise ::IO::Error.new("Calculated row length is negative: #{row_length}") if row_length < 0

      predictor_per_row = predictor >= 10
      current_row = Bytes.new(row_length)
      last_row = Bytes.new(row_length)
      output = ::IO::Memory.new
      current_row_data = 0
      predictor_read = false
      current = predictor

      offset = 0
      while offset < data.size
        if predictor_per_row && current_row_data == 0 && !predictor_read
          current = data[offset].to_i + 10
          offset += 1
          predictor_read = true
        else
          to_read = Math.min(row_length - current_row_data, data.size - offset)
          current_row[current_row_data, to_read].copy_from(data[offset, to_read])
          current_row_data += to_read
          offset += to_read

          if current_row_data == row_length
            decode_predictor_row(current, colors, bits_per_component, columns, current_row, last_row)
            output.write(current_row)
            temp = last_row
            last_row = current_row
            current_row = temp
            current_row_data = 0
            predictor_read = false
          end
        end
      end

      # The last row is allowed to be incomplete and is completed with zeros.
      if current_row_data > 0
        (current_row_data...row_length).each { |i| current_row[i] = 0_u8 }
        decode_predictor_row(current, colors, bits_per_component, columns, current_row, last_row)
        output.write(current_row)
      end

      output.to_slice
    end

    # Decodes a single line of data in-place (Java Predictor#decodePredictorRow).
    def self.decode_predictor_row(predictor : Int32, colors : Int32, bits_per_component : Int32,
                                  columns : Int32, actline : Bytes, lastline : Bytes) : Nil
      return if predictor == 1

      bits_per_pixel = colors * bits_per_component
      bytes_per_pixel = (bits_per_pixel + 7) // 8
      row_length = actline.size

      case predictor
      when 2
        decode_tiff_sub(colors, bits_per_component, columns, bytes_per_pixel, row_length, actline)
      when 10
        # PRED NONE
      when 11
        # PRED SUB
        index = bytes_per_pixel
        while index < row_length
          sub = actline[index]
          left = actline[index - bytes_per_pixel]
          actline[index] = (sub + left).to_u8!
          index += 1
        end
      when 12
        # PRED UP
        (0...row_length).each do |index|
          actline[index] = (actline[index] + lastline[index]).to_u8!
        end
      when 13
        # PRED AVG
        (0...row_length).each do |index|
          left = index - bytes_per_pixel >= 0 ? actline[index - bytes_per_pixel] : 0_u8
          up = lastline[index]
          actline[index] = (actline[index] + ((left.to_i32 + up.to_i32) // 2)).to_u8!
        end
      when 14
        # PRED PAETH
        (0...row_length).each do |index|
          a = index - bytes_per_pixel >= 0 ? actline[index - bytes_per_pixel].to_i32 : 0
          b = lastline[index].to_i32
          c = index - bytes_per_pixel >= 0 ? lastline[index - bytes_per_pixel].to_i32 : 0
          value = a + b - c
          absa = (value - a).abs
          absb = (value - b).abs
          absc = (value - c).abs
          predictor_value = if absa <= absb && absa <= absc
                              a
                            elsif absb <= absc
                              b
                            else
                              c
                            end
          actline[index] = (actline[index] + predictor_value).to_u8!
        end
      end
    end

    private def self.decode_tiff_sub(colors : Int32, bits_per_component : Int32, columns : Int32,
                                     bytes_per_pixel : Int32, row_length : Int32, actline : Bytes) : Nil
      if bits_per_component == 8
        index = bytes_per_pixel
        while index < row_length
          actline[index] = (actline[index] + actline[index - bytes_per_pixel]).to_u8!
          index += 1
        end
        return
      end

      if bits_per_component == 16
        index = bytes_per_pixel
        while index < row_length - 1
          sub = ((actline[index] & 0xff).to_i32 << 8) + (actline[index + 1] & 0xff).to_i32
          left = ((actline[index - bytes_per_pixel] & 0xff).to_i32 << 8) +
                 (actline[index - bytes_per_pixel + 1] & 0xff).to_i32
          sum = sub + left
          actline[index] = ((sum >> 8) & 0xff).to_u8
          actline[index + 1] = (sum & 0xff).to_u8
          index += 2
        end
        return
      end

      if bits_per_component == 1 && colors == 1
        (0...row_length).each do |byte_index|
          7.downto(0) do |bit|
            next if byte_index == 0 && bit == 7
            sub = (actline[byte_index] >> bit) & 1
            left = bit == 7 ? (actline[byte_index - 1] & 1) : ((actline[byte_index] >> (bit + 1)) & 1)
            if ((sub + left) & 1) == 0
              actline[byte_index] &= ~(1_u8 << bit)
            else
              actline[byte_index] |= (1_u8 << bit)
            end
          end
        end
        return
      end

      elements = columns * colors
      p = colors
      while p < elements
        byte_pos_sub = p * bits_per_component // 8
        bit_pos_sub = 8 - p * bits_per_component % 8 - bits_per_component
        byte_pos_left = (p - colors) * bits_per_component // 8
        bit_pos_left = 8 - (p - colors) * bits_per_component % 8 - bits_per_component

        sub = get_bit_seq(actline[byte_pos_sub], bit_pos_sub, bits_per_component)
        left = get_bit_seq(actline[byte_pos_left], bit_pos_left, bits_per_component)
        actline[byte_pos_sub] = calc_set_bit_seq(actline[byte_pos_sub], bit_pos_sub, bits_per_component, sub + left).to_u8
        p += 1
      end
    end

    # Get value from bit interval from a byte-sized integer.
    # Mirrors org.apache.pdfbox.filter.Predictor#getBitSeq.
    def self.get_bit_seq(by : Int, start_bit : Int, bit_size : Int) : Int32
      mask = (1_u32 << bit_size) - 1_u32
      ((by.to_u32 >> start_bit) & mask).to_i32
    end

    # Set value in a bit interval and return the resulting byte-sized integer.
    # Mirrors org.apache.pdfbox.filter.Predictor#calcSetBitSeq.
    def self.calc_set_bit_seq(by : Int, start_bit : Int, bit_size : Int, val : Int) : Int32
      mask = (1_u32 << bit_size) - 1_u32
      truncated_val = val.to_u32 & mask
      clear_mask = ~(mask << start_bit)
      ((by.to_u32 & clear_mask) | (truncated_val << start_bit)).to_i32
    end
  end
end

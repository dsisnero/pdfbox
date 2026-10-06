require "../../../filter"

module Pdfbox::Pdmodel::Graphics::Image
  # Factory for creating a PDImageXObject containing a lossless compressed image.
  # Java: org.apache.pdfbox.pdmodel.graphics.image.LosslessFactory
  class LosslessFactory
    def self.create_from_image(document : Pdfbox::Pdmodel::Document, image : CrImage::Image) : PDImageXObject
      if gray_image?(image)
        return create_from_gray_image(image, document)
      end

      predictor = PredictorEncoder.new(document, image).encode
      if predictor
        if predictor.color_space == Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE &&
           predictor.bits_per_component < 16 &&
           image.bounds.width * image.bounds.height <= 50 * 50
          # also create classic compressed image, compare sizes
          classic = create_from_rgb_image(image, document)
          if stream_data_size(classic) < stream_data_size(predictor)
            return classic
          end
        end
        return predictor
      end

      # Fallback: export as 8-bit sRGB
      create_from_rgb_image(image, document)
    end

    def self.gray_image?(image : CrImage::Image) : Bool
      image.is_a?(CrImage::Gray) || image.is_a?(CrImage::Gray16)
    end

    # Grayscale images need one color per sample.
    # Java: LosslessFactory.createFromGrayImage
    private def self.create_from_gray_image(image : CrImage::Image, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      height = image.bounds.height
      width = image.bounds.width
      bpc = image.is_a?(CrImage::Gray16) ? 16 : 8

      # Extract one byte per sample (top-to-bottom, left-to-right)
      bytes_per_sample = bpc == 16 ? 2 : 1
      data = Bytes.new(width * height * bytes_per_sample)
      idx = 0
      0.upto(height - 1) do |y|
        0.upto(width - 1) do |x|
          color = image.at(x, y)
          r, _g, _b, _a = color.rgba
          if bpc == 16
            data[idx] = (r >> 8).to_u8
            data[idx + 1] = (r & 0xFF).to_u8
            idx += 2
          else
            data[idx] = (r >> 8).to_u8
            idx += 1
          end
        end
      end

      prepare_image_x_object(document, data, width, height, bpc, Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
    end

    # Java: LosslessFactory.createFromRGBImage
    private def self.create_from_rgb_image(image : CrImage::Image, document : Pdfbox::Pdmodel::Document) : PDImageXObject
      height = image.bounds.height
      width = image.bounds.width
      bpc = 8
      image_data = Bytes.new(width * height * 3)

      has_alpha = has_transparency?(image)
      apbc = has_alpha ? (binary_alpha?(image) ? 1 : 8) : 1
      alpha_image_data = Bytes.new((((width * apbc / 8) + (width * apbc % 8 != 0 ? 1 : 0)) * height).to_i)

      byte_idx = 0
      alpha_byte_idx = 0
      alpha_bit_pos = 7

      0.upto(height - 1) do |y|
        0.upto(width - 1) do |x|
          color = image.at(x, y)
          r, g, b, a = color.rgba
          image_data[byte_idx] = (r >> 8).to_u8
          image_data[byte_idx + 1] = (g >> 8).to_u8
          image_data[byte_idx + 2] = (b >> 8).to_u8
          byte_idx += 3

          if has_alpha
            if apbc == 1
              # write a bit (binary alpha: opaque => 1, transparent => 0)
              alpha_image_data[alpha_byte_idx] |= ((a >> 8) & 1) << alpha_bit_pos
              if (alpha_bit_pos -= 1) < 0
                alpha_bit_pos = 7
                alpha_byte_idx += 1
              end
            else
              alpha_image_data[alpha_byte_idx] = (a >> 8).to_u8
              alpha_byte_idx += 1
            end
          end
        end
        if apbc == 1 && alpha_bit_pos != 7
          alpha_bit_pos = 7
          alpha_byte_idx += 1
        end
      end

      pd_image = prepare_image_x_object(document, image_data, width, height, bpc, Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
      if has_alpha
        pd_mask = prepare_image_x_object(document, alpha_image_data, width, height, apbc, Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
        pd_image.cos_object[Pdfbox::Cos::Name.new("SMask")] = pd_mask.cos_object
      end
      pd_image
    end

    # Detect whether any pixel is not fully opaque.
    def self.has_transparency?(image : CrImage::Image) : Bool
      0.upto(image.bounds.height - 1) do |y|
        0.upto(image.bounds.width - 1) do |x|
          _r, _g, _b, a = image.at(x, y).rgba
          return true if a < 0xFFFF
        end
      end
      false
    end

    # Detect BITMASK transparency: every alpha is either fully opaque or fully
    # transparent (binary), mirroring java.awt.Transparency.BITMASK.
    def self.binary_alpha?(image : CrImage::Image) : Bool
      0.upto(image.bounds.height - 1) do |y|
        0.upto(image.bounds.width - 1) do |x|
          _r, _g, _b, a = image.at(x, y).rgba
          return false unless a == 0 || a == 0xFFFF
        end
      end
      true
    end

    # Size in bytes of the compressed image stream.
    private def self.stream_data_size(image : PDImageXObject) : Int32
      if stream = image.cos_object.as?(Pdfbox::Cos::Stream)
        stream.data.size
      else
        0
      end
    end

    # Create a PDImageXObject using the Flate filter.
    # Java: LosslessFactory.prepareImageXObject
    def self.prepare_image_x_object(document : Pdfbox::Pdmodel::Document, byte_array : Bytes, width : Int32, height : Int32, bits_per_component : Int32, init_color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace) : PDImageXObject
      encoded = Pdfbox::Filter::FlateFilter.new.encode(byte_array)

      stream = Pdfbox::Cos::Stream.new(entries: {} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, data: encoded)
      stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("FlateDecode")
      stream[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(width)
      stream[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(height)
      stream[Pdfbox::Cos::Name.new("BitsPerComponent")] = Pdfbox::Cos::Integer.new(bits_per_component)
      stream[Pdfbox::Cos::Name.new("ColorSpace")] = init_color_space.cos_object

      PDImageXObject.new(document, stream, stream)
    end

    # PNG predictor encoder producing PNG-predictor-15 + Flate encoded data.
    # Java: LosslessFactory.PredictorEncoder
    private class PredictorEncoder
      @document : Pdfbox::Pdmodel::Document
      @image : CrImage::Image
      @bytes_per_pixel : Int32
      @height : Int32
      @width : Int32

      def initialize(@document, @image)
        @bytes_per_pixel = 3
        @height = @image.bounds.height
        @width = @image.bounds.width
      end

      def encode : PDImageXObject?
        # only 8-bit RGB / RGBA is supported by this port
        unless @image.is_a?(CrImage::RGBA) || @image.is_a?(CrImage::NRGBA)
          return nil
        end

        # BITMASK transparency (binary alpha) is not handled by the predictor;
        # fall back to createFromRGBImage which uses a 1-bit soft mask.
        return nil if LosslessFactory.has_transparency?(@image) && LosslessFactory.binary_alpha?(@image)

        row_byte_count = @width * @bytes_per_pixel + 1
        data_raw_row_none = Bytes.new(row_byte_count)
        data_raw_row_sub = Bytes.new(row_byte_count)
        data_raw_row_up = Bytes.new(row_byte_count)
        data_raw_row_average = Bytes.new(row_byte_count)
        data_raw_row_paeth = Bytes.new(row_byte_count)

        a_values = Bytes.new(@bytes_per_pixel)
        c_values = Bytes.new(@bytes_per_pixel)
        b_values = Bytes.new(@bytes_per_pixel)
        x_values = Bytes.new(@bytes_per_pixel)

        alpha_image_data = Bytes.new(@width * @height)
        has_alpha = LosslessFactory.has_transparency?(@image)

        # write the encoding markers
        data_raw_row_none[0] = 0_u8
        data_raw_row_sub[0] = 1_u8
        data_raw_row_up[0] = 2_u8
        data_raw_row_average[0] = 3_u8
        data_raw_row_paeth[0] = 4_u8

        raw_stream = ::IO::Memory.new

        prev_row = Bytes.new(@width * @bytes_per_pixel)
        transfer_row = Bytes.new(@width * @bytes_per_pixel)

        0.upto(@height - 1) do |row_num|
          a_values.fill(0_u8)
          c_values.fill(0_u8)

          # fill transfer row for this image row
          0.upto(@width - 1) do |x|
            color = @image.at(x, row_num)
            r, g, b, a = color.rgba
            base = x * @bytes_per_pixel
            transfer_row[base] = (r >> 8).to_u8
            transfer_row[base + 1] = (g >> 8).to_u8
            transfer_row[base + 2] = (b >> 8).to_u8
            if has_alpha
              alpha_image_data[row_num * @width + x] = (a >> 8).to_u8
            end
          end

          writer_ptr = 1
          0.upto(@width - 1) do |x|
            base = x * @bytes_per_pixel
            b_values[0] = prev_row[base]
            b_values[1] = prev_row[base + 1]
            b_values[2] = prev_row[base + 2]

            # x_values must mirror transfer_row bytes for the current pixel
            x_values[0] = transfer_row[base]
            x_values[1] = transfer_row[base + 1]
            x_values[2] = transfer_row[base + 2]

            @bytes_per_pixel.times do |byte_ptr|
              xv = x_values[byte_ptr]
              av = a_values[byte_ptr]
              bv = b_values[byte_ptr]
              cv = c_values[byte_ptr]
              data_raw_row_none[writer_ptr] = xv
              data_raw_row_sub[writer_ptr] = (xv.to_i16 - av.to_i16).to_u8!
              data_raw_row_up[writer_ptr] = (xv.to_i16 - bv.to_i16).to_u8!
              data_raw_row_average[writer_ptr] = (xv.to_i16 - ((bv.to_i16 + av.to_i16) / 2)).to_u8!
              data_raw_row_paeth[writer_ptr] = png_filter_paeth(xv, av, bv, cv)
              writer_ptr += 1
            end

            # shift values into prev/upper-left for next pixel
            @bytes_per_pixel.times do |i|
              a_values[i] = x_values[i]
              c_values[i] = b_values[i]
            end
          end

          row_to_write = choose_data_row_to_write(data_raw_row_none, data_raw_row_sub, data_raw_row_up, data_raw_row_average, data_raw_row_paeth)
          raw_stream.write(row_to_write)

          # swap prev and transfer rows
          temp = prev_row
          prev_row = transfer_row
          transfer_row = temp
        end

        encoded = Pdfbox::Filter::FlateFilter.new.encode(raw_stream.to_slice)

        stream = Pdfbox::Cos::Stream.new(entries: {} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, data: encoded)
        stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("FlateDecode")
        stream[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(@width)
        stream[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(@height)
        stream[Pdfbox::Cos::Name.new("BitsPerComponent")] = Pdfbox::Cos::Integer.new(8)
        stream[Pdfbox::Cos::Name.new("ColorSpace")] = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE.cos_object

        decode_parms = Pdfbox::Cos::Dictionary.new
        decode_parms[Pdfbox::Cos::Name.new("BitsPerComponent")] = Pdfbox::Cos::Integer.new(8)
        decode_parms[Pdfbox::Cos::Name.new("Predictor")] = Pdfbox::Cos::Integer.new(15)
        decode_parms[Pdfbox::Cos::Name.new("Columns")] = Pdfbox::Cos::Integer.new(@width)
        decode_parms[Pdfbox::Cos::Name.new("Colors")] = Pdfbox::Cos::Integer.new(3)
        stream[Pdfbox::Cos::Name.new("DecodeParms")] = decode_parms

        image_x_object = PDImageXObject.new(@document, stream, stream)

        if has_alpha
          pd_mask = LosslessFactory.prepare_image_x_object(@document, alpha_image_data, @width, @height, 8, Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
          image_x_object.cos_object[Pdfbox::Cos::Name.new("SMask")] = pd_mask.cos_object
        end

        image_x_object
      end

      private def choose_data_row_to_write(none, sub, up, average, paeth) : Bytes
        row_to_write = none
        est = est_compress_sum(none)
        est_sub = est_compress_sum(sub)
        est_up = est_compress_sum(up)
        est_avg = est_compress_sum(average)
        est_paeth = est_compress_sum(paeth)
        if est > est_sub
          row_to_write = sub
          est = est_sub
        end
        if est > est_up
          row_to_write = up
          est = est_up
        end
        if est > est_avg
          row_to_write = average
          est = est_avg
        end
        if est > est_paeth
          row_to_write = paeth
        end
        row_to_write
      end

      private def est_compress_sum(row : Bytes) : Int64
        sum = 0_i64
        row.each do |byte|
          v = byte.to_i16
          sum += v.abs
        end
        sum
      end

      private def png_filter_paeth(x : UInt8, a : UInt8, b : UInt8, c : UInt8) : UInt8
        p = a.to_i32 + b.to_i32 - c.to_i32
        pa = (p - a.to_i32).abs
        pb = (p - b.to_i32).abs
        pc = (p - c.to_i32).abs
        pr = if pa <= pb && pa <= pc
               a
             elsif pb <= pc
               b
             else
               c
             end
        (x.to_i32 - pr.to_i32).to_u8!
      end
    end
  end
end

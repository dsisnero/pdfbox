require "log"

module Pdfbox::Filter
  # Decompresses data encoded using a DCT (discrete cosine transform) technique
  # based on the JPEG standard. The Crystal port decodes via CrImage and emits
  # raw RGB raster bytes. Java: org.apache.pdfbox.filter.DCTFilter
  class DCTFilter < Filter
    Log = ::Log.for(self)

    # Offset of the colour transform byte within the APP14 Adobe segment data.
    POS_TRANSFORM = 11
    ADOBE         = "Adobe"

    # Scans the JPEG byte stream for the APP14 Adobe marker and returns its
    # colour-transform value, or 0 if unknown. Port of DCTFilter
    # #getAdobeTransformByBruteForce (Java reads via ImageInputStream).
    def get_adobe_transform_by_brute_force(bytes : Bytes) : Int32
      a = 0
      i = 0
      size = bytes.size
      while i < size
        by = bytes[i].to_i
        i += 1
        if ADOBE[a].ord == by
          a += 1
          next unless a == ADOBE.size

          # match: `i` now points just after "Adobe"
          a = 0
          marker_pos = i - 9
          break if marker_pos < 0 || marker_pos + 4 > size

          tag = (bytes[marker_pos].to_i << 8) | bytes[marker_pos + 1].to_i
          next if tag != 0xFFEE

          len = (bytes[marker_pos + 2].to_i << 8) | bytes[marker_pos + 3].to_i
          data_pos = marker_pos + 4
          if len >= POS_TRANSFORM + 1 && data_pos + POS_TRANSFORM + 1 <= size
            return bytes[data_pos + POS_TRANSFORM].to_i
          end
        else
          a = 0
        end
      end
      0
    end

    # Clamps a value to the 0-255 range (Java DCTFilter#clamp).
    def self.clamp(value : Float32) : Int32
      return 0 if value < 0
      return 255 if value > 255
      value.to_i32
    end

    def decode(encoded : Bytes) : Bytes
      img = CrImage.read(::IO::Memory.new(encoded))
      width = img.bounds.width
      height = img.bounds.height

      rgb = Bytes.new(width * height * 3)
      idx = 0
      height.times do |y|
        width.times do |x|
          r, g, b, _a = img.at(x, y).rgba
          rgb[idx] = (r >> 8).to_u8
          rgb[idx + 1] = (g >> 8).to_u8
          rgb[idx + 2] = (b >> 8).to_u8
          idx += 3
        end
      end
      rgb
    end

    def encode(input : Bytes) : Bytes
      raise Pdfbox::Cos::UnsupportedOperationError.new("DCTFilter encoding not implemented, use the JPEGFactory methods instead")
    end
  end
end

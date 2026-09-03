require "log"

module Pdfbox::Filter
  # Decompresses data encoded using a DCT (discrete cosine transform) technique
  # based on the JPEG standard. The Crystal port decodes via CrImage and emits
  # raw RGB raster bytes. Java: org.apache.pdfbox.filter.DCTFilter
  class DCTFilter < Filter
    Log = ::Log.for(self)

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

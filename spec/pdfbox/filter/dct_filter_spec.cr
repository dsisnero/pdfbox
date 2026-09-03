require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/DCTFilter.java
#
# DCTFilter decompresses JPEG (DCT) image data. The Crystal port decodes the
# JPEG via CrImage and emits raw RGB raster bytes (Java's raster data). The
# 4-component YCCK→CMYK and 3-component BGR→RGB conversions in Java are handled
# by CrImage's JPEG reader; the 4-channel YCCK path is documented as limited.

module Pdfbox::Filter
  JPEG_FIXTURE = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg.jpg"

  describe DCTFilter do
    it "is registered in FilterFactory under DCTDecode and DCT" do
      Pdfbox::Filter::FilterFactory::INSTANCE.filter(Pdfbox::Cos::Name.new("DCTDecode")).should be_a(DCTFilter)
      Pdfbox::Filter::FilterFactory::INSTANCE.filter(Pdfbox::Cos::Name.new("DCT")).should be_a(DCTFilter)
    end

    it "decodes a JPEG to raw RGB bytes of the right size" do
      jpeg_bytes = File.read(JPEG_FIXTURE).to_slice
      img = CrImage.read(::IO::Memory.new(jpeg_bytes))
      width = img.bounds.width
      height = img.bounds.height

      filter = DCTFilter.new
      decoded = filter.decode(jpeg_bytes)
      decoded.bytesize.should eq(width * height * 3)
    end

    it "decodes a JPEG via Cos::Stream with DCTDecode filter" do
      jpeg_bytes = File.read(JPEG_FIXTURE).to_slice
      img = CrImage.read(::IO::Memory.new(jpeg_bytes))
      width = img.bounds.width
      height = img.bounds.height

      stream = Pdfbox::Cos::Stream.new(entries: {} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, data: jpeg_bytes)
      stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("DCTDecode")
      stream[Pdfbox::Cos::Name.new("Width")] = Pdfbox::Cos::Integer.new(width)
      stream[Pdfbox::Cos::Name.new("Height")] = Pdfbox::Cos::Integer.new(height)
      stream[Pdfbox::Cos::Name.new("ColorSpace")] = Pdfbox::Cos::Name.new("DeviceRGB")

      decoded = stream.create_input_stream.gets_to_end
      decoded.bytesize.should eq(width * height * 3)
    end
  end
end

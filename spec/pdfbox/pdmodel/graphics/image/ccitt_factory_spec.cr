require "../../../../spec_helper"

module Pdfbox::Pdmodel::Graphics::Image
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/CCITTFactoryTest.java
  #
  # Ports the CCITTFactory createFromFile/createFromByteArray/createFromFile(number)
  # dictionary-construction behavior: the CCITT T4/T6 strip is extracted from the
  # single-strip TIFF and wrapped in a PDImageXObject with the CCITTFaxDecode
  # filter, 1 bpc, DeviceGray, and Columns/Rows/K/BlackIs1 decode params. The
  # pixel round-trip assertions (ValidateXImage.checkIdent via getOpaqueImage)
  # and rendering are advisory (Chunk K render-compare policy).
  module CCITTFactorySpecHelpers
    IMAGE_DIR = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image")

    # Flips every bit in a 1-bit raster.
    def self.invert_bits(bytes : Bytes) : Bytes
      inverted = Bytes.new(bytes.size)
      bytes.each_with_index { |byte, i| inverted[i] = (~byte & 0xFF).to_u8 }
      inverted
    end

    # Dictionary-level assertions of Java ValidateXImage.validate (without the
    # pixel round-trip / ImageIO.write parts, which are render-compare advisory).
    def self.validate_image(ximage : PDImageXObject?, bpc : Int32, width : Int32, height : Int32, format : String, color_space_name : String)
      ximage.should_not be_nil
      img = ximage.not_nil!
      img.cos_object[Pdfbox::Cos::Name.new("Type")].should eq(Pdfbox::Cos::Name.new("XObject"))
      img.cos_object[Pdfbox::Cos::Name.new("Subtype")].should eq(Pdfbox::Cos::Name.new("Image"))
      img.bits_per_component.should eq(bpc)
      img.width.should eq(width)
      img.height.should eq(height)
      img.suffix.should eq(format)
      color_space_base = img.cos_object[Pdfbox::Cos::Name.new("ColorSpace")]
      color_space_base = color_space_base.object if color_space_base.is_a?(Pdfbox::Cos::Object)
      color_space_base.as(Pdfbox::Cos::Name).value.should eq(color_space_name)

      decode_parms = img.cos_object.get_dictionary(Pdfbox::Cos::Name.new("DecodeParms"))
      if decode_parms
        decode_parms.get_int(Pdfbox::Cos::Name.new("Columns"), 0).should eq(width)
        if decode_parms.has_key?(Pdfbox::Cos::Name.new("Rows"))
          decode_parms.get_int(Pdfbox::Cos::Name.new("Rows"), 0).should eq(height)
        end
        if decode_parms.has_key?(Pdfbox::Cos::Name.new("K"))
          k = decode_parms.get_int(Pdfbox::Cos::Name.new("K"), -1000)
          (k == -1 || k == 0 || k == 50).should be_true
        end
      end
    end
  end

  describe CCITTFactory do
    describe "TestCCITTFactory#testCreateFromRandomAccessSingle" do
      it "extracts the G3 and G4 CCITT strips with correct decode params" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          ximage3 = CCITTFactory.create_from_file(doc, File.join(CCITTFactorySpecHelpers::IMAGE_DIR, "ccittg3.tif"))
          ximage3.should_not be_nil
          CCITTFactorySpecHelpers.validate_image(ximage3, 1, 344, 287, "tiff", "DeviceGray")

          ximage4 = CCITTFactory.create_from_file(doc, File.join(CCITTFactorySpecHelpers::IMAGE_DIR, "ccittg4.tif"))
          ximage4.should_not be_nil
          CCITTFactorySpecHelpers.validate_image(ximage4, 1, 344, 287, "tiff", "DeviceGray")
        ensure
          doc.close
        end
      end
    end

    describe "TestCCITTFactory#testCreateFromRandomAccessMulti" do
      it "iterates multiple CCITT pages from a multi-page TIFF" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          count = 0
          loop do
            ximage = CCITTFactory.create_from_file(doc, File.join(CCITTFactorySpecHelpers::IMAGE_DIR, "ccittg4multi.tif"), count)
            break if ximage.nil?
            CCITTFactorySpecHelpers.validate_image(ximage, 1, ximage.width, ximage.height, "tiff", "DeviceGray")
            count += 1
          end
          count.should be > 1
        ensure
          doc.close
        end
      end
    end

    describe "TestCCITTFactory#testCreateFromFileLock / testCreateFromFileNumberLock" do
      it "does not lock the source file" do
        temp_dir = (SpecPaths::PROJECT_ROOT / "temp" / "ccitt-spec").to_s
        Dir.mkdir_p(temp_dir)
        copied = File.join(temp_dir, "ccittg3.tif")
        File.copy(File.join(CCITTFactorySpecHelpers::IMAGE_DIR, "ccittg3.tif"), copied)

        doc = Pdfbox::Pdmodel::Document.create
        begin
          CCITTFactory.create_from_file(doc, copied)
          CCITTFactory.create_from_file(doc, copied, 0)
          File.delete(copied)
          File.exists?(copied).should be_false
        ensure
          doc.close
        end
      end
    end

    describe "TestCCITTFactory#testByteShortPaddedWithGarbage" do
      it "reads byte/short tag values ignoring garbage padding" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          base = File.join(CCITTFactorySpecHelpers::IMAGE_DIR, "ccittg3-garbage-padded-fields")
          [".tif", "-bigendian.tif"].each do |ext|
            ximage = CCITTFactory.create_from_file(doc, base + ext)
            ximage.should_not be_nil
            CCITTFactorySpecHelpers.validate_image(ximage, 1, 344, 287, "tiff", "DeviceGray")
          end
        ensure
          doc.close
        end
      end
    end

    describe "TestCCITTFactory#testCreateFromBufferedChessImage" do
      it "G4-encodes a 1-bit chess raster so it decodes back to the source" do
        width = 343
        height = 287
        (width % 8).should_not eq(0) # not a multiple of 8, like the Java test
        row_bytes = (width + 7) // 8

        # Java builds the raster by toggling black/white per pixel (x outer, y inner).
        bitmap = Bytes.new(row_bytes * height)
        (0...width).each do |x|
          (0...height).each do |y|
            next unless (x * height + y).even? # black
            bitmap[y * row_bytes + x // 8] |= (1_u8 << (7 - (x % 8)))
          end
        end

        doc = Pdfbox::Pdmodel::Document.create
        begin
          ximage = CCITTFactory.create_from_image(doc, width, height, bitmap)
          CCITTFactorySpecHelpers.validate_image(ximage, 1, width, height, "tiff", "DeviceGray")

          # /BlackIs1 is not set, so the decoder inverts: 0 = black.
          decoded = ximage.stream.not_nil!.create_input_stream.gets_to_end
          decoded.bytesize.should eq(row_bytes * height)
          decoded.to_slice.should eq(CCITTFactorySpecHelpers.invert_bits(bitmap))
        ensure
          doc.close
        end
      end
    end

    describe "TestCCITTFactory#testCreateFromBufferedImage" do
      it "G4-encodes the raster from a TIFF-derived bitmap" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          reference = CCITTFactory.create_from_file(doc, File.join(CCITTFactorySpecHelpers::IMAGE_DIR, "ccittg4.tif"))
          reference.should_not be_nil
          cols = reference.not_nil!.width
          rows = reference.not_nil!.height

          # 0 = black; createFromImage expects bit 1 = black.
          visual = reference.not_nil!.stream.not_nil!.create_input_stream.gets_to_end.to_slice

          ximage = CCITTFactory.create_from_image(doc, cols, rows, CCITTFactorySpecHelpers.invert_bits(visual))
          CCITTFactorySpecHelpers.validate_image(ximage, 1, cols, rows, "tiff", "DeviceGray")

          decoded = ximage.stream.not_nil!.create_input_stream.gets_to_end.to_slice
          decoded.should eq(visual)
        ensure
          doc.close
        end
      end
    end
  end
end

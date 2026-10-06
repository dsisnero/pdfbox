require "../../../../spec_helper"

module Pdfbox::Pdmodel::Graphics::Image
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/LosslessFactoryTest.java
  #
  # Ports the LosslessFactory.createFromImage dictionary-construction behavior:
  # grayscale images become Flate-encoded DeviceGray at the source bit depth;
  # RGB(A) images become PNG-predictor-15 + Flate encoded DeviceRGB with a
  # DecodeParms dict (Predictor/Colors/Columns), plus a DeviceGray soft mask for
  # transparency. The pixel round-trip assertions (ValidateXImage.checkIdent,
  # getImage, colorCount) and rendering are advisory (Chunk K render-compare
  # policy).
  module LosslessFactorySpecHelpers
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
    end

    # Java: assertNotNull(ximage.getSoftMask()); validate(smask, ...)
    def self.assert_soft_mask(img : PDImageXObject, bpc : Int32, width : Int32, height : Int32, color_space_name : String)
      smask_base = img.cos_object[Pdfbox::Cos::Name.new("SMask")]?
      smask_base.should_not be_nil
      smask_obj = smask_base.not_nil!
      smask_obj = smask_obj.object if smask_obj.is_a?(Pdfbox::Cos::Object)
      smask = smask_obj.as(Pdfbox::Cos::Stream)
      doc = Pdfbox::Pdmodel::Document.create
      begin
        validate_image(PDImageXObject.new(doc, smask, smask), bpc, width, height, "png", color_space_name)
      ensure
        doc.close
      end
    end

    # Builds an opaque RGBA image from RGB tuples.
    def self.build_rgb(width : Int32, height : Int32, &) : CrImage::RGBA
      img = CrImage::RGBA.new(CrImage.rect(0, 0, width, height))
      0.upto(height - 1) do |y|
        0.upto(width - 1) do |x|
          r, g, b = yield(x, y)
          img.set_rgba(x, y, CrImage::Color::RGBA.new(r.to_u8, g.to_u8, b.to_u8, 255_u8))
        end
      end
      img
    end
  end

  describe LosslessFactory do
    describe "TestLosslessFactoryTest#testCreateLosslessFromImageRGB" do
      it "encodes an opaque RGB image as predictor-15 PNG (DeviceRGB, 8 bpc)" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          w = 64
          h = 48
          image = LosslessFactorySpecHelpers.build_rgb(w, h) { |x, y| {(x * 20) % 256, (y * 30) % 256, (x + y) % 256} }
          ximage = LosslessFactory.create_from_image(doc, image)
          LosslessFactorySpecHelpers.validate_image(ximage, 8, w, h, "png", "DeviceRGB")

          # soft mask only for transparency
          ximage.cos_object[Pdfbox::Cos::Name.new("SMask")]?.should be_nil

          # predictor decode params
          decode_parms = ximage.cos_object.get_dictionary(Pdfbox::Cos::Name.new("DecodeParms"))
          decode_parms.should_not be_nil
          decode_parms.not_nil!.get_int(Pdfbox::Cos::Name.new("Predictor"), 0).should eq(15)
          decode_parms.not_nil!.get_int(Pdfbox::Cos::Name.new("Colors"), 0).should eq(3)
          decode_parms.not_nil!.get_int(Pdfbox::Cos::Name.new("Columns"), 0).should eq(w)
          decode_parms.not_nil!.get_int(Pdfbox::Cos::Name.new("BitsPerComponent"), 0).should eq(8)
        ensure
          doc.close
        end
      end

      it "encodes a grayscale image as DeviceGray at 8 bpc without DecodeParms" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          w = 8
          h = 6
          gray = CrImage::Gray.new(CrImage.rect(0, 0, w, h))
          0.upto(h - 1) do |y|
            0.upto(w - 1) do |x|
              gray.set_gray(x, y, CrImage::Color::Gray.new((x * 32 + y * 16) % 256))
            end
          end
          ximage = LosslessFactory.create_from_image(doc, gray)
          LosslessFactorySpecHelpers.validate_image(ximage, 8, w, h, "png", "DeviceGray")
          ximage.cos_object[Pdfbox::Cos::Name.new("SMask")]?.should be_nil
        ensure
          doc.close
        end
      end
    end

    describe "TestLosslessFactoryTest#testCreateLosslessFromImageINT_ARGB" do
      it "creates a DeviceGray soft mask for transparency and keeps RGB predictor image" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          w = 60
          h = 60
          image = CrImage::RGBA.new(CrImage.rect(0, 0, w, h))
          0.upto(h - 1) do |y|
            0.upto(w - 1) do |x|
              alpha = (y / 10 * 10) % 256
              image.set_rgba(x, y, CrImage::Color::RGBA.new(200_u8, 100_u8, 50_u8, alpha.to_u8))
            end
          end

          ximage = LosslessFactory.create_from_image(doc, image)
          LosslessFactorySpecHelpers.validate_image(ximage, 8, w, h, "png", "DeviceRGB")
          LosslessFactorySpecHelpers.assert_soft_mask(ximage, 8, w, h, "DeviceGray")

          decode_parms = ximage.cos_object.get_dictionary(Pdfbox::Cos::Name.new("DecodeParms"))
          decode_parms.should_not be_nil
          decode_parms.not_nil!.get_int(Pdfbox::Cos::Name.new("Predictor"), 0).should eq(15)
          decode_parms.not_nil!.get_int(Pdfbox::Cos::Name.new("Colors"), 0).should eq(3)
        ensure
          doc.close
        end
      end
    end

    describe "TestLosslessFactoryTest#testCreateLosslessFromImageBITMASK_INT_ARGB" do
      it "uses a 1-bit soft mask when alpha is binary (BITMASK transparency)" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          width = 11
          height = 8
          image = CrImage::RGBA.new(CrImage.rect(0, 0, width, height))
          0.upto(height - 1) do |y|
            0.upto(width - 1) do |x|
              alpha = (x + y) % 2 == 0 ? 255_u8 : 0_u8
              image.set_rgba(x, y, CrImage::Color::RGBA.new(255_u8, 0_u8, 0_u8, alpha))
            end
          end

          ximage = LosslessFactory.create_from_image(doc, image)
          LosslessFactorySpecHelpers.validate_image(ximage, 8, width, height, "png", "DeviceRGB")
          LosslessFactorySpecHelpers.assert_soft_mask(ximage, 1, width, height, "DeviceGray")
        ensure
          doc.close
        end
      end
    end

    describe "TestLosslessFactoryTest#testCreateLosslessFromImageINT_BGR / INT_RGB / BYTE_3BGR" do
      it "encodes opaque RGB buffers identically regardless of source pixel layout" do
        doc = Pdfbox::Pdmodel::Document.create
        begin
          w = 64
          h = 40
          bgr = LosslessFactorySpecHelpers.build_rgb(w, h) { |x, y| {(x * 13) % 256, (y * 17) % 256, (x * y) % 256} }
          bgr_image = LosslessFactory.create_from_image(doc, bgr)
          LosslessFactorySpecHelpers.validate_image(bgr_image, 8, w, h, "png", "DeviceRGB")

          rgb = LosslessFactorySpecHelpers.build_rgb(w, h) { |x, y| {(x * 13) % 256, (y * 17) % 256, (x * y) % 256} }
          rgb_image = LosslessFactory.create_from_image(doc, rgb)
          LosslessFactorySpecHelpers.validate_image(rgb_image, 8, w, h, "png", "DeviceRGB")
        ensure
          doc.close
        end
      end
    end
  end
end

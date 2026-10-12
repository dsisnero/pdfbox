require "../../../../spec_helper"

private JPEG_PATH = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg.jpg")
private JPEG_CMYK = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpegcmyk.jpg")
private JPEG_GRAY = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg256.jpg")

# Helpers for the create_from_image tests. AWT BufferedImage is modelled with CrImage
# (RGBA/NRGBA/Gray); ImageIO.is available as CrImage. The pixel-identical rendering
# assertions of ValidateXImage.checkIdent are advisory (Chunk K render-compare policy).
private module JpegFactoryCreateFromImageHelpers
  # Java ValidateXImage.validate without the pixel round-trip / ImageIO.write parts.
  def self.validate_image(ximage : Pdfbox::Pdmodel::Graphics::Image::PDImageXObject, bpc : Int32, width : Int32, height : Int32, color_space_name : String)
    ximage.cos_object[Pdfbox::Cos::Name.new("Type")].should eq(Pdfbox::Cos::Name.new("XObject"))
    ximage.cos_object[Pdfbox::Cos::Name.new("Subtype")].should eq(Pdfbox::Cos::Name.new("Image"))
    ximage.bits_per_component.should eq(bpc)
    ximage.width.should eq(width)
    ximage.height.should eq(height)
    ximage.suffix.should eq("jpg")
    color_space_base = ximage.cos_object[Pdfbox::Cos::Name.new("ColorSpace")]
    color_space_base = color_space_base.object if color_space_base.is_a?(Pdfbox::Cos::Object)
    color_space_base.as(Pdfbox::Cos::Name).value.should eq(color_space_name)
  end

  # Returns the soft mask XObject stream (Java getSoftMask) or nil.
  def self.soft_mask_stream(ximage : Pdfbox::Pdmodel::Graphics::Image::PDImageXObject) : Pdfbox::Cos::Stream?
    base = ximage.cos_object[Pdfbox::Cos::Name.new("SMask")]?
    return nil unless base
    base = base.object if base.is_a?(Pdfbox::Cos::Object)
    base.as?(Pdfbox::Cos::Stream)
  end

  # Java: colorCount(image) — number of distinct colors in the decoded image.
  def self.color_count(image : CrImage::Image) : Int32
    colors = Set(UInt32).new
    bounds = image.bounds
    bounds.min.y.upto(bounds.max.y - 1) do |y|
      bounds.min.x.upto(bounds.max.x - 1) do |x|
        r, g, b, _a = image.at(x, y).rgba
        colors << (((r >> 8).to_u32 << 16) | ((g >> 8).to_u32 << 8) | (b >> 8).to_u32)
      end
    end
    colors.size
  end

  # Java testCreateFromImageINT_ARGB/4BYTE_ABGR: build a non-premultiplied ARGB image from
  # an RGB source and punch an alpha gradient of (y/10*10) down the image.
  def self.build_argb_with_alpha_gradient(base : CrImage::Image) : CrImage::NRGBA
    width = base.bounds.width
    height = base.bounds.height
    argb = CrImage::NRGBA.new(CrImage.rect(0, 0, width, height))
    0.upto(height - 1) do |y|
      # Java sets the alpha byte via (y / 10 * 10) << 24, which wraps mod 256.
      alpha = (((y // 10) * 10) & 0xFF).to_u8
      0.upto(width - 1) do |x|
        r, g, b, _a = base.at(x, y).rgba
        argb.set_nrgba(x, y, CrImage::Color::NRGBA.new((r >> 8).to_u8, (g >> 8).to_u8, (b >> 8).to_u8, alpha))
      end
    end
    argb
  end

  # Java testCreateFromImageUSHORT_555_RGB: RGB image with no alpha channel.
  def self.build_opaque_rgb(base : CrImage::Image) : CrImage::RGBA
    width = base.bounds.width
    height = base.bounds.height
    rgb = CrImage::RGBA.new(CrImage.rect(0, 0, width, height))
    0.upto(height - 1) do |y|
      0.upto(width - 1) do |x|
        r, g, b, _a = base.at(x, y).rgba
        rgb.set_rgba(x, y, CrImage::Color::RGBA.new((r >> 8).to_u8, (g >> 8).to_u8, (b >> 8).to_u8, 255_u8))
      end
    end
    rgb
  end
end

# Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/JPEGFactoryTest.java
# Model surface parity: create_from_stream / create_from_byte_array color space detection
# (DeviceRGB / DeviceCMYK / DeviceGray from the JPEG SOF frame components) plus the exact
# JPEG stream round-trip through save/load, and create_from_image (raster -> JPEG XObject
# with a DeviceGray soft mask for transparency). AWT BufferedImage / ImageIO rendering
# assertions are advisory (no AWT equivalent in Crystal).
describe Pdfbox::Pdmodel::Graphics::Image::JPEGFactory do
  describe "create_from_stream" do
    it "creates RGB JPEG XObject with DCTDecode filter and DeviceRGB color space" do
      doc = Pdfbox::Pdmodel::Document.create
      io = ::File.open(JPEG_PATH)
      image = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_stream(doc, io)

      image.bits_per_component.should eq(8)
      image.width.should eq(344)
      image.height.should eq(287)
      image.suffix.should eq("jpg")
      image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)

      cos = image.cos_object.as(Pdfbox::Cos::Stream)
      cos[Pdfbox::Cos::Name.new("Type")].as(Pdfbox::Cos::Name).value.should eq("XObject")
      cos[Pdfbox::Cos::Name.new("Subtype")].as(Pdfbox::Cos::Name).value.should eq("Image")
      cos[Pdfbox::Cos::Name.new("Filter")].as(Pdfbox::Cos::Name).value.should eq("DCTDecode")
      cos.data.size.should be > 0
    ensure
      io.try(&.close)
      doc.try(&.close)
    end

    it "creates CMYK JPEG XObject with DeviceCMYK color space and inverted Decode array" do
      doc = Pdfbox::Pdmodel::Document.create
      io = ::File.open(JPEG_CMYK)
      image = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_stream(doc, io)

      image.bits_per_component.should eq(8)
      image.width.should eq(343)
      image.height.should eq(287)
      image.suffix.should eq("jpg")
      image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE)

      decode = image.decode
      decode.size.should eq(8)
      decode.to_cos_number_float_list.should eq([1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0])
    ensure
      io.try(&.close)
      doc.try(&.close)
    end

    it "creates gray JPEG XObject with DeviceGray color space" do
      doc = Pdfbox::Pdmodel::Document.create
      io = ::File.open(JPEG_GRAY)
      image = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_stream(doc, io)

      image.bits_per_component.should eq(8)
      image.width.should eq(344)
      image.height.should eq(287)
      image.suffix.should eq("jpg")
      image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
    ensure
      io.try(&.close)
      doc.try(&.close)
    end
  end

  describe "create_from_byte_array" do
    it "preserves the JPEG stream byte-for-byte" do
      doc = Pdfbox::Pdmodel::Document.create
      original = ::File.read(JPEG_PATH).to_slice
      image = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_byte_array(doc, original)

      cos = image.cos_object.as(Pdfbox::Cos::Stream)
      cos.data.should eq(original)
    ensure
      doc.try(&.close)
    end
  end

  # Source of truth: JPEGFactoryTest.checkJpegStream — the JPEG stream can be extracted
  # PDFBOX-5137 / PDFBOX-5196: numFrameComponents (not numScanComponents) selects
  # the color space; checkJpegStream extracts the raw JPEG after save/reload.
  describe "TestPDFBox5137" do
    it "uses numFrameComponents for the color space and preserves the JPEG stream" do
      lotus_jpeg = SpecPaths.resolve("spec/resources/pdfbox/pdmodel/graphics/image/PDFBOX-5196-lotus.jpg")
      original = ::File.read(lotus_jpeg).to_slice
      outfile = File.tempname("pdfbox_5137_", ".pdf")
      begin
        doc = Pdfbox::Pdmodel::Document.create
        image = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_byte_array(doc, original)

        # Java ValidateXImage.validate(ximage, 8, 500, 500, "jpg", DeviceRGB).
        cos = image.cos_object.as(Pdfbox::Cos::Stream)
        cos[Pdfbox::Cos::Name.new("Type")].as(Pdfbox::Cos::Name).value.should eq("XObject")
        cos[Pdfbox::Cos::Name.new("Subtype")].as(Pdfbox::Cos::Name).value.should eq("Image")
        cos.data.size.should be > 0
        image.bits_per_component.should eq(8)
        image.width.should eq(500)
        image.height.should eq(500)
        image.suffix.should eq("jpg")
        image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)

        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)
        content = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        content.draw_image(image, 0, 0, image.width, image.height)
        content.close
        doc.save(outfile)
        doc.close

        # Java checkJpegStream: Im1's DCT stream equals the original JPEG.
        reloaded = Pdfbox::Pdmodel::Document.load(outfile)
        resources = reloaded.pages[0].resources.not_nil!
        xobject_dict = resources.cos_object[Pdfbox::Cos::Name.new("XObject")]
        xobject_dict = xobject_dict.object.as(Pdfbox::Cos::Base) if xobject_dict.is_a?(Pdfbox::Cos::Object)
        entry = xobject_dict.as(Pdfbox::Cos::Dictionary).entries.values.first
        entry = entry.object.as(Pdfbox::Cos::Base) if entry.is_a?(Pdfbox::Cos::Object)
        stream = entry.as(Pdfbox::Cos::Stream)

        stream.create_input_stream(["DCTDecode"]).gets_to_end.to_slice.should eq(original)
        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end
  end

  # from a saved/reloaded PDF exactly as it was passed to createFromStream.
  describe "JPEG stream round-trip" do
    it "extracts the exact JPEG bytes after save and reload" do
      outfile = File.tempname("pdfbox_jpeg_factory_", ".pdf")
      begin
        doc = Pdfbox::Pdmodel::Document.create
        original = ::File.read(JPEG_PATH).to_slice
        image = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_byte_array(doc, original)

        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)
        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        content_stream.draw_image(image, 150, 300, image.width, image.height)
        content_stream.close
        doc.save(outfile)
        doc.close

        reloaded = Pdfbox::Pdmodel::Document.load(outfile)
        page0 = reloaded.pages[0]
        resources = page0.resources.not_nil!

        xobject_dict_value = resources.cos_object[Pdfbox::Cos::Name.new("XObject")]
        xobject_dict_value = xobject_dict_value.object.as(Pdfbox::Cos::Base) if xobject_dict_value.is_a?(Pdfbox::Cos::Object)
        xobject_dict = xobject_dict_value.as(Pdfbox::Cos::Dictionary)
        xobject_dict.entries.size.should eq(1)
        xobject = xobject_dict.entries.values.first
        xobject = xobject.object.as(Pdfbox::Cos::Base) if xobject.is_a?(Pdfbox::Cos::Object)
        stream = xobject.as(Pdfbox::Cos::Stream)
        stream[Pdfbox::Cos::Name.new("Filter")].as(Pdfbox::Cos::Name).value.should eq("DCTDecode")
        stream.data.should eq(original)
        # Java checkJpegStream: createInputStream([DCTDecode]) yields the raw JPEG.
        stream.create_input_stream(["DCTDecode"]).gets_to_end.to_slice.should eq(original)
        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end
  end

  # Source of truth: JPEGFactoryTest#testCreateFromImageRGB / #testCreateFromImage256 /
  # #testCreateFromImageINT_ARGB / #testCreateFromImage4BYTE_ABGR /
  # #testCreateFromImageUSHORT_555_RGB. The Java AWT image types are modelled with CrImage:
  # TYPE_INT_ARGB and TYPE_4BYTE_ABGR both map to a non-premultiplied alpha raster (NRGBA),
  # so they exercise the same soft-mask path in Crystal.
  describe "create_from_image" do
    it "testCreateFromImageRGB: encodes a color raster as a DeviceRGB JPEG" do
      doc = Pdfbox::Pdmodel::Document.create
      begin
        image = CrImage.read(JPEG_PATH)
        image.bounds.width.should eq(344)
        image.bounds.height.should eq(287)
        ximage = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_image(doc, image)
        JpegFactoryCreateFromImageHelpers.validate_image(ximage, 8, 344, 287, "DeviceRGB")
        JpegFactoryCreateFromImageHelpers.soft_mask_stream(ximage).should be_nil
      ensure
        doc.close
      end
    end

    it "testCreateFromImage256: encodes a gray raster as a DeviceGray JPEG" do
      doc = Pdfbox::Pdmodel::Document.create
      begin
        image = CrImage.read(JPEG_GRAY)
        image.bounds.width.should eq(344)
        image.bounds.height.should eq(287)
        ximage = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_image(doc, image)
        JpegFactoryCreateFromImageHelpers.validate_image(ximage, 8, 344, 287, "DeviceGray")
        JpegFactoryCreateFromImageHelpers.soft_mask_stream(ximage).should be_nil
      ensure
        doc.close
      end
    end

    it "testCreateFromImageINT_ARGB: alpha rasters get a DeviceGray JPEG soft mask" do
      doc = Pdfbox::Pdmodel::Document.create
      begin
        base = CrImage.read(JPEG_PATH)
        width = base.bounds.width
        height = base.bounds.height
        argb = JpegFactoryCreateFromImageHelpers.build_argb_with_alpha_gradient(base)

        ximage = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_image(doc, argb)
        JpegFactoryCreateFromImageHelpers.validate_image(ximage, 8, width, height, "DeviceRGB")

        smask = JpegFactoryCreateFromImageHelpers.soft_mask_stream(ximage)
        smask.should_not be_nil
        smask_image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc, smask.not_nil!, smask.not_nil!)
        JpegFactoryCreateFromImageHelpers.validate_image(smask_image, 8, width, height, "DeviceGray")

        # Java: assertTrue(colorCount(ximage.getSoftMask().getImage()) > image.getHeight() / 10)
        decoded = CrImage.read(::IO::Memory.new(smask.not_nil!.data))
        JpegFactoryCreateFromImageHelpers.color_count(decoded).should be > (height // 10)
      ensure
        doc.close
      end
    end

    it "testCreateFromImage4BYTE_ABGR: exercises the same alpha soft-mask path" do
      doc = Pdfbox::Pdmodel::Document.create
      begin
        base = CrImage.read(JPEG_PATH)
        width = base.bounds.width
        height = base.bounds.height
        abgr = JpegFactoryCreateFromImageHelpers.build_argb_with_alpha_gradient(base)

        ximage = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_image(doc, abgr)
        JpegFactoryCreateFromImageHelpers.validate_image(ximage, 8, width, height, "DeviceRGB")

        smask = JpegFactoryCreateFromImageHelpers.soft_mask_stream(ximage)
        smask.should_not be_nil
        smask_image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc, smask.not_nil!, smask.not_nil!)
        JpegFactoryCreateFromImageHelpers.validate_image(smask_image, 8, width, height, "DeviceGray")

        decoded = CrImage.read(::IO::Memory.new(smask.not_nil!.data))
        JpegFactoryCreateFromImageHelpers.color_count(decoded).should be > (height // 10)
      ensure
        doc.close
      end
    end

    it "testCreateFromImageUSHORT_555_RGB: opaque RGB raster has no soft mask" do
      doc = Pdfbox::Pdmodel::Document.create
      begin
        base = CrImage.read(JPEG_PATH)
        width = base.bounds.width
        height = base.bounds.height
        rgb = JpegFactoryCreateFromImageHelpers.build_opaque_rgb(base)

        ximage = Pdfbox::Pdmodel::Graphics::Image::JPEGFactory.create_from_image(doc, rgb)
        JpegFactoryCreateFromImageHelpers.validate_image(ximage, 8, width, height, "DeviceRGB")
        JpegFactoryCreateFromImageHelpers.soft_mask_stream(ximage).should be_nil
      ensure
        doc.close
      end
    end
  end
end

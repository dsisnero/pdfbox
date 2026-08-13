require "../../../../spec_helper"

private JPEG_PATH = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg.jpg")
private JPEG_CMYK = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpegcmyk.jpg")
private JPEG_GRAY = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg256.jpg")

# Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/JPEGFactoryTest.java
# Model surface parity: create_from_stream / create_from_byte_array color space detection
# (DeviceRGB / DeviceCMYK / DeviceGray from the JPEG SOF frame components) plus the exact
# JPEG stream round-trip through save/load. AWT BufferedImage / ImageIO rendering assertions
# are out of scope (no AWT equivalent in Crystal).
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
        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end
  end
end

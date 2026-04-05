require "../../../../spec_helper"

private JPEG_PATH = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg.jpg")
private PNG_PATH  = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/png.png")

# Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/PDImageXObjectTest.java
# Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/LosslessFactoryTest.java
describe Pdfbox::Pdmodel::Graphics::Image::PDImageXObject do
  describe "create_from_file" do
    it "creates JPEG XObject with DCTDecode filter and correct dimensions" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(JPEG_PATH, doc)

      image.width.should eq(344)
      image.height.should eq(287)
      image.bits_per_component.should eq(8)
      image.suffix.should eq("jpg")

      cos = image.cos_object.as(Pdfbox::Cos::Dictionary)
      cos[Pdfbox::Cos::Name.new("Filter")].as(Pdfbox::Cos::Name).value.should eq("DCTDecode")
      cos[Pdfbox::Cos::Name.new("ColorSpace")].as(Pdfbox::Cos::Name).value.should eq("DeviceRGB")
    ensure
      doc.try(&.close)
    end

    it "creates PNG XObject with FlateDecode filter and correct dimensions" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(PNG_PATH, doc)

      image.width.should eq(343)
      image.height.should eq(287)
      image.bits_per_component.should eq(8)
      image.suffix.should eq("png")

      cos = image.cos_object.as(Pdfbox::Cos::Dictionary)
      cos[Pdfbox::Cos::Name.new("Filter")].as(Pdfbox::Cos::Name).value.should eq("FlateDecode")
      cos[Pdfbox::Cos::Name.new("ColorSpace")].as(Pdfbox::Cos::Name).value.should eq("DeviceRGB")
    ensure
      doc.try(&.close)
    end

    it "XOR stream contains image data" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(JPEG_PATH, doc)

      stream = image.create_input_stream
      stream.size.should be > 0
    ensure
      doc.try(&.close)
    end
  end

  describe "default properties" do
    it "has correct Type and Subtype entries" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)

      cos = image.cos_object.as(Pdfbox::Cos::Dictionary)
      cos[Pdfbox::Cos::Name.new("Type")].as(Pdfbox::Cos::Name).value.should eq("XObject")
      cos[Pdfbox::Cos::Name.new("Subtype")].as(Pdfbox::Cos::Name).value.should eq("Image")
    ensure
      doc.try(&.close)
    end

    it "supports setting and getting width/height" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)

      image.width = 640
      image.height = 480
      image.width.should eq(640)
      image.height.should eq(480)
    ensure
      doc.try(&.close)
    end

    it "supports setting bits_per_component" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)

      image.bits_per_component = 8
      image.bits_per_component.should eq(8)
    ensure
      doc.try(&.close)
    end

    it "supports setting interpolate" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)

      image.interpolate?.should eq(false)
      image.interpolate = true
      image.interpolate?.should eq(true)
    ensure
      doc.try(&.close)
    end

    it "supports setting stencil" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)

      image.stencil?.should eq(false)
      image.stencil = true
      image.stencil?.should eq(true)
    ensure
      doc.try(&.close)
    end
  end

  describe "drawImage and save round-trip" do
    # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/ValidateXImage.java:doWritePDF
    it "embeds JPEG in PDF and re-loads with correct page count" do
      outfile = File.tempname("pdfbox_crystal_test_", ".pdf")
      begin
        doc = Pdfbox::Pdmodel::Document.create
        image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(JPEG_PATH, doc)

        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        content_stream.draw_image(image, 0, 0, image.width, image.height)
        content_stream.close

        doc.save(outfile)

        # Re-load and verify
        reloaded = Pdfbox::Pdmodel::Document.load(outfile)
        reloaded.number_of_pages.should eq(1)
        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end

    it "embeds PNG in PDF and re-loads with correct page count" do
      outfile = File.tempname("pdfbox_crystal_test_", ".pdf")
      begin
        doc = Pdfbox::Pdmodel::Document.create
        image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(PNG_PATH, doc)

        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        content_stream.draw_image(image, 0, 0, image.width, image.height)
        content_stream.close

        doc.save(outfile)

        reloaded = Pdfbox::Pdmodel::Document.load(outfile)
        reloaded.number_of_pages.should eq(1)
        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end

    it "embeds image resized to page dimensions" do
      outfile = File.tempname("pdfbox_crystal_test_", ".pdf")
      begin
        doc = Pdfbox::Pdmodel::Document.create
        image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(JPEG_PATH, doc)

        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        content_stream.draw_image(image, 0, 0, 612, 792)
        content_stream.close

        doc.save(outfile)

        reloaded = Pdfbox::Pdmodel::Document.load(outfile)
        reloaded.number_of_pages.should eq(1)
        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end

    # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/ValidateXImage.java:doWritePDF
    it "handles multiple images on the same page" do
      outfile = File.tempname("pdfbox_crystal_test_", ".pdf")
      begin
        doc = Pdfbox::Pdmodel::Document.create
        jpeg_image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(JPEG_PATH, doc)
        png_image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(PNG_PATH, doc)

        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        content_stream.draw_image(jpeg_image, 0, 400, 200, 167)
        content_stream.draw_image(png_image, 300, 400, 200, 167)
        content_stream.close

        doc.save(outfile)

        reloaded = Pdfbox::Pdmodel::Document.load(outfile)
        reloaded.number_of_pages.should eq(1)
        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end

    # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/ValidateXImage.java:doWritePDF
    it "handles drawImage with Matrix overload" do
      outfile = File.tempname("pdfbox_crystal_test_", ".pdf")
      begin
        doc = Pdfbox::Pdmodel::Document.create
        image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(JPEG_PATH, doc)

        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        matrix = Pdfbox::Util::Matrix.new(2.0_f32, 0.0_f32, 0.0_f32, 2.0_f32, 10.0_f32, 20.0_f32)
        content_stream.draw_image(image, matrix)
        content_stream.close

        doc.save(outfile)

        reloaded = Pdfbox::Pdmodel::Document.load(outfile)
        reloaded.number_of_pages.should eq(1)
        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end

    it "saves and re-loads with XObject resource on the page" do
      outfile = File.tempname("pdfbox_crystal_test_", ".pdf")
      begin
        doc = Pdfbox::Pdmodel::Document.create
        image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(JPEG_PATH, doc)

        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        content_stream.draw_image(image, 10, 20, 100, 83)
        content_stream.close

        doc.save(outfile)

        reloaded = Pdfbox::Pdmodel::Document.load(outfile)
        page0 = reloaded.pages[0]
        resources = page0.resources
        resources.should_not be_nil

        xobject_dict = resources.not_nil!.cos_object[Pdfbox::Cos::Name.new("XObject")]?
        xobject_dict.should_not be_nil

        reloaded.close
      ensure
        File.delete(outfile) if File.exists?(outfile)
      end
    end
  end
end

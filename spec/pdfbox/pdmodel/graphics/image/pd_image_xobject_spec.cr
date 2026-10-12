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

      image.interpolate?.should be_false
      image.interpolate = true
      image.interpolate?.should be_true
    ensure
      doc.try(&.close)
    end

    it "supports setting stencil" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)

      image.stencil?.should be_false
      image.stencil = true
      image.stencil?.should be_true
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

  describe "mask / soft-mask / optional-content accessors" do
    # Source of truth:
    # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/image/PDImageXObject.java
    # Upstream has no dedicated tests for these accessors; behavior is inferred
    # from the Java implementation.
    it "empty? is true for an image with no stream data and false otherwise" do
      doc = Pdfbox::Pdmodel::Document.create

      empty_stream = Pdfbox::Cos::Stream.new
      empty_image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc, empty_stream, empty_stream)
      empty_image.empty?.should be_true

      data_stream = Pdfbox::Cos::Stream.new(data: Bytes[1, 2, 3])
      data_image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc, data_stream, data_stream)
      data_image.empty?.should be_false
    ensure
      doc.try(&.close)
    end

    it "color_key_mask returns the /Mask array and mask returns nil for it" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
      array = Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(0), Pdfbox::Cos::Integer.new(1)])
      image.cos_object.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Mask")] = array

      image.color_key_mask.should be(array)
      image.mask.should be_nil
    ensure
      doc.try(&.close)
    end

    it "mask returns the /Mask stream as an image (and color_key_mask is nil)" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
      mask_stream = Pdfbox::Cos::Stream.new(data: Bytes[0])
      image.cos_object.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Mask")] = mask_stream

      mask_image = image.mask
      mask_image.should_not be_nil
      mask_image.as(Pdfbox::Pdmodel::Graphics::Image::PDImageXObject).cos_object.should be(mask_stream)
      image.color_key_mask.should be_nil
    ensure
      doc.try(&.close)
    end

    it "mask and color_key_mask are nil when /Mask is absent" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)

      image.mask.should be_nil
      image.color_key_mask.should be_nil
    ensure
      doc.try(&.close)
    end

    it "soft_mask returns the /SMask stream as an image" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
      smask_stream = Pdfbox::Cos::Stream.new(data: Bytes[0])
      image.cos_object.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("SMask")] = smask_stream

      soft = image.soft_mask
      soft.should_not be_nil
      soft.as(Pdfbox::Pdmodel::Graphics::Image::PDImageXObject).cos_object.should be(smask_stream)
    ensure
      doc.try(&.close)
    end

    it "optional_content dispatches on /Type and round-trips through the setter" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc)
      image.optional_content.should be_nil

      oc_dict = Pdfbox::Cos::Dictionary.new
      oc_dict[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("OCG")
      image.cos_object.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("OC")] = oc_dict

      image.optional_content.should be_a(Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup)

      new_oc = Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList.new(Pdfbox::Cos::Dictionary.new)
      image.optional_content = new_oc
      image.cos_object.as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("OC")].should be(new_oc.cos_object)
    ensure
      doc.try(&.close)
    end
  end
end

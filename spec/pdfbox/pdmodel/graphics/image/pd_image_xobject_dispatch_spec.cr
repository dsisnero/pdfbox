require "../../../../spec_helper"

private IMAGE_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image"

private def image_path(name : String) : String
  SpecPaths.resolve("#{IMAGE_DIR}/#{name}")
end

# Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/PDImageXObjectTest.java
# Source of truth: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/util/filetypedetector/FileTypeDetector.java
# Model surface parity: the createFromFileByExtension / createFromFileByContent /
# createFromByteArray convenience methods dispatch to the right factory and produce the
# same image suffix (JPEG -> jpg, PNG/GIF -> png). FileTypeDetector magic-byte detection.
# AWT BufferedImage / ImageIO pixel comparisons (checkIdentARGB) are out of scope.
describe Pdfbox::Pdmodel::Graphics::Image::PDImageXObject do
  describe "FileTypeDetector" do
    it "detects JPEG from the FF D8 magic bytes" do
      bytes = Slice.new(2) { 0x00_u8 }
      bytes[0] = 0xFF_u8
      bytes[1] = 0xD8_u8
      Pdfbox::Util::FileTypeDetector.detect_file_type(bytes).should eq(Pdfbox::Util::FileType::Jpeg)
    end

    it "detects TIFF from both byte orders" do
      little = Slice.new(4) { 0x00_u8 }
      little[0] = 0x49_u8 # I
      little[1] = 0x49_u8 # I
      little[2] = 0x2A_u8
      Pdfbox::Util::FileTypeDetector.detect_file_type(little).should eq(Pdfbox::Util::FileType::Tiff)

      big = Slice.new(4) { 0x00_u8 }
      big[0] = 0x4D_u8 # M
      big[1] = 0x4D_u8 # M
      big[2] = 0x00_u8
      big[3] = 0x2A_u8
      Pdfbox::Util::FileTypeDetector.detect_file_type(big).should eq(Pdfbox::Util::FileType::Tiff)
    end

    it "detects PNG from the 16-byte signature (including IHDR)" do
      bytes = Slice.new(16) { 0x00_u8 }
      bytes[0] = 0x89_u8
      bytes[1] = 0x50_u8 # P
      bytes[2] = 0x4E_u8 # N
      bytes[3] = 0x47_u8 # G
      bytes[4] = 0x0D_u8
      bytes[5] = 0x0A_u8
      bytes[6] = 0x1A_u8
      bytes[7] = 0x0A_u8
      bytes[8] = 0x00_u8
      bytes[9] = 0x00_u8
      bytes[10] = 0x00_u8
      bytes[11] = 0x0D_u8
      bytes[12] = 0x49_u8 # I
      bytes[13] = 0x48_u8 # H
      bytes[14] = 0x44_u8 # D
      bytes[15] = 0x52_u8 # R
      Pdfbox::Util::FileTypeDetector.detect_file_type(bytes).should eq(Pdfbox::Util::FileType::Png)
    end

    it "detects GIF 87a and 89a" do
      Pdfbox::Util::FileTypeDetector.detect_file_type("GIF87a".to_slice).should eq(Pdfbox::Util::FileType::Gif)
      Pdfbox::Util::FileTypeDetector.detect_file_type("GIF89a".to_slice).should eq(Pdfbox::Util::FileType::Gif)
    end

    it "detects BMP from the BM magic bytes" do
      Pdfbox::Util::FileTypeDetector.detect_file_type("BM".to_slice).should eq(Pdfbox::Util::FileType::Bmp)
    end

    it "returns UNKNOWN for unrecognised bytes" do
      Pdfbox::Util::FileTypeDetector.detect_file_type("hello".to_slice).should eq(Pdfbox::Util::FileType::Unknown)
    end

    it "detects file type from an actual JPEG file" do
      bytes = ::File.read(image_path("jpeg.jpg")).to_slice
      Pdfbox::Util::FileTypeDetector.detect_file_type(bytes).should eq(Pdfbox::Util::FileType::Jpeg)
    end
  end

  describe "create_from_file_by_extension" do
    it "dispatches JPEG files to the JPEG factory (jpg suffix)" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_extension(image_path("jpeg.jpg"), doc)
      image.suffix.should eq("jpg")
      image.width.should eq(344)
      image.height.should eq(287)
      image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    ensure
      doc.try(&.close)
    end

    it "dispatches CMYK JPEG to the JPEG factory with CMYK color space" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_extension(image_path("jpegcmyk.jpg"), doc)
      image.suffix.should eq("jpg")
      image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE)
    ensure
      doc.try(&.close)
    end

    it "dispatches PNG files with png suffix" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_extension(image_path("png.png"), doc)
      image.suffix.should eq("png")
      image.width.should eq(343)
      image.height.should eq(287)
    ensure
      doc.try(&.close)
    end

    it "dispatches GIF files with png suffix" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_extension(image_path("gif.gif"), doc)
      image.suffix.should eq("png")
      image.width.should eq(343)
      image.height.should eq(287)
    ensure
      doc.try(&.close)
    end

    it "rejects an unsupported extension" do
      doc = Pdfbox::Pdmodel::Document.create
      expect_raises(::ArgumentError) do
        Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_extension(image_path("jpeg.jpg") + "nope", doc)
      end
    ensure
      doc.try(&.close)
    end
  end

  describe "create_from_file_by_content" do
    it "dispatches JPEG by magic bytes with jpg suffix" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_content(image_path("jpeg.jpg"), doc)
      image.suffix.should eq("jpg")
      image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    ensure
      doc.try(&.close)
    end

    it "dispatches PNG by magic bytes with png suffix" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_content(image_path("png.png"), doc)
      image.suffix.should eq("png")
    ensure
      doc.try(&.close)
    end

    it "dispatches GIF by magic bytes with png suffix" do
      doc = Pdfbox::Pdmodel::Document.create
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_content(image_path("gif.gif"), doc)
      image.suffix.should eq("png")
    ensure
      doc.try(&.close)
    end
  end

  describe "create_from_byte_array" do
    it "dispatches JPEG bytes with jpg suffix" do
      doc = Pdfbox::Pdmodel::Document.create
      bytes = ::File.read(image_path("jpeg.jpg")).to_slice
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_byte_array(doc, bytes, "jpeg.jpg")
      image.suffix.should eq("jpg")
      image.width.should eq(344)
      image.height.should eq(287)
    ensure
      doc.try(&.close)
    end

    it "dispatches PNG bytes with png suffix" do
      doc = Pdfbox::Pdmodel::Document.create
      bytes = ::File.read(image_path("png.png")).to_slice
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_byte_array(doc, bytes, "png.png")
      image.suffix.should eq("png")
    ensure
      doc.try(&.close)
    end

    it "dispatches GIF bytes with png suffix" do
      doc = Pdfbox::Pdmodel::Document.create
      bytes = ::File.read(image_path("gif.gif")).to_slice
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_byte_array(doc, bytes, "gif.gif")
      image.suffix.should eq("png")
    ensure
      doc.try(&.close)
    end
  end
end

require "../spec_helper"

describe "Porting parity pdfbox-tvk" do
  # Source of truth:
  # vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/imageio/ImageIOUtil.java
  # vendor/pdfbox/tools/src/test/java/org/apache/pdfbox/tools/imageio/TestImageIOUtils.java
  it "derives format name from filename suffix like ImageIOUtil" do
    Tools::Imageio::ImageIOUtil.format_name_from_filename("out/page-1.png").should eq("png")
    Tools::Imageio::ImageIOUtil.format_name_from_filename("image.jpg").should eq("jpg")
    Tools::Imageio::ImageIOUtil.format_name_from_filename("no_suffix").should eq("no_suffix")
  end

  it "uses PNG-specific default compression quality" do
    Tools::Imageio::ImageIOUtil.default_compression_quality("png").should eq(0_f32)
    Tools::Imageio::ImageIOUtil.default_compression_quality("PNG").should eq(0_f32)
    Tools::Imageio::ImageIOUtil.default_compression_quality("jpg").should eq(1_f32)
    Tools::Imageio::ImageIOUtil.default_compression_quality("tif").should eq(1_f32)
  end

  it "detects tif/tiff formats with Java startsWith behavior" do
    Tools::Imageio::ImageIOUtil.tif_format?("tif").should be_true
    Tools::Imageio::ImageIOUtil.tif_format?("TIFF").should be_true
    Tools::Imageio::ImageIOUtil.tif_format?("png").should be_false
  end
end

require "../spec_helper"
require "../../src/tools"

private def png_dimensions(path : String) : {UInt32, UInt32}
  bytes = File.read(path).to_slice
  width = (bytes[16].to_u32 << 24) | (bytes[17].to_u32 << 16) | (bytes[18].to_u32 << 8) | bytes[19].to_u32
  height = (bytes[20].to_u32 << 24) | (bytes[21].to_u32 << 16) | (bytes[22].to_u32 << 8) | bytes[23].to_u32
  {width, height}
end

describe Tools::PDFToImage do
  hello3_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")

  it "reports missing input file" do
    err = IO::Memory.new
    tool = Tools::PDFToImage.new(IO::Memory.new, err)
    result = tool.call([] of String)
    result.should eq(1)
    err.to_s.should contain("Missing required option: -i")
  end

  it "returns error for nonexistent input file" do
    err = IO::Memory.new
    tool = Tools::PDFToImage.new(IO::Memory.new, err)
    result = tool.call(["-i", "nonexistent.pdf"])
    result.should eq(1)
  end

  it "writes a PNG for the selected page" do
    prefix = File.tempname("pdfbox_pdftoimage_", "")
    path = "#{prefix}-1.png"
    begin
      stderr = IO::Memory.new
      tool = Tools::PDFToImage.new(IO::Memory.new, stderr)
      result = tool.call(["-i", hello3_path, "--format", "png", "--page", "1", "--prefix", prefix, "--dpi", "72"])
      result.should eq(0)
      File.exists?(path).should be_true
      bytes = File.read(path).to_slice
      bytes[0, 8].should eq(Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
      png_dimensions(path).should eq({612_u32, 792_u32})
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "scales output dimensions with DPI" do
    prefix = File.tempname("pdfbox_pdftoimage_dpi_", "")
    path = "#{prefix}-1.png"
    begin
      tool = Tools::PDFToImage.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--format", "png", "--page", "1", "--prefix", prefix, "--dpi", "144"])
      result.should eq(0)
      png_dimensions(path).should eq({1224_u32, 1584_u32})
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "derives the default prefix from the input filename" do
    dir = File.tempname("pdfbox_pdftoimage_dir_", "")
    Dir.mkdir_p(dir)
    input = File.join(dir, "sample.pdf")
    File.copy(hello3_path, input)
    path = File.join(dir, "sample-1.png")
    begin
      tool = Tools::PDFToImage.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", input, "--format", "png", "--page", "1"])
      result.should eq(0)
      File.exists?(path).should be_true
    ensure
      File.delete(path) if File.exists?(path)
      File.delete(input) if File.exists?(input)
      Dir.delete(dir) if Dir.exists?(dir)
    end
  end

  it "writes a grayscale PNG when --color GRAY is used" do
    prefix = File.tempname("pdfbox_pdftoimage_gray_", "")
    path = "#{prefix}-1.png"
    begin
      tool = Tools::PDFToImage.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--format", "png", "--page", "1", "--prefix", prefix, "--color", "GRAY"])
      result.should eq(0)
      File.read(path).to_slice[25].should eq(0_u8)
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "applies --cropbox to the rendered area" do
    prefix = File.tempname("pdfbox_pdftoimage_crop_", "")
    path = "#{prefix}-1.png"
    begin
      tool = Tools::PDFToImage.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--format", "png", "--page", "1", "--prefix", prefix,
                          "--dpi", "72", "--cropbox", "0", "0", "306", "396"])
      result.should eq(0)
      png_dimensions(path).should eq({306_u32, 396_u32})
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "writes a JPEG when --format jpg is used and accepts --subsampling" do
    prefix = File.tempname("pdfbox_pdftoimage_jpg_", "")
    path = "#{prefix}-1.jpg"
    begin
      tool = Tools::PDFToImage.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--format", "jpg", "--page", "1", "--prefix", prefix,
                          "--quality", "0.8", "--subsampling"])
      result.should eq(0)
      File.read(path).to_slice[0, 2].should eq(Bytes[0xFF, 0xD8])
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "rejects an unsupported image format with exit code 2" do
    err = IO::Memory.new
    tool = Tools::PDFToImage.new(IO::Memory.new, err)
    result = tool.call(["-i", hello3_path, "--format", "xyz"])
    result.should eq(2)
    err.to_s.should contain("Invalid image format")
  end

  it "prints timing information when --time is set" do
    prefix = File.tempname("pdfbox_pdftoimage_time_", "")
    path = "#{prefix}-1.png"
    begin
      err = IO::Memory.new
      tool = Tools::PDFToImage.new(IO::Memory.new, err)
      result = tool.call(["-i", hello3_path, "--format", "png", "--page", "1", "--prefix", prefix, "--time"])
      result.should eq(0)
      err.to_s.should contain("Rendered 1 page")
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "accepts -outputPrefix alias for -prefix" do
    prefix = File.tempname("pdfbox_pdftoimage_alias_", "")
    path = "#{prefix}-1.png"
    begin
      tool = Tools::PDFToImage.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--format", "png", "--page", "1", "--outputPrefix", prefix])
      result.should eq(0)
      File.exists?(path).should be_true
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "accepts -resolution alias for -dpi" do
    prefix = File.tempname("pdfbox_pdftoimage_res_", "")
    path = "#{prefix}-1.png"
    begin
      tool = Tools::PDFToImage.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--format", "png", "--page", "1", "--prefix", prefix, "--resolution", "72"])
      result.should eq(0)
      png_dimensions(path).should eq({612_u32, 792_u32})
    ensure
      File.delete(path) if File.exists?(path)
    end
  end
end

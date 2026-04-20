require "../spec_helper"

private JPEG_PATH = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg.jpg")
private PNG_PATH  = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/png.png")

# Source of truth: vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/ImageToPDF.java
describe Tools::ImageToPDF do
  it "converts a single JPEG to PDF" do
    outfile = File.tempname("pdfbox_fromimage_test_", ".pdf")
    begin
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::ImageToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", JPEG_PATH, "-o", outfile])

      exit_code.should eq(0)
      File.exists?(outfile).should be_true

      doc = Pdfbox::Pdmodel::Document.load(outfile)
      doc.number_of_pages.should eq(1)
      doc.close
    ensure
      File.delete(outfile) if File.exists?(outfile)
    end
  end

  it "converts a single PNG to PDF" do
    outfile = File.tempname("pdfbox_fromimage_test_", ".pdf")
    begin
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::ImageToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", PNG_PATH, "-o", outfile])

      exit_code.should eq(0)
      File.exists?(outfile).should be_true

      doc = Pdfbox::Pdmodel::Document.load(outfile)
      doc.number_of_pages.should eq(1)
      doc.close
    ensure
      File.delete(outfile) if File.exists?(outfile)
    end
  end

  it "converts multiple images to multi-page PDF" do
    outfile = File.tempname("pdfbox_fromimage_test_", ".pdf")
    begin
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::ImageToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", JPEG_PATH, "-i", PNG_PATH, "-o", outfile])

      exit_code.should eq(0)

      doc = Pdfbox::Pdmodel::Document.load(outfile)
      doc.number_of_pages.should eq(2)
      doc.close
    ensure
      File.delete(outfile) if File.exists?(outfile)
    end
  end

  it "respects -pageSize option" do
    outfile = File.tempname("pdfbox_fromimage_test_", ".pdf")
    begin
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::ImageToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", JPEG_PATH, "-o", outfile, "-pageSize", "A4"])

      exit_code.should eq(0)

      doc = Pdfbox::Pdmodel::Document.load(outfile)
      page = doc.pages[0]
      media_box = page.media_box
      media_box.should_not be_nil
      # A4 = 595 x 842
      media_box.as(Pdfbox::Pdmodel::Rectangle).width.should eq(595.0)
      media_box.as(Pdfbox::Pdmodel::Rectangle).height.should eq(842.0)
      doc.close
    ensure
      File.delete(outfile) if File.exists?(outfile)
    end
  end

  it "respects -landscape option" do
    outfile = File.tempname("pdfbox_fromimage_test_", ".pdf")
    begin
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::ImageToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", JPEG_PATH, "-o", outfile, "--landscape"])

      exit_code.should eq(0)

      doc = Pdfbox::Pdmodel::Document.load(outfile)
      page = doc.pages[0]
      media_box = page.media_box
      media_box.should_not be_nil
      # Letter landscape = 792 x 612
      media_box.as(Pdfbox::Pdmodel::Rectangle).width.should eq(792.0)
      media_box.as(Pdfbox::Pdmodel::Rectangle).height.should eq(612.0)
      doc.close
    ensure
      File.delete(outfile) if File.exists?(outfile)
    end
  end

  it "reports error for missing -i" do
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    tool = Tools::ImageToPDF.new(stdout, stderr)
    exit_code = tool.call(["-o", "out.pdf"])
    exit_code.should eq(1)
    stderr.to_s.should contain("Missing required option: -i")
  end

  it "reports error for missing -o" do
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    tool = Tools::ImageToPDF.new(stdout, stderr)
    exit_code = tool.call(["-i", "dummy.jpg"])
    exit_code.should eq(1)
    stderr.to_s.should contain("Missing required option: -o")
  end

  it "reports error for nonexistent input file" do
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    tool = Tools::ImageToPDF.new(stdout, stderr)
    exit_code = tool.call(["-i", "/nonexistent/file.jpg", "-o", "out.pdf"])
    exit_code.should eq(1)
    stderr.to_s.should contain("Input file does not exist")
  end
end

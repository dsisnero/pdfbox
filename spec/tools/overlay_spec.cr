require "../spec_helper"

private JPEG_PATH = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg.jpg")
private PNG_PATH  = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/png.png")

# Source of truth: vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/OverlayPDF.java
describe Tools::Overlay do
  describe "#call" do
    it "returns error when -i is missing" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::Overlay.new(stdout, stderr)
      exit_code = tool.call(["-o", "out.pdf"])
      exit_code.should eq(1)
      stderr.to_s.should contain("Missing required option: -i")
    end

    it "returns error when -o is missing" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::Overlay.new(stdout, stderr)
      exit_code = tool.call(["-i", "test.pdf"])
      exit_code.should eq(1)
      stderr.to_s.should contain("Missing required option: -o")
    end

    it "returns error for nonexistent input file" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::Overlay.new(stdout, stderr)
      exit_code = tool.call(["-i", "/nonexistent/file.pdf", "-o", "out.pdf"])
      exit_code.should eq(1)
      stderr.to_s.should contain("Input file not found")
    end
  end

  describe "overlay functionality" do
    it "applies default overlay to all pages" do
      input_file = File.tempname("pdfbox_overlay_input_", ".pdf")
      overlay_file = File.tempname("pdfbox_overlay_overlay_", ".pdf")
      output_file = File.tempname("pdfbox_overlay_output_", ".pdf")
      begin
        # Create input PDF with an image
        tool = Tools::ImageToPDF.new(IO::Memory.new, IO::Memory.new)
        tool.call(["-i", JPEG_PATH, "-o", input_file])

        # Create overlay PDF with a different image
        tool2 = Tools::ImageToPDF.new(IO::Memory.new, IO::Memory.new)
        tool2.call(["-i", PNG_PATH, "-o", overlay_file])

        # Apply overlay
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        overlayer = Tools::Overlay.new(stdout, stderr)
        exit_code = overlayer.call([
          "-i", input_file,
          "-o", output_file,
          "--default", overlay_file,
        ])

        exit_code.should eq(0)
        File.exists?(output_file).should be_true
        File.size(output_file).should be > 0

        # Verify the output can be loaded
        doc = Pdfbox::Pdmodel::Document.load(output_file)
        doc.number_of_pages.should eq(1)
        doc.close
      ensure
        File.delete(input_file) if File.exists?(input_file)
        File.delete(overlay_file) if File.exists?(overlay_file)
        File.delete(output_file) if File.exists?(output_file)
      end
    end

    it "applies overlay with FOREGROUND position" do
      input_file = File.tempname("pdfbox_overlay_input_", ".pdf")
      overlay_file = File.tempname("pdfbox_overlay_overlay_", ".pdf")
      output_file = File.tempname("pdfbox_overlay_output_", ".pdf")
      begin
        # Create input PDF
        tool = Tools::TextToPDF.new(IO::Memory.new, IO::Memory.new)
        tool.call(["-i", "/dev/null", "-o", input_file]) rescue nil
        # Just create a basic PDF if /dev/null fails
        unless File.exists?(input_file)
          doc = Pdfbox::Pdmodel::Document.create
          doc.add_page(Pdfbox::Pdmodel::Page.new)
          doc.save(input_file)
        end

        # Create overlay PDF
        doc2 = Pdfbox::Pdmodel::Document.create
        doc2.add_page(Pdfbox::Pdmodel::Page.new)
        doc2.save(overlay_file)

        # Apply overlay in foreground
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        overlayer = Tools::Overlay.new(stdout, stderr)
        exit_code = overlayer.call([
          "-i", input_file,
          "-o", output_file,
          "--default", overlay_file,
          "--position", "FOREGROUND",
        ])

        exit_code.should eq(0)
        File.exists?(output_file).should be_true

        doc = Pdfbox::Pdmodel::Document.load(output_file)
        doc.number_of_pages.should eq(1)
        doc.close
      ensure
        File.delete(input_file) if File.exists?(input_file)
        File.delete(overlay_file) if File.exists?(overlay_file)
        File.delete(output_file) if File.exists?(output_file)
      end
    end
  end
end

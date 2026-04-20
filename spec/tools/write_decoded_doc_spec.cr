require "../spec_helper"

private JPEG_PATH = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg.jpg")

# Source of truth: vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/WriteDecodedDoc.java
describe Tools::WriteDecodedDoc do
  it "decodes a PDF and produces output file" do
    pdf_file = File.tempname("pdfbox_decode_input_", ".pdf")
    decoded_file = File.tempname("pdfbox_decode_output_", "_unc.pdf")
    begin
      # Create a PDF first
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::ImageToPDF.new(stdout, stderr)
      tool.call(["-i", JPEG_PATH, "-o", pdf_file])

      # Decode it
      decode_stdout = IO::Memory.new
      decode_stderr = IO::Memory.new
      decoder = Tools::WriteDecodedDoc.new(decode_stdout, decode_stderr)
      exit_code = decoder.call([pdf_file, decoded_file])

      exit_code.should eq(0)
      File.exists?(decoded_file).should be_true
      File.size(decoded_file).should be > 0
    ensure
      File.delete(pdf_file) if File.exists?(pdf_file)
      File.delete(decoded_file) if File.exists?(decoded_file)
    end
  end

  it "auto-generates output filename with _unc suffix" do
    pdf_file = File.tempname("pdfbox_decode_input_", ".pdf")
    begin
      # Create a PDF first
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::ImageToPDF.new(stdout, stderr)
      tool.call(["-i", JPEG_PATH, "-o", pdf_file])

      # Decode without specifying output
      decode_stdout = IO::Memory.new
      decode_stderr = IO::Memory.new
      decoder = Tools::WriteDecodedDoc.new(decode_stdout, decode_stderr)
      exit_code = decoder.call([pdf_file])

      exit_code.should eq(0)
      auto_output = pdf_file.gsub(/\.pdf$/, "_unc.pdf")
      File.exists?(auto_output).should be_true
    ensure
      File.delete(pdf_file) if File.exists?(pdf_file)
      auto_output = pdf_file.gsub(/\.pdf$/, "_unc.pdf")
      File.delete(auto_output) if File.exists?(auto_output)
    end
  end

  it "reports error for nonexistent input file" do
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    decoder = Tools::WriteDecodedDoc.new(stdout, stderr)
    exit_code = decoder.call(["/nonexistent/file.pdf"])
    exit_code.should eq(1)
    stderr.to_s.should contain("Input file not found")
  end

  it "reports error for missing input file" do
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    decoder = Tools::WriteDecodedDoc.new(stdout, stderr)
    exit_code = decoder.call([] of String)
    exit_code.should eq(1)
    stderr.to_s.should contain("Missing required input file")
  end

  it "dispatches via pdfbox decode" do
    pdf_file = File.tempname("pdfbox_decode_dispatch_input_", ".pdf")
    decoded_file = File.tempname("pdfbox_decode_dispatch_output_", "_unc.pdf")
    begin
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      Tools::ImageToPDF.new(stdout, stderr).call(["-i", JPEG_PATH, "-o", pdf_file]).should eq(0)

      decode_stdout = IO::Memory.new
      decode_stderr = IO::Memory.new
      exit_code = Tools::PDFBox.main(["decode", pdf_file, decoded_file], stdout_io: decode_stdout, stderr_io: decode_stderr, headless: true)

      exit_code.should eq(0)
      File.exists?(decoded_file).should be_true
      File.size(decoded_file).should be > 0
    ensure
      File.delete(pdf_file) if File.exists?(pdf_file)
      File.delete(decoded_file) if File.exists?(decoded_file)
    end
  end
end

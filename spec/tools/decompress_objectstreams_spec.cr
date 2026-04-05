require "../spec_helper"
require "../../src/tools"

private JPEG_PATH = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image/jpeg.jpg")

describe Tools::DecompressObjectstreams do
  it "decompresses a PDF to an explicit output path" do
    pdf_file = File.tempname("pdfbox_decompress_input_", ".pdf")
    output_file = File.tempname("pdfbox_decompress_output_", ".pdf")
    begin
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      Tools::ImageToPDF.new(stdout, stderr).call(["-i", JPEG_PATH, "-o", pdf_file]).should eq(0)

      tool_stdout = IO::Memory.new
      tool_stderr = IO::Memory.new
      exit_code = Tools::DecompressObjectstreams.new(tool_stdout, tool_stderr).call(["-i", pdf_file, "-o", output_file])

      exit_code.should eq(0)
      File.exists?(output_file).should be_true
      File.size(output_file).should be > 0
    ensure
      File.delete(pdf_file) if File.exists?(pdf_file)
      File.delete(output_file) if File.exists?(output_file)
    end
  end
end

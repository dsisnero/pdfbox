require "../spec_helper"
require "../../src/tools"
require "file_utils"

private TESTFILE1 = SpecPaths.resolve("vendor/pdfbox/tools/src/test/resources/org/apache/pdfbox/testPDFPackage.pdf")
private TESTFILE2 = SpecPaths.resolve("vendor/pdfbox/tools/src/test/resources/org/apache/pdfbox/hello3.pdf")
private TESTFILE3 = SpecPaths.resolve("vendor/pdfbox/tools/src/test/resources/org/apache/pdfbox/AngledExample.pdf")

private def extract_text_temp_file(name : String) : String
  dir = (SpecPaths::PROJECT_ROOT / "temp" / "extract-text-spec").to_s
  FileUtils.mkdir_p(dir)
  File.join(dir, name)
end

describe Tools::ExtractText do
  it "TestExtractText#testEmbeddedPDFs" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::ExtractText.new(stdout_io, stderr_io).call(["-i", TESTFILE1, "-console"])

    code.should eq(0)
    result = stdout_io.to_s
    result.should contain("PDF1")
    result.should contain("PDF2")
    result.should_not contain("PDF file: #{Path[TESTFILE1]}")
    result.should_not contain("Hello")
    result.should_not contain("World.")
    result.should_not contain("PDF file: #{Path[TESTFILE2]}")
  end

  it "TestExtractText#testAddFileName" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::ExtractText.new(stdout_io, stderr_io).call(["-i", TESTFILE1, "-console", "-addFileName"])

    code.should eq(0)
    result = stdout_io.to_s
    result.should contain("PDF1")
    result.should contain("PDF2")
    result.should contain("PDF file: #{Path[TESTFILE1]}")
    result.should_not contain("Hello")
    result.should_not contain("World.")
    result.should_not contain("PDF file: #{Path[TESTFILE2]}")
  end

  it "TestExtractText#testPDFBoxRepeatableSubcommand" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::ExtractText.new(stdout_io, stderr_io).call(["-i", TESTFILE2, "-console"])

    code.should eq(0)
    result = stdout_io.to_s
    result.should contain("World.")
  end

  it "TestExtractText#testPDFBoxRepeatableSubcommandAddFileName" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::ExtractText.new(stdout_io, stderr_io).call(["-i", TESTFILE2, "-console", "-addFileName"])

    code.should eq(0)
    result = stdout_io.to_s
    result.should contain("World.")
    result.should contain("PDF file: #{Path[TESTFILE2]}")
  end

  it "TestExtractText#testPDFBoxRepeatableSubcommandAddFileNameOutfile" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::ExtractText.new(stdout_io, stderr_io).call(["-i", TESTFILE2, "-console", "-addFileName", "-o", "test.txt"])

    code.should eq(0)
    result = stdout_io.to_s
    result.should contain("World.")
    result.should contain("PDF file: #{Path[TESTFILE2]}")
  end

  it "TestExtractText#testPDFBoxRepeatableSubcommandAddFileNameMulti" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::PDFBox.main(["export:text", "-i", TESTFILE1, "-console", "-addFileName",
                               "export:text", "-i", TESTFILE2, "-console", "-addFileName"],
      stdout_io: stdout_io, stderr_io: stderr_io, headless: true)

    code.should eq(0)
    result = stdout_io.to_s
    result.should contain("PDF1")
    result.should contain("PDF2")
    result.should contain("PDF file: #{Path[TESTFILE1]}")
    result.should contain("Hello")
    result.should contain("World.")
    result.should contain("PDF file: #{Path[TESTFILE2]}")
  end

  it "TestExtractText#testPDFBoxRepeatableSubcommandAddFileNameOutfileMulti" do
    outfile = extract_text_temp_file("outfile.txt")
    File.delete?(outfile)
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::PDFBox.main(["export:text", "-i", TESTFILE1, "-encoding", "UTF-8", "-addFileName", "-o", outfile,
                               "export:text", "-i", TESTFILE2, "-encoding", "UTF-8", "-addFileName", "-o", outfile],
      stdout_io: stdout_io, stderr_io: stderr_io, headless: true)

    code.should eq(0)
    result = File.read(outfile)
    result.should_not contain("PDF1")
    result.should_not contain("PDF2")
    result.should_not contain("PDF file: #{Path[TESTFILE1]}")
    result.should contain("Hello")
    result.should contain("World.")
    result.should contain("PDF file: #{Path[TESTFILE2]}")
  end

  it "TestExtractText#testPDFBoxRepeatableSubcommandAddFileNameOutfileAppend" do
    outfile = extract_text_temp_file("outfile-append.txt")
    File.delete?(outfile)
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::PDFBox.main(["export:text", "-i", TESTFILE1, "-encoding", "UTF-8", "-addFileName", "-o", outfile,
                               "export:text", "-i", TESTFILE2, "-encoding", "UTF-8", "-addFileName", "-o", outfile, "-append"],
      stdout_io: stdout_io, stderr_io: stderr_io, headless: true)

    code.should eq(0)
    result = File.read(outfile)
    result.should contain("PDF1")
    result.should contain("PDF2")
    result.should contain("PDF file: #{Path[TESTFILE1]}")
    result.should contain("Hello")
    result.should contain("World.")
    result.should contain("PDF file: #{Path[TESTFILE2]}")
  end

  it "TestExtractText#testRotationMagic" do
    outfile = extract_text_temp_file("rotation-outfile.txt")
    File.delete?(outfile)
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::PDFBox.main(["export:text", "-rotationMagic", "-i", TESTFILE3, "-o", outfile],
      stdout_io: stdout_io, stderr_io: stderr_io, headless: true)

    code.should eq(0)
    result = File.read(outfile)
    result.should contain("Horizontal Text")
    result.should contain("Vertical Text")
  end
end

require "../spec_helper"
require "../../src/tools"

describe Tools::PDFToImage do
  hello3_path = File.expand_path("../../../vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf", __DIR__)

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

  it "accepts format option" do
    if File.exists?(hello3_path)
      stderr = IO::Memory.new
      stdout = IO::Memory.new
      tool = Tools::PDFToImage.new(stdout, stderr)
      result = tool.call(["-i", hello3_path, "--format", "png", "--page", "1"])
      result.should eq(0)
    end
  end

  it "accepts page range options" do
    if File.exists?(hello3_path)
      stderr = IO::Memory.new
      stdout = IO::Memory.new
      tool = Tools::PDFToImage.new(stdout, stderr)
      result = tool.call(["-i", hello3_path, "--startPage", "1", "--endPage", "1"])
      result.should eq(0)
    end
  end

  it "accepts color and dpi options" do
    if File.exists?(hello3_path)
      stderr = IO::Memory.new
      stdout = IO::Memory.new
      tool = Tools::PDFToImage.new(stdout, stderr)
      result = tool.call(["-i", hello3_path, "--color", "GRAY", "--dpi", "72", "--page", "1"])
      result.should eq(0)
    end
  end

  it "accepts quality and subsampling options" do
    if File.exists?(hello3_path)
      stderr = IO::Memory.new
      stdout = IO::Memory.new
      tool = Tools::PDFToImage.new(stdout, stderr)
      result = tool.call(["-i", hello3_path, "--quality", "0.8", "--subsample", "--page", "1"])
      result.should eq(0)
    end
  end
end

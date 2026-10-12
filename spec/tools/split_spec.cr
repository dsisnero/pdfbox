require "../spec_helper"
require "../../src/tools"

describe Tools::Split do
  hello3_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")

  it "reports missing input file" do
    err = IO::Memory.new
    split = Tools::Split.new(IO::Memory.new, err)
    result = split.call([] of String)
    result.should eq(1)
    err.to_s.should contain("Missing required option: -i")
  end

  it "splits a PDF into single-page files by default" do
    prefix = File.tempname("pdfbox_split_", "")
    out1 = "#{prefix}-1.pdf"
    begin
      tool = Tools::Split.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--outputPrefix", prefix])
      result.should eq(0)
      File.exists?(out1).should be_true
      doc = Pdfbox::Loader.load_pdf(out1)
      doc.number_of_pages.should eq(1)
      doc.close
    ensure
      File.delete(out1) if File.exists?(out1)
    end
  end

  it "splits a PDF by page count with --split" do
    prefix = File.tempname("pdfbox_split_n_", "")
    out1 = "#{prefix}-1.pdf"
    begin
      tool = Tools::Split.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--outputPrefix", prefix, "--split", "1"])
      result.should eq(0)
      File.exists?(out1).should be_true
      doc = Pdfbox::Loader.load_pdf(out1)
      doc.number_of_pages.should eq(1)
      doc.close
    ensure
      File.delete(out1) if File.exists?(out1)
    end
  end

  it "extracts a page range named like Java (prefix-1.pdf)" do
    prefix = File.tempname("pdfbox_split_range_", "")
    out_file = "#{prefix}-1.pdf"
    begin
      tool = Tools::Split.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", hello3_path, "--outputPrefix", prefix, "--startPage", "1", "--endPage", "1"])
      result.should eq(0)
      File.exists?(out_file).should be_true
      doc = Pdfbox::Loader.load_pdf(out_file)
      doc.number_of_pages.should eq(1)
      doc.close
    ensure
      File.delete(out_file) if File.exists?(out_file)
    end
  end

  it "rejects an out-of-range start page" do
    prefix = File.tempname("pdfbox_split_oob_", "")
    err = IO::Memory.new
    tool = Tools::Split.new(IO::Memory.new, err)
    result = tool.call(["-i", hello3_path, "--outputPrefix", prefix, "--startPage", "99"])
    result.should eq(1)
    err.to_s.should contain("out of range")
  end

  it "uses the absolute input path (minus extension) as the default prefix" do
    dir = File.tempname("pdfbox_split_dir_", "")
    Dir.mkdir_p(dir)
    input = File.join(dir, "sample.pdf")
    File.copy(hello3_path, input)
    out_file = File.join(dir, "sample-1.pdf")
    begin
      tool = Tools::Split.new(IO::Memory.new, IO::Memory.new)
      result = tool.call(["-i", input])
      result.should eq(0)
      File.exists?(out_file).should be_true
    ensure
      File.delete(out_file) if File.exists?(out_file)
      File.delete(input) if File.exists?(input)
      Dir.delete(dir) if Dir.exists?(dir)
    end
  end
end

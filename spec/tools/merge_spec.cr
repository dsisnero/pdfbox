require "../spec_helper"
require "../../src/tools"

describe Tools::Merge do
  hello3_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")

  it "reports missing input file" do
    err = IO::Memory.new
    merge = Tools::Merge.new(IO::Memory.new, err)
    result = merge.call([] of String)
    result.should eq(1)
    err.to_s.should contain("Missing required option: -i")
  end

  it "reports missing output file" do
    err = IO::Memory.new
    merge = Tools::Merge.new(IO::Memory.new, err)
    result = merge.call(["-i", hello3_path])
    result.should eq(1)
    err.to_s.should contain("Missing required option: -o")
  end

  it "merges two PDF files into a document with combined pages" do
    out_path = File.tempname("pdfbox_merge_", ".pdf")
    begin
      merge = Tools::Merge.new(IO::Memory.new, IO::Memory.new)
      result = merge.call(["-i", hello3_path, "-i", hello3_path, "-o", out_path])
      result.should eq(0)
      File.exists?(out_path).should be_true

      merged = Pdfbox::Loader.load_pdf(out_path)
      merged.number_of_pages.should eq(2)
      merged.close
    ensure
      File.delete(out_path) if File.exists?(out_path)
    end
  end

  it "rejects a nonexistent input file" do
    err = IO::Memory.new
    merge = Tools::Merge.new(IO::Memory.new, err)
    result = merge.call(["-i", "missing-input.pdf", "-o", "out.pdf"])
    result.should eq(1)
    err.to_s.should contain("does not exist")
  end
end

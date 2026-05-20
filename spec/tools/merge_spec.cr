require "../spec_helper"
require "../../src/tools"

describe Tools::Merge do
  hello3_path = File.expand_path("../../../vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf", __DIR__)

  it "reports missing input file" do
    err = IO::Memory.new
    merge = Tools::Merge.new(IO::Memory.new, err)
    result = merge.call([] of String)
    result.should eq(1)
    err.to_s.should contain("Missing required option: -i")
  end

  it "reports missing output file" do
    if File.exists?(hello3_path)
      err = IO::Memory.new
      merge = Tools::Merge.new(IO::Memory.new, err)
      result = merge.call(["-i", hello3_path])
      result.should eq(1)
      err.to_s.should contain("Missing required option: -o")
    end
  end

  it "merges two PDF files" do
    if File.exists?(hello3_path)
      out_path = File.expand_path("../../../temp/merged_test.pdf", __DIR__)
      Dir.mkdir_p(File.dirname(out_path))

      merge = Tools::Merge.new(IO::Memory.new, IO::Memory.new)
      result = merge.call(["-i", hello3_path, "-i", hello3_path, "-o", out_path])
      result.should eq(0)

      merged = Pdfbox::Loader.load_pdf(out_path)
      merged.number_of_pages.should eq(2)
      merged.close

      File.delete(out_path) if File.exists?(out_path)
    end
  end
end

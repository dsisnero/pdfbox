require "../spec_helper"
require "../../src/tools"

describe Tools::Split do
  hello3_path = File.expand_path("../../../vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf", __DIR__)

  it "reports missing input file" do
    err = IO::Memory.new
    split = Tools::Split.new(IO::Memory.new, err)
    result = split.call([] of String)
    result.should eq(1)
    err.to_s.should contain("Missing required option: -i")
  end

  it "splits a PDF by page range" do
    if File.exists?(hello3_path)
      out_dir = File.expand_path("../../../temp", __DIR__)
      Dir.mkdir_p(out_dir)

      split = Tools::Split.new(IO::Memory.new, IO::Memory.new)
      result = split.call(["-i", hello3_path, "--startPage", "1", "--endPage", "1"])
      result.should eq(0)
    end
  end

  it "splits a PDF into single-page files" do
    if File.exists?(hello3_path)
      split = Tools::Split.new(IO::Memory.new, IO::Memory.new)
      result = split.call(["-i", hello3_path, "--split", "1"])
      result.should eq(0)
    end
  end
end

require "../spec_helper"
require "../../src/tools"

describe Tools::PDFBox do
  it "PDFBoxHeadlessTest#isHeadlessTest" do
    Tools::PDFBox.new(headless: true).headless?.should be_true
  end

  it "PDFBoxHeadlessTest#isHeadlessPDFBoxTest" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::PDFBox.main(["debug"], stdout_io: stdout_io, stderr_io: stderr_io, headless: true)

    code.should eq(0)
    stderr_io.to_s.should contain("Unmatched argument at index 0: 'debug'")
  end

  it "PDFBoxNonHeadlessTest#isNonHeadlessTest" do
    Tools::PDFBox.new(headless: false).headless?.should be_false
  end

  it "PDFBoxNonHeadlessTest#isNonHeadlessPDFBoxTest" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    code = Tools::PDFBox.main(["debug"], stdout_io: stdout_io, stderr_io: stderr_io, headless: false)

    code.should eq(0)
    stderr_io.to_s.should_not contain("Unmatched argument at index 0: 'debug'")
  end
end

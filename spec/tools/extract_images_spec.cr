require "../spec_helper"

# No dedicated Java ExtractImages test exists.
# Source of truth: vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/ExtractImages.java
describe Tools::ExtractImages do
  describe "#call" do
    it "returns error when input file doesn't exist" do
      tool = Tools::ExtractImages.new
      result = tool.call(["-i", "nonexistent.pdf"])
      result.should eq(1)
    end

    it "returns error when -i flag is missing" do
      output = IO::Memory.new
      error = IO::Memory.new
      tool = Tools::ExtractImages.new(output, error)
      result = tool.call([] of String)
      result.should eq(1)
      error.to_s.should contain("Missing required option: -i")
    end

    it "returns error for nonexistent file with -useDirectJPEG" do
      tool = Tools::ExtractImages.new
      result = tool.call(["-useDirectJPEG", "-i", "test.pdf"])
      result.should eq(1)
    end

    it "returns error for nonexistent file with -noColorConvert" do
      tool = Tools::ExtractImages.new
      result = tool.call(["-noColorConvert", "-i", "test.pdf"])
      result.should eq(1)
    end

    it "returns error for nonexistent file with -prefix" do
      tool = Tools::ExtractImages.new
      result = tool.call(["-prefix", "myprefix", "-i", "test.pdf"])
      result.should eq(1)
    end
  end
end

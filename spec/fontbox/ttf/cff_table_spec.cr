require "../../spec_helper"

module Fontbox::TTF
  private class StubTrueTypeFontForCFF < TrueTypeFont
    def initialize
      super(RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)))
    end
  end

  describe CFFTable do
    it "reads and parses CFF data" do
      bytes = File.read("spec/resources/fonts/SourceSansProBold.otf").to_slice
      table = CFFTable.new
      table.length = bytes.size

      table.read(StubTrueTypeFontForCFF.new, RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(bytes)))

      table.initialized.should be_true
      table.font.should_not be_nil
      font = table.font || raise "expected parsed CFF font"
      font.name.should eq("SourceSansPro-Bold")
    end

    it "reads CFF headers without setting ROS for Type1 CFF fonts" do
      bytes = File.read("spec/resources/fonts/SourceSansProBold.otf").to_slice
      table = CFFTable.new
      table.length = bytes.size
      headers = FontHeaders.new

      table.read_headers(StubTrueTypeFontForCFF.new, RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(bytes)), headers)

      headers.otf_registry.should be_nil
      headers.otf_ordering.should be_nil
      headers.otf_supplement.should eq(0)
    end
  end
end

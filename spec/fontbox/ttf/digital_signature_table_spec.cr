require "../../spec_helper"

module Fontbox::TTF
  private class StubTrueTypeFontForDSIG < TrueTypeFont
    def initialize
      super(RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)))
    end
  end

  describe DigitalSignatureTable do
    it "marks DSIG table initialized when read" do
      table = DigitalSignatureTable.new
      table.read(StubTrueTypeFontForDSIG.new, RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)))

      table.initialized.should be_true
    end
  end
end

require "../../spec_helper"

module Fontbox::TTF
  private class StubTrueTypeFontForKerning < TrueTypeFont
    def initialize
      super(RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)))
    end
  end

  def self.stream_for_kerning(bytes : Bytes) : RandomAccessReadDataStream
    RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(bytes))
  end

  describe KerningTable do
    it "reads version 0 format 0 kerning pairs" do
      data = Bytes[
        0x00, 0x00, # table version
        0x00, 0x01, # num subtables
        0x00, 0x00, # subtable version
        0x00, 0x1A, # subtable length (26)
        0x00, 0x01, # coverage: horizontal, format 0
        0x00, 0x02, # numPairs
        0x00, 0x0C, # searchRange (12)
        0x00, 0x01, # entrySelector
        0x00, 0x00, # rangeShift
        0x00, 0x0A, # left
        0x00, 0x14, # right
        0xFF, 0xCE, # value -50
        0x00, 0x1E, # left
        0x00, 0x28, # right
        0x00, 0x64, # value 100
      ]

      table = KerningTable.new
      table.read(StubTrueTypeFontForKerning.new, Fontbox::TTF.stream_for_kerning(data))

      subtable = table.horizontal_kerning_subtable
      subtable.should_not be_nil
      s = subtable || raise "expected horizontal kerning subtable"
      s.kerning(10, 20).should eq(-50)
      s.kerning(30, 40).should eq(100)
      s.kerning(11, 20).should eq(0)
    end

    it "returns nil for unsupported kerning table version" do
      data = Bytes[
        0x00, 0x02, # high word of version
        0x00, 0x00, # low word -> version 0x00020000 unsupported
      ]

      table = KerningTable.new
      table.read(StubTrueTypeFontForKerning.new, Fontbox::TTF.stream_for_kerning(data))

      table.horizontal_kerning_subtable.should be_nil
    end
  end
end

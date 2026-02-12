require "../../spec_helper"

module Fontbox::TTF
  private class StubHeaderTableForLoca < HeaderTable
    def initialize(@loca_format : Int16)
      super()
    end

    # ameba:disable Naming/AccessorMethodName
    def index_to_loc_format : Int16
      @loca_format
    end
    # ameba:enable Naming/AccessorMethodName
  end

  private class StubTrueTypeFontForLoca < TrueTypeFont
    def initialize(@num_glyphs : Int32, @header : HeaderTable?)
      super(RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)))
    end

    # ameba:disable Naming/AccessorMethodName
    def header : HeaderTable?
      @header
    end

    # ameba:enable Naming/AccessorMethodName

    # ameba:disable Naming/AccessorMethodName
    def number_of_glyphs : Int32
      @num_glyphs
    end
    # ameba:enable Naming/AccessorMethodName
  end

  def self.stream_for_loca(bytes : Bytes) : RandomAccessReadDataStream
    RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(bytes))
  end

  describe IndexToLocationTable do
    it "reads short offsets and multiplies by 2" do
      # 3 unsigned shorts: 0, 2, 5
      data = Bytes[0x00, 0x00, 0x00, 0x02, 0x00, 0x05]
      table = IndexToLocationTable.new
      font = StubTrueTypeFontForLoca.new(2, StubHeaderTableForLoca.new(IndexToLocationTable::SHORT_OFFSETS.to_i16))

      table.read(font, Fontbox::TTF.stream_for_loca(data))

      table.offsets.should eq([0_i64, 4_i64, 10_i64])
    end

    it "reads long offsets" do
      # 3 unsigned ints: 0, 16, 32
      data = Bytes[0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x10,
        0x00, 0x00, 0x00, 0x20]
      table = IndexToLocationTable.new
      font = StubTrueTypeFontForLoca.new(2, StubHeaderTableForLoca.new(IndexToLocationTable::LONG_OFFSETS.to_i16))

      table.read(font, Fontbox::TTF.stream_for_loca(data))

      table.offsets.should eq([0_i64, 16_i64, 32_i64])
    end

    it "raises when head table is missing" do
      table = IndexToLocationTable.new
      font = StubTrueTypeFontForLoca.new(1, nil)

      expect_raises(IO::EOFError, "Could not get head table") do
        table.read(font, Fontbox::TTF.stream_for_loca(Bytes.empty))
      end
    end

    it "raises for unknown offset format" do
      table = IndexToLocationTable.new
      font = StubTrueTypeFontForLoca.new(1, StubHeaderTableForLoca.new(5_i16))

      expect_raises(IO::EOFError, "Error:TTF.loca unknown offset format: 5") do
        table.read(font, Fontbox::TTF.stream_for_loca(Bytes[0x00, 0x00, 0x00, 0x00]))
      end
    end

    it "raises for empty glyph font with one glyph" do
      table = IndexToLocationTable.new
      font = StubTrueTypeFontForLoca.new(1, StubHeaderTableForLoca.new(IndexToLocationTable::SHORT_OFFSETS.to_i16))

      expect_raises(IO::EOFError, "The font has no glyphs") do
        table.read(font, Fontbox::TTF.stream_for_loca(Bytes[0x00, 0x00, 0x00, 0x00]))
      end
    end
  end
end

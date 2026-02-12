require "../../spec_helper"

module Fontbox::TTF
  private class StubVerticalHeaderTable < VerticalHeaderTable
    def initialize(@metrics_count : UInt16)
      super()
    end

    # ameba:disable Naming/AccessorMethodName
    def get_number_of_v_metrics : UInt16
      @metrics_count
    end
    # ameba:enable Naming/AccessorMethodName
  end

  private class StubTrueTypeFontForVerticalMetrics < TrueTypeFont
    def initialize(@num_glyphs : Int32, @v_header : VerticalHeaderTable?)
      super(RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)))
    end

    # ameba:disable Naming/AccessorMethodName
    def get_vertical_header : VerticalHeaderTable?
      @v_header
    end

    # ameba:enable Naming/AccessorMethodName

    # ameba:disable Naming/AccessorMethodName
    def get_number_of_glyphs : Int32
      @num_glyphs
    end
    # ameba:enable Naming/AccessorMethodName
  end

  def self.stream_for_vertical(bytes : Bytes) : RandomAccessReadDataStream
    RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(bytes))
  end

  describe VerticalHeaderTable do
    it "reads vhea metrics" do
      data = Bytes[
        0x00, 0x01, 0x00, 0x00,
        0x03, 0xE8,
        0xFF, 0x38,
        0x00, 0x14,
        0x04, 0xB0,
        0x00, 0x0A,
        0xFF, 0xF1,
        0x03, 0x20,
        0x00, 0x01,
        0x00, 0x00,
        0x00, 0x02,
        0x00, 0x00,
        0x00, 0x00,
        0x00, 0x00,
        0x00, 0x00,
        0x00, 0x00,
        0x00, 0x02,
      ]

      table = VerticalHeaderTable.new
      table.read(StubTrueTypeFontForVerticalMetrics.new(0, nil), Fontbox::TTF.stream_for_vertical(data))

      table.version.should eq(1.0_f32)
      table.ascender.should eq(1000)
      table.descender.should eq(-200)
      table.line_gap.should eq(20)
      table.advance_height_max.should eq(1200_u16)
      table.min_top_side_bearing.should eq(10)
      table.min_bottom_side_bearing.should eq(-15)
      table.y_max_extent.should eq(800)
      table.number_of_v_metrics.should eq(2_u16)
    end
  end

  describe VerticalMetricsTable do
    it "reads vmtx metrics and additional side bearings" do
      data = Bytes[
        0x01, 0xF4, 0x00, 0x0A,
        0x02, 0x58, 0xFF, 0xEC,
        0x00, 0x1E, 0xFF, 0xD8,
      ]

      table = VerticalMetricsTable.new
      table.length = data.size
      font = StubTrueTypeFontForVerticalMetrics.new(4, StubVerticalHeaderTable.new(2_u16))
      table.read(font, Fontbox::TTF.stream_for_vertical(data))

      table.advance_height(0).should eq(500)
      table.advance_height(1).should eq(600)
      table.advance_height(3).should eq(600)
      table.top_side_bearing(0).should eq(10)
      table.top_side_bearing(1).should eq(-20)
      table.top_side_bearing(2).should eq(30)
      table.top_side_bearing(3).should eq(-40)
    end

    it "raises when vhea table is missing" do
      table = VerticalMetricsTable.new
      font = StubTrueTypeFontForVerticalMetrics.new(1, nil)

      expect_raises(IO::EOFError, "Could not get vhea table") do
        table.read(font, Fontbox::TTF.stream_for_vertical(Bytes.empty))
      end
    end
  end

  describe VerticalOriginTable do
    it "reads VORG defaults and per-glyph origins" do
      data = Bytes[
        0x00, 0x01, 0x00, 0x00,
        0x03, 0x70,
        0x00, 0x02,
        0x00, 0x05, 0x03, 0x84,
        0x00, 0x07, 0x03, 0x52,
      ]

      table = VerticalOriginTable.new
      table.read(StubTrueTypeFontForVerticalMetrics.new(0, nil), Fontbox::TTF.stream_for_vertical(data))

      table.version.should eq(1.0_f32)
      table.origin_y(5).should eq(900)
      table.origin_y(7).should eq(850)
      table.origin_y(6).should eq(880)
    end
  end
end

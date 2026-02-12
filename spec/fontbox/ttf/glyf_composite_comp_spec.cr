require "../../spec_helper"

module Fontbox::TTF
  describe GlyfCompositeComp do
    it "reads word xy arguments with uniform scale" do
      flags = GlyfCompositeComp::ARG_1_AND_2_ARE_WORDS | GlyfCompositeComp::ARGS_ARE_XY_VALUES | GlyfCompositeComp::WE_HAVE_A_SCALE
      data = Bytes[
        ((flags >> 8) & 0xFF).to_u8, (flags & 0xFF).to_u8,
        0x00, 0x12,
        0x00, 0x03,
        0xFF, 0xFC,
        0x20, 0x00,
      ]

      comp = GlyfCompositeComp.new(RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(data)))

      comp.glyph_index.should eq(18)
      comp.argument1.should eq(3)
      comp.argument2.should eq(-4)
      comp.x_translate.should eq(3)
      comp.y_translate.should eq(-4)
      comp.x_scale.should be_close(0.5, 0.00001)
      comp.y_scale.should be_close(0.5, 0.00001)
      comp.scale_x(10, 0).should eq(5)
      comp.scale_y(0, 10).should eq(5)
    end

    it "reads two-by-two transform and scales points" do
      flags = GlyfCompositeComp::ARG_1_AND_2_ARE_WORDS | GlyfCompositeComp::WE_HAVE_A_TWO_BY_TWO
      data = Bytes[
        ((flags >> 8) & 0xFF).to_u8, (flags & 0xFF).to_u8,
        0x00, 0x01,
        0x00, 0x02,
        0x00, 0x03,
        0x40, 0x00,
        0x20, 0x00,
        0xE0, 0x00,
        0x40, 0x00,
      ]

      comp = GlyfCompositeComp.new(RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(data)))

      comp.x_scale.should be_close(1.0, 0.00001)
      comp.scale01.should be_close(0.5, 0.00001)
      comp.scale10.should be_close(-0.5, 0.00001)
      comp.y_scale.should be_close(1.0, 0.00001)
      comp.scale_x(4, 2).should eq(3)
      comp.scale_y(4, 2).should eq(4)
    end
  end
end

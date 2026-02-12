require "../../spec_helper"

module Fontbox::TTF
  describe GlyfSimpleDescript do
    it "creates an empty descript for zero contours" do
      desc = GlyfSimpleDescript.new(0_i16, RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)), 0_i16)
      desc.point_count.should eq(0)
      desc.contour_count.should eq(0)
      desc.is_composite.should be_false
    end

    it "reads contour endpoints, flags and relative coordinates" do
      data = Bytes[
        0x00, 0x01, # endPtsOfContours[0] = 1 => pointCount = 2
        0x00, 0x00, # instructionCount = 0
        0x37,       # point 0 flag: on-curve, x short +, y short +
        0x17,       # point 1 flag: on-curve, x short +, y short -
        0x0A, 0x05, # x deltas: +10, +5
        0x14, 0x02, # y deltas: +20, -2
      ]

      desc = GlyfSimpleDescript.new(1_i16, RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(data)), 0_i16)

      desc.contour_count.should eq(1)
      desc.point_count.should eq(2)
      desc.end_pt_of_contours(0).should eq(1)

      desc.x_coordinate(0).should eq(10)
      desc.x_coordinate(1).should eq(15)
      desc.y_coordinate(0).should eq(20)
      desc.y_coordinate(1).should eq(18)
    end

    it "handles repeated flags" do
      # One contour with 3 points, all same flag via REPEAT
      data = Bytes[
        0x00, 0x02,       # endPtsOfContours[0] = 2 => pointCount = 3
        0x00, 0x00,       # instructionCount = 0
        0x3F,             # flag: on-curve + repeat + x short + y short + dual bits
        0x02,             # repeat twice (total 3 points)
        0x01, 0x01, 0x01, # x deltas
        0x01, 0x01, 0x01, # y deltas
      ]

      desc = GlyfSimpleDescript.new(1_i16, RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(data)), 0_i16)

      desc.point_count.should eq(3)
      desc.x_coordinate(0).should eq(1)
      desc.x_coordinate(1).should eq(2)
      desc.x_coordinate(2).should eq(3)
      desc.y_coordinate(0).should eq(1)
      desc.y_coordinate(1).should eq(2)
      desc.y_coordinate(2).should eq(3)
    end
  end
end

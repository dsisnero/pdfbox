require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/fontbox/src/main/java/org/apache/fontbox/ttf/KerningSubtable.java
#     private static class PairData0Format0 (read + getKerning via binary search).
# Upstream has no dedicated test; this is a characterization spec. The pairs
# are read big-endian (TTF byte order) and looked up with a binary search over
# the (left, right) key.
private def build_kerning_pair_stream : Fontbox::TTF::TTFDataStream
  io = ::IO::Memory.new
  io.write_bytes(3_u16, ::IO::ByteFormat::BigEndian) # numPairs
  io.write_bytes(0_u16, ::IO::ByteFormat::BigEndian) # searchRange
  io.write_bytes(0_u16, ::IO::ByteFormat::BigEndian) # entrySelector
  io.write_bytes(0_u16, ::IO::ByteFormat::BigEndian) # rangeShift
  # (10, 20) => 5
  io.write_bytes(10_u16, ::IO::ByteFormat::BigEndian)
  io.write_bytes(20_u16, ::IO::ByteFormat::BigEndian)
  io.write_bytes(5_i16, ::IO::ByteFormat::BigEndian)
  # (30, 40) => -3
  io.write_bytes(30_u16, ::IO::ByteFormat::BigEndian)
  io.write_bytes(40_u16, ::IO::ByteFormat::BigEndian)
  io.write_bytes(-3_i16, ::IO::ByteFormat::BigEndian)
  # (30, 50) => 7
  io.write_bytes(30_u16, ::IO::ByteFormat::BigEndian)
  io.write_bytes(50_u16, ::IO::ByteFormat::BigEndian)
  io.write_bytes(7_i16, ::IO::ByteFormat::BigEndian)

  Fontbox::TTF::RandomAccessReadDataStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(io.to_slice))
end

module Fontbox::TTF
  describe KerningSubtable::PairData0Format0 do
    it "reads the pair table and returns the kerning for a matching pair" do
      pairs = KerningSubtable::PairData0Format0.new
      pairs.read(build_kerning_pair_stream)

      pairs.get_kerning(10, 20).should eq(5)
      pairs.get_kerning(30, 40).should eq(-3)
      pairs.get_kerning(30, 50).should eq(7)
    end

    it "returns 0 for a pair that is not present" do
      pairs = KerningSubtable::PairData0Format0.new
      pairs.read(build_kerning_pair_stream)

      pairs.get_kerning(30, 45).should eq(0)
      pairs.get_kerning(99, 99).should eq(0)
      pairs.get_kerning(0, 0).should eq(0)
    end

    it "compares pairs by left glyph id, then right glyph id" do
      pairs = KerningSubtable::PairData0Format0.new

      pairs.compare([10, 20, 0], [10, 30, 0]).should be < 0
      pairs.compare([10, 30, 0], [10, 20, 0]).should be > 0
      pairs.compare([10, 20, 0], [20, 0, 0]).should be < 0
      pairs.compare([20, 0, 0], [10, 99, 0]).should be > 0
      pairs.compare([10, 20, 0], [10, 20, 0]).should eq(0)
    end
  end
end

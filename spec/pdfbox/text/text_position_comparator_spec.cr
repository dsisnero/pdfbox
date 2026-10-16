require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/text/TextPositionComparator.java
# Upstream has no dedicated test; this is a characterization spec for the
# comparator PDFTextStripper uses when sortByPosition is enabled. The
# direction-adjusted coordinates are derived from the text matrix, so the
# helper builds a position whose dir/xDirAdj/yDirAdj/heightDir are known.
private def build_text_position(x : Float32, y : Float32, height : Float32, dir : Int32 = 0,
                                page_width : Float32 = 612.0_f32, page_height : Float32 = 792.0_f32) : Pdfbox::Text::TextPosition
  matrix = if dir == 180
             Pdfbox::Util::Matrix.new(-1.0_f32, 0.0_f32, 0.0_f32, -1.0_f32, page_width - x, y)
           else
             Pdfbox::Util::Matrix.translate(x, page_height - y)
           end
  Pdfbox::Text::TextPosition.new(
    0, page_width, page_height, matrix, x + 1.0_f32, y, height,
    1.0_f32, 1.0_f32, "a", [65], nil, 12.0_f32, 12)
end

describe Pdfbox::Text::TextPositionComparator do
  comparator = Pdfbox::Text::TextPositionComparator.new

  it "orders by direction first" do
    zero = build_text_position(10.0_f32, 100.0_f32, 10.0_f32, 0)
    one_eighty = build_text_position(10.0_f32, 100.0_f32, 10.0_f32, 180)

    comparator.compare(zero, one_eighty).should be < 0
    comparator.compare(one_eighty, zero).should be > 0
  end

  it "returns 0 for identical direction-adjusted positions" do
    position = build_text_position(10.0_f32, 100.0_f32, 10.0_f32)
    comparator.compare(position, position).should eq(0)
  end

  it "orders positions on the same line by x" do
    left = build_text_position(10.0_f32, 100.0_f32, 10.0_f32)
    right = build_text_position(20.0_f32, 100.0_f32, 10.0_f32)

    comparator.compare(left, right).should be < 0
    comparator.compare(right, left).should be > 0
  end

  it "uses a tolerance for near-equal baselines" do
    a = build_text_position(10.0_f32, 100.0_f32, 10.0_f32)
    b = build_text_position(20.0_f32, 100.05_f32, 10.0_f32)

    comparator.compare(a, b).should be < 0
  end

  it "orders positions on different lines by y" do
    top = build_text_position(50.0_f32, 100.0_f32, 10.0_f32)
    bottom = build_text_position(10.0_f32, 200.0_f32, 10.0_f32)

    comparator.compare(top, bottom).should be < 0
    comparator.compare(bottom, top).should be > 0
  end

  it "treats vertically overlapping positions as the same line" do
    tall = build_text_position(10.0_f32, 100.0_f32, 20.0_f32)
    overlapping = build_text_position(20.0_f32, 90.0_f32, 5.0_f32)

    comparator.compare(tall, overlapping).should be < 0
  end
end

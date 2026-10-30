require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PageDrawer.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/state/PDGraphicsState.java
#
# `Pdfbox::Util::ClipPath` is the AWT-free stand-in for the `Path2D`/`Area` pair
# Java stores as a clipping path: all subpaths of one `W`/`W*` share a winding
# rule, and `contains?` mirrors `Area#contains` for a point.

private def square(x1 : Float64, y1 : Float64, x2 : Float64, y2 : Float64) : Array(Tuple(Float64, Float64))
  [{x1, y1}, {x2, y1}, {x2, y2}, {x1, y2}]
end

describe Pdfbox::Util::ClipPath do
  it "contains the points inside a simple subpath" do
    path = Pdfbox::Util::ClipPath.new([square(0.0, 0.0, 10.0, 10.0)])
    path.contains?(5.0, 5.0).should be_true
    path.contains?(15.0, 5.0).should be_false
    path.contains?(5.0, 15.0).should be_false
  end

  it "leaves a hole for a nested subpath under the even-odd rule" do
    path = Pdfbox::Util::ClipPath.new(
      [square(0.0, 0.0, 10.0, 10.0), square(4.0, 4.0, 6.0, 6.0)],
      Pdfbox::Util::ClipPath::WIND_EVEN_ODD
    )
    path.contains?(2.0, 5.0).should be_true  # in the outer ring
    path.contains?(5.0, 5.0).should be_false # in the hole
    path.contains?(15.0, 5.0).should be_false
  end

  it "fills a nested subpath drawn in the same direction under the non-zero rule" do
    path = Pdfbox::Util::ClipPath.new(
      [square(0.0, 0.0, 10.0, 10.0), square(4.0, 4.0, 6.0, 6.0)],
      Pdfbox::Util::ClipPath::WIND_NON_ZERO
    )
    path.contains?(5.0, 5.0).should be_true
    path.contains?(2.0, 5.0).should be_true
  end

  it "is empty when no subpath has an area" do
    path = Pdfbox::Util::ClipPath.new([[{0.0, 0.0}, {10.0, 0.0}]])
    path.empty?.should be_true
    path.contains?(5.0, 0.0).should be_false
  end
end

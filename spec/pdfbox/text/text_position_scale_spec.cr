require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/text/TextPosition.java
#     getXScale / getYScale (the text matrix scaling factors). Upstream has no
#     dedicated test; this is a characterization spec.
private def build_scaled_text_position(matrix : Pdfbox::Util::Matrix) : Pdfbox::Text::TextPosition
  Pdfbox::Text::TextPosition.new(
    0, 612.0_f32, 792.0_f32, matrix, 1.0_f32, 1.0_f32, 10.0_f32,
    1.0_f32, 1.0_f32, "a", [65], nil, 12.0_f32, 12)
end

describe Pdfbox::Text::TextPosition do
  it "reports the X and Y scale from the text matrix" do
    matrix = Pdfbox::Util::Matrix.new(2.0_f32, 0.0_f32, 0.0_f32, 3.0_f32, 0.0_f32, 0.0_f32)
    position = build_scaled_text_position(matrix)

    position.x_scale.should eq(2.0_f32)
    position.y_scale.should eq(3.0_f32)
  end

  it "uses the unscaled factors for a translation matrix" do
    matrix = Pdfbox::Util::Matrix.translate(10.0_f32, 20.0_f32)
    position = build_scaled_text_position(matrix)

    position.x_scale.should eq(1.0_f32)
    position.y_scale.should eq(1.0_f32)
  end
end

require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/PDFStreamEngine.java
#     getGraphicsStackSize()            -> graphicsStack.size()
#     transformedPoint(float x, float y) -> the point transformed by the current
#                                          transformation matrix (AffineTransform
#                                          built from the CTM)
#     transformWidth(float width)        -> width * sqrt(((scaleX + shearX)^2 +
#                                          (scaleY + shearY)^2) * 0.5)
#
# These are the extension points a custom stream engine uses to work in device
# space; the port did not have them.
private class ProbeStreamEngine < Pdfbox::Contentstream::PDFStreamEngine
  def use_matrix(matrix : Pdfbox::Util::Matrix) : Nil
    graphics_state.current_transformation_matrix = matrix
  end
end

describe Pdfbox::Contentstream::PDFStreamEngine do
  it "reports the graphics stack size" do
    engine = ProbeStreamEngine.new
    engine.graphics_stack_size.should eq(1)

    engine.save_graphics_state
    engine.graphics_stack_size.should eq(2)

    engine.restore_graphics_state
    engine.graphics_stack_size.should eq(1)
  end

  it "transforms a point with the current transformation matrix" do
    engine = ProbeStreamEngine.new
    # scale (2, 3) and translate (10, 20)
    engine.use_matrix(Pdfbox::Util::Matrix.new(2.0_f32, 0.0_f32, 0.0_f32, 3.0_f32, 10.0_f32, 20.0_f32))

    origin = engine.transformed_point(0.0, 0.0)
    origin[0].should eq(10.0)
    origin[1].should eq(20.0)

    point = engine.transformed_point(1.0, 1.0)
    point[0].should eq(12.0)
    point[1].should eq(23.0)
  end

  it "transforms a width with the current transformation matrix" do
    engine = ProbeStreamEngine.new
    engine.use_matrix(Pdfbox::Util::Matrix.new(2.0_f32, 0.0_f32, 0.0_f32, 3.0_f32, 10.0_f32, 20.0_f32))

    # (scaleX + shearX) = 2, (scaleY + shearY) = 3, so sqrt((4 + 9) / 2)
    engine.transform_width(10.0).should be_close(10.0 * Math.sqrt(6.5), 1e-6)
    # the translation does not change a width
    engine.transform_width(2.0).should be_close(2.0 * Math.sqrt(6.5), 1e-6)
  end

  it "returns the identity transform for an untransformed engine" do
    engine = ProbeStreamEngine.new
    engine.transformed_point(3.0, 4.0).should eq({3.0, 4.0})
    engine.transform_width(5.0).should be_close(5.0, 1e-6)
  end
end

require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/util/Matrix.java
#     getScaleX / getShearX / getScaleY / getShearY, getScaleInstance and rotate.
# Upstream has no dedicated test; this is a characterization spec.
module Pdfbox::Util
  describe Matrix do
    it "reports the scale, shear and translation elements" do
      matrix = Matrix.new(2.0_f32, 0.5_f32, 0.25_f32, 3.0_f32, 10.0_f32, 20.0_f32)

      matrix.scale_x.should eq(2.0_f32)
      matrix.shear_y.should eq(0.5_f32)
      matrix.shear_x.should eq(0.25_f32)
      matrix.scale_y.should eq(3.0_f32)
      matrix.translate_x.should eq(10.0_f32)
      matrix.translate_y.should eq(20.0_f32)
    end

    it "builds a scale instance" do
      matrix = Matrix.get_scale_instance(2.0_f32, 3.0_f32)

      matrix.scale_x.should eq(2.0_f32)
      matrix.scale_y.should eq(3.0_f32)
      matrix.shear_x.should eq(0.0_f32)
      matrix.shear_y.should eq(0.0_f32)
    end

    it "rotates the matrix by the given angle" do
      matrix = Matrix.identity
      matrix.rotate(Math::PI / 2)

      matrix.scale_x.should be_close(0.0_f32, 0.0001_f32)
      matrix.shear_y.should be_close(1.0_f32, 0.0001_f32)
      matrix.shear_x.should be_close(-1.0_f32, 0.0001_f32)
      matrix.scale_y.should be_close(0.0_f32, 0.0001_f32)
    end
  end
end

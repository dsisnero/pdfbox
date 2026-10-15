require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationCircle.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationSquare.java
#     getInteriorColor/setInteriorColor, getFringe/setFringe and initFringe.
#
# The Java FDFAnnotationTest does not cover these, so the assertions below are
# derived from the Java source.
module Pdfbox::Pdmodel::Fdf
  describe "FDFAnnotationCircle/Square shape styling" do
    it "parses interior-color and fringe for a circle (Java FDFAnnotationCircle)" do
      xml = %(<circle page="0" rect="0,0,10,10" interior-color="#00FF00" fringe="1,2,3,4"/>)
      annot = FDFAnnotationCircle.new(XML.parse(xml).root.not_nil!)

      annot.interior_color.should eq([0.0_f32, 1.0_f32, 0.0_f32])
      annot.fringe.should_not be_nil
      annot.fringe.not_nil!.lower_left_x.should eq(1.0_f32)
      annot.fringe.not_nil!.upper_right_y.should eq(4.0_f32)
    end

    it "parses interior-color and fringe for a square (Java FDFAnnotationSquare)" do
      xml = %(<square page="0" rect="0,0,10,10" interior-color="#FF0000" fringe="5,6,7,8"/>)
      annot = FDFAnnotationSquare.new(XML.parse(xml).root.not_nil!)

      annot.interior_color.should eq([1.0_f32, 0.0_f32, 0.0_f32])
      annot.fringe.should_not be_nil
      annot.fringe.not_nil!.lower_left_x.should eq(5.0_f32)
      annot.fringe.not_nil!.upper_right_x.should eq(7.0_f32)
    end

    it "raises for a malformed fringe (Java 'wrong amount')" do
      xml = %(<square page="0" rect="0,0,10,10" fringe="1,2"/>)
      expect_raises(::IO::Error, "Error: wrong amount of numbers in attribute 'fringe'") do
        FDFAnnotationSquare.new(XML.parse(xml).root.not_nil!)
      end
    end

    it "round-trips the interior color and clears the fringe (Java setters)" do
      annot = FDFAnnotationCircle.new
      annot.interior_color.should be_nil
      annot.fringe.should be_nil

      annot.interior_color = [0.25_f32, 0.5_f32, 0.75_f32]
      annot.interior_color.should eq([0.25_f32, 0.5_f32, 0.75_f32])

      annot.fringe = nil
      annot.fringe.should be_nil
    end
  end
end

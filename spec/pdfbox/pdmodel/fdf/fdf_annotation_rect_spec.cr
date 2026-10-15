require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotation.java
#     createRectangleFromAttributes: rect values are lowerLeftX, lowerLeftY,
#     upperRightX, upperRightY (NOT x, y, width, height).
module Pdfbox::Pdmodel::Fdf
  describe "FDFAnnotation /Rect parsing" do
    it "interprets the XFDF rect as llx,lly,urx,ury (Java createRectangleFromAttributes)" do
      xml = %(<text page="0" rect="1,2,3,4"/>)
      annot = FDFAnnotationText.new(XML.parse(xml).root.not_nil!)

      rect = annot.rectangle
      rect.should_not be_nil
      rect.not_nil!.lower_left_x.should eq(1.0_f32)
      rect.not_nil!.lower_left_y.should eq(2.0_f32)
      rect.not_nil!.upper_right_x.should eq(3.0_f32)
      rect.not_nil!.upper_right_y.should eq(4.0_f32)
    end

    it "stores the raw rect values without adding width/height" do
      xml = %(<square page="0" rect="10,20,110,220"/>)
      annot = FDFAnnotationSquare.new(XML.parse(xml).root.not_nil!)

      stored = annot.cos_object.get_array(Cos::Name.new("Rect")).not_nil!
      stored.to_float_array.should eq([10.0, 20.0, 110.0, 220.0])
    end

    it "raises for a rect with the wrong amount of numbers (Java parseRectangleAttributes)" do
      xml = %(<text page="0" rect="1,2,3"/>)
      expect_raises(::IO::Error, "Error: wrong amount of numbers in attribute 'rect'") do
        FDFAnnotationText.new(XML.parse(xml).root.not_nil!)
      end
    end
  end
end

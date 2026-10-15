require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationCaret.java
#     getFringe/setFringe, getSymbol/setSymbol, initFringe and the element parser.
#
# The Java FDFAnnotationTest does not cover these, so the assertions below are
# derived from the Java source.
module Pdfbox::Pdmodel::Fdf
  describe "FDFAnnotationCaret" do
    it "round-trips the fringe rectangle (Java setFringe/getFringe)" do
      annot = FDFAnnotationCaret.new
      annot.fringe.should be_nil

      array = Cos::Array.new
      [1.0, 2.0, 3.0, 4.0].each { |value| array.add(Cos::Float.new(value)) }
      rect = Common::PDRectangle.new(array)
      annot.fringe = rect

      fringe = annot.fringe
      fringe.should_not be_nil
      fringe.not_nil!.lower_left_x.should eq(1.0_f32)
      fringe.not_nil!.lower_left_y.should eq(2.0_f32)
      fringe.not_nil!.upper_right_x.should eq(3.0_f32)
      fringe.not_nil!.upper_right_y.should eq(4.0_f32)

      annot.fringe = nil
      annot.fringe.should be_nil
    end

    it "maps the caret symbol like Java (paragraph -> P, anything else -> None)" do
      annot = FDFAnnotationCaret.new
      annot.symbol.should be_nil

      annot.symbol = "paragraph"
      annot.symbol.should eq("P")

      annot.symbol = "P"
      annot.symbol.should eq("None")
    end

    it "parses fringe and symbol from XFDF (Java FDFAnnotationCaret(Element))" do
      xml = %(<caret page="0" rect="0,0,10,10" fringe="1,2,3,4" symbol="paragraph"/>)
      annot = FDFAnnotationCaret.new(XML.parse(xml).root.not_nil!)

      annot.fringe.should_not be_nil
      annot.fringe.not_nil!.lower_left_x.should eq(1.0_f32)
      annot.fringe.not_nil!.upper_right_y.should eq(4.0_f32)
      annot.symbol.should eq("P")
    end

    it "raises for a caret with a malformed fringe (Java 'wrong amount')" do
      xml = %(<caret page="0" rect="0,0,10,10" fringe="1,2,3"/>)
      expect_raises(::IO::Error, "Error: wrong amount of numbers in attribute 'fringe'") do
        FDFAnnotationCaret.new(XML.parse(xml).root.not_nil!)
      end
    end
  end
end

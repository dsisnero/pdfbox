require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationTextMarkup.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationHighlight.java
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationTest.java
#     (fixure xfdf-test-document-annotations.xml, loaded by loadXFDFAnnotations)
#
# The Java test only asserts the annotation count / richtext, so the coords
# assertions below are derived from FDFAnnotationTextMarkup + the fixture.
module Pdfbox::Pdmodel::Fdf
  describe "FDFAnnotationTextMarkup" do
    it "parses the highlight coords into /QuadPoints (Java FDFAnnotationTextMarkup#setCoords)" do
      path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/fdf/xfdf-test-document-annotations.xml")
      fdf_doc = Pdfbox::Loader.load_xfdf(path)
      begin
        annots = fdf_doc.catalog.fdf.annotations.as(Array(FDFAnnotation))
        highlight = annots.find(&.is_a?(FDFAnnotationHighlight))
        highlight.should_not be_nil
        highlight.as(FDFAnnotationHighlight).coords.should eq([
          68.4, 680.06, 233.62, 680.06, 68.4, 611.57, 233.62, 611.57,
        ])

        underline = annots.find(&.is_a?(FDFAnnotationUnderline))
        underline.should_not be_nil
        underline.as(FDFAnnotationUnderline).coords.should eq([
          233.62, 680.06, 361.63, 680.06, 233.62, 611.57, 361.63, 611.57,
        ])

        strikeout = annots.find(&.is_a?(FDFAnnotationStrikeOut))
        strikeout.should_not be_nil
        strikeout.as(FDFAnnotationStrikeOut).coords.should eq([
          372.24, 680.06, 467.52, 680.06, 372.24, 611.57, 467.52, 611.57,
        ])
      ensure
        fdf_doc.close
      end
    end

    it "round-trips coords through /QuadPoints (Java setCoords/getCoords)" do
      annot = FDFAnnotationUnderline.new
      annot.coords.should be_nil

      annot.coords = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
      annot.coords.should eq([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
    end

    it "raises for a missing coords attribute (Java 'missing attribute')" do
      xml = %(<highlight page="0" rect="68.4,611.57,233.62,680.06"/>)
      expect_raises(::IO::Error, "Error: missing attribute 'coords'") do
        FDFAnnotationHighlight.new(XML.parse(xml).root.not_nil!)
      end
    end

    it "raises for too few coords numbers (Java 'too little numbers')" do
      xml = %(<highlight page="0" rect="68.4,611.57,233.62,680.06" coords="1,2,3,4"/>)
      expect_raises(::IO::Error, "Error: too little numbers in attribute 'coords'") do
        FDFAnnotationHighlight.new(XML.parse(xml).root.not_nil!)
      end
    end
  end
end

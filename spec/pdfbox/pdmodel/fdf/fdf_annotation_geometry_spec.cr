require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationInk.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationPolygon.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationPolyline.java
#   vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/fdf/xfdf-test-document-annotations.xml
#
# The Java FDFAnnotationTest only asserts count/richtext, so the geometry
# assertions below are derived from the Java source and the XFDF fixture.
module Pdfbox::Pdmodel::Fdf
  describe "FDF annotation geometry" do
    it "parses the ink freehand path from the XFDF fixture (Java FDFAnnotationInk inklist/gesture)" do
      path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/fdf/xfdf-test-document-annotations.xml")
      fdf_doc = Pdfbox::Loader.load_xfdf(path)
      begin
        annots = fdf_doc.catalog.fdf.annotations.as(Array(FDFAnnotation))
        ink = annots.find(&.is_a?(FDFAnnotationInk))
        ink.should_not be_nil

        ink_list = ink.as(FDFAnnotationInk).ink_list
        ink_list.should_not be_nil
        ink_list.not_nil!.size.should eq(1)
        gesture = ink_list.not_nil![0]
        gesture.size.should eq(100)
        gesture[0].should be_close(344.701508, 1e-6)
        gesture[1].should be_close(361.968750, 1e-6)
        gesture[-2].should be_close(555.237793, 1e-6)
        gesture[-1].should be_close(369.187500, 1e-6)
      ensure
        fdf_doc.close
      end
    end

    it "round-trips an ink list (Java setInkList/getInkList)" do
      annot = FDFAnnotationInk.new
      annot.ink_list.should be_nil

      annot.ink_list = [[1.0, 2.0, 3.0, 4.0], [5.0, 6.0]]
      annot.ink_list.should eq([[1.0, 2.0, 3.0, 4.0], [5.0, 6.0]])
    end

    it "parses and round-trips polygon vertices (Java FDFAnnotationPolygon)" do
      xml = %(<polygon page="0" rect="0,0,10,10"><vertices>0,0;10,0;10,10</vertices></polygon>)
      annot = FDFAnnotationPolygon.new(XML.parse(xml).root.not_nil!)
      annot.vertices.should eq([0.0, 0.0, 10.0, 0.0, 10.0, 10.0])

      annot.vertices = [1.0, 1.0, 2.0, 2.0]
      annot.vertices.should eq([1.0, 1.0, 2.0, 2.0])
    end

    it "parses polyline vertices (Java FDFAnnotationPolyline)" do
      xml = %(<polyline page="0" rect="0,0,10,10"><vertices>1,2;3,4</vertices></polyline>)
      annot = FDFAnnotationPolyline.new(XML.parse(xml).root.not_nil!)
      annot.vertices.should eq([1.0, 2.0, 3.0, 4.0])
    end

    it "raises for a polygon with missing vertices (Java 'missing element')" do
      xml = %(<polygon page="0" rect="0,0,10,10"/>)
      expect_raises(::IO::Error, "Error: missing element 'vertices'") do
        FDFAnnotationPolygon.new(XML.parse(xml).root.not_nil!)
      end
    end

    it "raises for an ink with missing gesture (Java 'missing element')" do
      xml = %(<ink page="0" rect="0,0,10,10"><inklist/></ink>)
      expect_raises(::IO::Error, "Error: missing element 'gesture'") do
        FDFAnnotationInk.new(XML.parse(xml).root.not_nil!)
      end
    end
  end
end

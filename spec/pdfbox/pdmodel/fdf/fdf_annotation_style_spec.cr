require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationLine.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationPolygon.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationPolyline.java
#   vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/fdf/xfdf-test-document-annotations.xml
#
# The Java FDFAnnotationTest only asserts count/richtext, so the style
# assertions below are derived from the Java source and the XFDF fixture.
module Pdfbox::Pdmodel::Fdf
  describe "FDF annotation styling" do
    it "parses the line start/end/head/tail/interior-color from the fixture (Java FDFAnnotationLine)" do
      path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/fdf/xfdf-test-document-annotations.xml")
      fdf_doc = Pdfbox::Loader.load_xfdf(path)
      begin
        annots = fdf_doc.catalog.fdf.annotations.as(Array(FDFAnnotation))
        line = annots.find(&.is_a?(FDFAnnotationLine))
        line.should_not be_nil
        line = line.as(FDFAnnotationLine)

        line.line.should eq([563.49, 245.44, 563.49, 121.69])
        line.start_point_ending_style.should eq("Square")
        line.end_point_ending_style.should eq("Slash")

        interior = line.interior_color
        interior.should_not be_nil
        interior.not_nil![0].should be_close(30.0 / 255.0, 1e-6)
        interior.not_nil![1].should be_close(89.0 / 255.0, 1e-6)
        interior.not_nil![2].should be_close(255.0 / 255.0, 1e-6)
      ensure
        fdf_doc.close
      end
    end

    it "round-trips the line coordinates, ending styles and interior color (Java setters)" do
      annot = FDFAnnotationLine.new
      annot.line.should be_nil
      annot.start_point_ending_style.should eq("None")
      annot.end_point_ending_style.should eq("None")
      annot.interior_color.should be_nil

      annot.line = [1.0, 2.0, 3.0, 4.0]
      annot.start_point_ending_style = "OpenArrow"
      annot.end_point_ending_style = "ClosedArrow"
      annot.interior_color = [0.5_f32, 0.25_f32, 0.125_f32]

      annot.line.should eq([1.0, 2.0, 3.0, 4.0])
      annot.start_point_ending_style.should eq("OpenArrow")
      annot.end_point_ending_style.should eq("ClosedArrow")
      annot.interior_color.should eq([0.5_f32, 0.25_f32, 0.125_f32])
    end

    it "raises for a line with missing start/end (Java 'missing attribute')" do
      xml = %(<line page="0" rect="0,0,10,10" end="1,2"/>)
      expect_raises(::IO::Error, "Error: missing attribute 'start'") do
        FDFAnnotationLine.new(XML.parse(xml).root.not_nil!)
      end

      xml2 = %(<line page="0" rect="0,0,10,10" start="1,2"/>)
      expect_raises(::IO::Error, "Error: missing attribute 'end'") do
        FDFAnnotationLine.new(XML.parse(xml2).root.not_nil!)
      end
    end

    it "parses polyline head/tail/interior-color (Java FDFAnnotationPolyline initStyles)" do
      xml = %(<polyline page="0" rect="0,0,10,10" head="Circle" tail="Diamond" interior-color="#FF0000">) +
            %(<vertices>0,0;10,10</vertices></polyline>)
      annot = FDFAnnotationPolyline.new(XML.parse(xml).root.not_nil!)
      annot.start_point_ending_style.should eq("Circle")
      annot.end_point_ending_style.should eq("Diamond")
      annot.interior_color.should eq([1.0_f32, 0.0_f32, 0.0_f32])
    end

    it "parses and round-trips polygon interior color (Java FDFAnnotationPolygon)" do
      xml = %(<polygon page="0" rect="0,0,10,10" interior-color="#00FF00">) +
            %(<vertices>0,0;10,0;10,10</vertices></polygon>)
      annot = FDFAnnotationPolygon.new(XML.parse(xml).root.not_nil!)
      annot.interior_color.should eq([0.0_f32, 1.0_f32, 0.0_f32])

      annot.interior_color = [0.1_f32, 0.2_f32, 0.3_f32]
      annot.interior_color.should eq([0.1_f32, 0.2_f32, 0.3_f32])
    end
  end
end

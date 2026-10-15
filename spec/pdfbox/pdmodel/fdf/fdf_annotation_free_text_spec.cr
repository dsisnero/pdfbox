require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationFreeText.java
#     getJustification returns "" + the quadding int (/Q), setJustification maps
#     "centered" -> 1, "right" -> 2, else 0.
module Pdfbox::Pdmodel::Fdf
  describe FDFAnnotationFreeText do
    it "returns the quadding int as a string (Java getJustification)" do
      annot = FDFAnnotationFreeText.new
      annot.justification.should eq("0")

      annot.justification = "centered"
      annot.justification.should eq("1")

      annot.justification = "right"
      annot.justification.should eq("2")

      annot.justification = "left"
      annot.justification.should eq("0")
    end

    it "clamps nil/unknown justification to 0 (Java setJustification)" do
      annot = FDFAnnotationFreeText.new
      annot.justification = nil
      annot.justification.should eq("0")
    end
  end
end

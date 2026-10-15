require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocument.java
#     getFontsToSubset (the fonts registered for subsetting on save).
module Pdfbox::Pdmodel
  describe Document do
    it "exposes the fonts registered for subsetting (Java getFontsToSubset)" do
      doc = Document.create
      doc.fonts_to_subset.should be_empty

      font = Font::PDType1Font.new(Font::Standard14Fonts::FontName::HELVETICA)
      doc.register_font_for_save(font)
      doc.fonts_to_subset.should eq([font])
    end

    it "exposes the Java-compatible get_fonts_to_subset alias" do
      doc = Document.create
      font = Font::PDType1Font.new(Font::Standard14Fonts::FontName::HELVETICA)
      doc.register_font_for_save(font)
      doc.get_fonts_to_subset.should eq([font])
    end
  end
end

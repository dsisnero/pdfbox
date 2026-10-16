require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDFont.java
#     getType (/Type name), getSubType (/Subtype name). Upstream has no dedicated
#     test; this is a characterization spec.
module Pdfbox::Pdmodel::Font
  describe PDFont do
    it "reads the /Type and /Subtype entries" do
      font = PDType1Font.new(Standard14Fonts::FontName::HELVETICA)

      font.type.should eq("Font")
      font.sub_type.should eq("Type1")
    end

    it "returns nil when /Subtype is absent" do
      font = PDType1Font.new(Cos::Dictionary.new)

      font.sub_type.should be_nil
      font.type.should be_nil
    end
  end
end

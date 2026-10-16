require "../../../spec_helper"
require "../../../../src/pdfbox"

module Pdfbox::Pdmodel::Font
  # Characterization spec for PDType1Font#codeToName (Java getEncoding().getName
  # + getNameInFont); upstream has no dedicated test.
  describe PDType1Font do
    it "maps a code to the glyph name for a standard-14 font" do
      font = PDType1Font.new(Standard14Fonts::FontName::HELVETICA)

      font.code_to_name(65).should eq("A")
      font.code_to_name(97).should eq("a")
      font.code_to_name(48).should eq("zero")
    end

    it "maps a code to the glyph name for a Symbol font" do
      font = PDType1Font.new(Standard14Fonts::FontName::SYMBOL)

      font.code_to_name(65).should eq("Alpha")
    end

    it "returns the embedded Type 1 font (nil for a standard-14 font)" do
      font = PDType1Font.new(Standard14Fonts::FontName::HELVETICA)

      font.get_type1_font.should be_nil
    end
  end
end

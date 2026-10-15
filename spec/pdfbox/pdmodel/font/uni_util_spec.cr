require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/UniUtil.java
#     getUniNameOfCodePoint — faster than String.format("uni%04X", codePoint).
#
# The Java utility is package-private and has no dedicated test, so the
# assertions below are derived from the Java source.
describe "UniUtil" do
  it "formats uni names like Java getUniNameOfCodePoint" do
    Pdfbox::Pdmodel::Font::UniUtil.get_uni_name_of_code_point(0x0).should eq("uni0000")
    Pdfbox::Pdmodel::Font::UniUtil.get_uni_name_of_code_point(0x1).should eq("uni0001")
    Pdfbox::Pdmodel::Font::UniUtil.get_uni_name_of_code_point(0x41).should eq("uni0041")
    Pdfbox::Pdmodel::Font::UniUtil.get_uni_name_of_code_point(0xABC).should eq("uni0ABC")
    Pdfbox::Pdmodel::Font::UniUtil.get_uni_name_of_code_point(0x100).should eq("uni0100")
    Pdfbox::Pdmodel::Font::UniUtil.get_uni_name_of_code_point(0xFFFF).should eq("uniFFFF")
    Pdfbox::Pdmodel::Font::UniUtil.get_uni_name_of_code_point(0x1F600).should eq("uni1F600")
  end
end

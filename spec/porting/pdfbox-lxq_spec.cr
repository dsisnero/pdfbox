require "../spec_helper"

describe "Porting parity pdfbox-lxq" do
  # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/util ● P3
  # Ported from StringUtilTest.java
  it "StringUtilTest#testSplitOnSpace_happyPath" do
    Pdfbox::Util::StringUtil.split_on_space("a b c").should eq(["a", "b", "c"])
  end

  it "StringUtilTest#testSplitOnSpace_emptyString" do
    Pdfbox::Util::StringUtil.split_on_space("").should eq([""])
  end

  it "StringUtilTest#testSplitOnSpace_onlySpaces" do
    Pdfbox::Util::StringUtil.split_on_space("   ").should eq([] of String)
  end

  it "StringUtilTest#testTokenizeOnSpace_happyPath" do
    Pdfbox::Util::StringUtil.tokenize_on_space("a b c").should eq(["a", " ", "b", " ", "c"])
  end

  it "StringUtilTest#testTokenizeOnSpace_emptyString" do
    Pdfbox::Util::StringUtil.tokenize_on_space("").should eq([""])
  end

  it "StringUtilTest#testTokenizeOnSpace_onlySpaces" do
    Pdfbox::Util::StringUtil.tokenize_on_space("   ").should eq([" ", " ", " "])
  end

  it "StringUtilTest#testTokenizeOnSpace_onlySpacesWithText" do
    Pdfbox::Util::StringUtil.tokenize_on_space("  a  ").should eq([" ", " ", "a", " ", " "])
  end
end

require "../spec_helper"

describe "Porting parity pdfbox-cjn" do
  # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/function/type4 ● P3
  it "tracks direct Java source-of-truth test files for this suite" do
    File.exists?("vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/function/type4/TestParser.java").should be_true
  end
end

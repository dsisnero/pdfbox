require "../spec_helper"

describe "Porting parity pdfbox-cq8" do
  # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/pagenavigation ● P3
  it "tracks direct Java source-of-truth test files for this suite" do
    File.exists?("vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/pagenavigation/PDTransitionDirectionTest.java").should be_true
  end
end

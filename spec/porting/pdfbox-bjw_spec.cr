require "../spec_helper"

describe "Porting parity pdfbox-bjw" do
  # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/documentnavigation/outline ● P3
  it "tracks direct Java source-of-truth test files for this suite" do
    File.exists?("vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/documentnavigation/outline/PDDocumentOutlineTest.java").should be_true
  end
end

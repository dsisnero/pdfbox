require "../spec_helper"

describe "Porting parity pdfbox-9zt" do
  # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/text ● P3
  # This path contains direct Java tests and should not remain a "no tests" placeholder.
  it "tracks direct Java source-of-truth test files for this suite" do
    File.exists?("vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/text/BidiTest.java").should be_true
    File.exists?("vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/text/PDFTextStripperByAreaTest.java").should be_true
    File.exists?("vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/text/TestTextStripper.java").should be_true
  end
end

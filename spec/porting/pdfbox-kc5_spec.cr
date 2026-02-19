require "../spec_helper"

describe "Porting parity pdfbox-kc5" do
  # Source of truth: vendor/pdfbox/tools/src/test/java/org/apache/pdfbox/tools ● P3
  it "tracks direct Java source-of-truth test files for this suite" do
    File.exists?("vendor/pdfbox/tools/src/test/java/org/apache/pdfbox/tools/PDFBoxNonHeadlessTest.java").should be_true
  end
end

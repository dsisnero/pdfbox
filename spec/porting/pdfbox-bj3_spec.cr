require "../spec_helper"

describe "Porting parity pdfbox-bj3" do
  # Source of truth: vendor/pdfbox/xmpbox/src/test/java/org/apache/xmpbox/xml ● P3
  it "tracks direct Java source-of-truth test files for this suite" do
    File.exists?("vendor/pdfbox/xmpbox/src/test/java/org/apache/xmpbox/xml/DomXmpParserTest.java").should be_true
  end
end

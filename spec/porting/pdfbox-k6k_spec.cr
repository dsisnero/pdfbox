require "../spec_helper"

describe "Porting parity pdfbox-k6k" do
  # Source of truth: vendor/pdfbox/xmpbox/src/test/java/org/apache/xmpbox/schema ● P3
  it "tracks direct Java source-of-truth test files for this suite" do
    File.exists?("vendor/pdfbox/xmpbox/src/test/java/org/apache/xmpbox/schema/XMPBasicTest.java").should be_true
  end
end

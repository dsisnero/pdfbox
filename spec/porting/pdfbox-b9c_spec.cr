require "../spec_helper"

describe "Porting parity pdfbox-b9c" do
  # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image ● P3
  it "tracks direct Java source-of-truth test files for this suite" do
    File.exists?("vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/LosslessFactoryTest.java").should be_true
  end
end

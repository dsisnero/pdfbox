require "../spec_helper"

describe "Porting parity pdfbox-9tt" do
  # Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/action ● P3
  # This path does contain direct Java tests (e.g. PDActionURITest.java).
  it "tracks direct Java source-of-truth test files for this suite" do
    java_test = "vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/action/PDActionURITest.java"
    File.exists?(java_test).should be_true
  end
end

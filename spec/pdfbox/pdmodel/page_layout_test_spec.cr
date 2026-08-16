require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/PageLayoutTest.java
describe Pdfbox::Pdmodel::PageLayout do
  it "PageLayoutTest#testValues (PDFBOX-3362)" do
    values = Pdfbox::Pdmodel::PageLayout.values
    string_set = Set(String).new
    layout_set = Set(Pdfbox::Pdmodel::PageLayout).new
    values.each do |pl|
      s = pl.string_value
      string_set.add(s)
      layout_set.add(Pdfbox::Pdmodel::PageLayout.from_string(s))
    end
    layout_set.size.should eq(values.size)
    string_set.size.should eq(values.size)
  end

  it "PageLayoutTest#fromStringInputNotNullOutputIllegalArgumentException" do
    expect_raises(ArgumentError) { Pdfbox::Pdmodel::PageLayout.from_string("SinglePag") }
  end
end

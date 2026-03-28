require "../../spec_helper"

describe Pdfbox::Pdmodel::PageLayout do
  it "PageLayoutTest#testValues" do
    layouts = Pdfbox::Pdmodel::PageLayout.values
    page_layout_set = Set(Pdfbox::Pdmodel::PageLayout).new
    string_set = Set(String).new

    layouts.each do |layout|
      string_value = layout.string_value
      string_set << string_value
      page_layout_set << Pdfbox::Pdmodel::PageLayout.from_string(string_value)
    end

    page_layout_set.size.should eq(layouts.size)
    string_set.size.should eq(layouts.size)
  end

  it "PageLayoutTest#fromStringInputNotNullOutputIllegalArgumentException" do
    expect_raises(ArgumentError, "SinglePag") do
      Pdfbox::Pdmodel::PageLayout.from_string("SinglePag")
    end
  end
end

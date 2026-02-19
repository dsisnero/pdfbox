require "../../spec_helper"

describe Pdfbox::Filter::Filter do
  it "raises for an empty filter list (TestFilters#testEmptyFilterList)" do
    expect_raises(ArgumentError) do
      Pdfbox::Filter::Filter.decode(Bytes.empty, [] of Pdfbox::Filter::Filter, Pdfbox::Cos::Dictionary.new, nil, nil)
    end
  end
end

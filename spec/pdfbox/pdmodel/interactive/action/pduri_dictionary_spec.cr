require "../../../../spec_helper"
require "../../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::Action::PDURIDictionary do
  it "stores and reads the base URI" do
    dictionary = Pdfbox::Pdmodel::Interactive::Action::PDURIDictionary.new

    dictionary.base = "https://example.com/base/"

    dictionary.cos_object.should be_a(Pdfbox::Cos::Dictionary)
    dictionary.base.should eq("https://example.com/base/")
  end
end

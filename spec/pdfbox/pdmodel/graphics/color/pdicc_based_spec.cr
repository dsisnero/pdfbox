# Port of org.apache.pdfbox.pdmodel.graphics.color.PDICCBasedTest
require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Graphics::Color::PDICCBased do
  it "tests constructor for PDFBOX-2812" do
    doc = Pdfbox::Pdmodel::PDDocument.new
    icc_based = Pdfbox::Pdmodel::Graphics::Color::PDICCBased.new(doc)
    icc_based.name.should eq("ICCBased")
    icc_based.pd_stream.should_not be_nil
  end
end

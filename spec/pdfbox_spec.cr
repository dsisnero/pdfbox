require "./spec_helper"

describe Pdfbox do
  it "has a version number" do
    Pdfbox::VERSION.should eq("0.1.0")
  end

  it "defines PDFDocument class" do
    Pdfbox::PDFDocument.should_not be_nil
  end

  it "defines error classes" do
    Pdfbox::Error.should_not be_nil
    Pdfbox::PDFError.should_not be_nil
    Pdfbox::UnsupportedFeatureError.should_not be_nil
  end
end

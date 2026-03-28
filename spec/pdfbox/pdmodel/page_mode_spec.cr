require "../../spec_helper"

describe Pdfbox::Pdmodel::PageMode do
  it "PageModeTest#fromStringInputNotNullOutputNotNull" do
    Pdfbox::Pdmodel::PageMode.from_string("FullScreen").should eq(Pdfbox::Pdmodel::PageMode::FULL_SCREEN)
  end

  it "PageModeTest#fromStringInputNotNullOutputNotNull2" do
    Pdfbox::Pdmodel::PageMode.from_string("UseThumbs").should eq(Pdfbox::Pdmodel::PageMode::USE_THUMBS)
  end

  it "PageModeTest#fromStringInputNotNullOutputNotNull3" do
    Pdfbox::Pdmodel::PageMode.from_string("UseOC").should eq(Pdfbox::Pdmodel::PageMode::USE_OPTIONAL_CONTENT)
  end

  it "PageModeTest#fromStringInputNotNullOutputNotNull4" do
    Pdfbox::Pdmodel::PageMode.from_string("UseNone").should eq(Pdfbox::Pdmodel::PageMode::USE_NONE)
  end

  it "PageModeTest#fromStringInputNotNullOutputNotNull5" do
    Pdfbox::Pdmodel::PageMode.from_string("UseAttachments").should eq(Pdfbox::Pdmodel::PageMode::USE_ATTACHMENTS)
  end

  it "PageModeTest#fromStringInputNotNullOutputNotNull6" do
    Pdfbox::Pdmodel::PageMode.from_string("UseOutlines").should eq(Pdfbox::Pdmodel::PageMode::USE_OUTLINES)
  end

  it "PageModeTest#fromStringInputNotNullOutputIllegalArgumentException" do
    expect_raises(ArgumentError, "") do
      Pdfbox::Pdmodel::PageMode.from_string("")
    end
  end

  it "PageModeTest#fromStringInputNotNullOutputIllegalArgumentException2" do
    expect_raises(ArgumentError, "Dulacb`ecj") do
      Pdfbox::Pdmodel::PageMode.from_string("Dulacb`ecj")
    end
  end

  it "PageModeTest#stringValueOutputNotNull" do
    Pdfbox::Pdmodel::PageMode::USE_OPTIONAL_CONTENT.string_value.should eq("UseOC")
  end
end

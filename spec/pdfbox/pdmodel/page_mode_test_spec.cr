require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/PageModeTest.java
describe Pdfbox::Pdmodel::PageMode do
  it "PageModeTest#fromStringInputNotNullOutputNotNull*" do
    Pdfbox::Pdmodel::PageMode.from_string("FullScreen").should eq(Pdfbox::Pdmodel::PageMode::FULL_SCREEN)
    Pdfbox::Pdmodel::PageMode.from_string("UseThumbs").should eq(Pdfbox::Pdmodel::PageMode::USE_THUMBS)
    Pdfbox::Pdmodel::PageMode.from_string("UseOC").should eq(Pdfbox::Pdmodel::PageMode::USE_OPTIONAL_CONTENT)
    Pdfbox::Pdmodel::PageMode.from_string("UseNone").should eq(Pdfbox::Pdmodel::PageMode::USE_NONE)
    Pdfbox::Pdmodel::PageMode.from_string("UseAttachments").should eq(Pdfbox::Pdmodel::PageMode::USE_ATTACHMENTS)
    Pdfbox::Pdmodel::PageMode.from_string("UseOutlines").should eq(Pdfbox::Pdmodel::PageMode::USE_OUTLINES)
  end

  it "PageModeTest#fromStringInputNotNullOutputIllegalArgumentException*" do
    expect_raises(ArgumentError) { Pdfbox::Pdmodel::PageMode.from_string("") }
    expect_raises(ArgumentError) { Pdfbox::Pdmodel::PageMode.from_string("Dulacb`ecj") }
  end

  it "PageModeTest#stringValueOutputNotNull" do
    Pdfbox::Pdmodel::PageMode::USE_OPTIONAL_CONTENT.string_value.should eq("UseOC")
  end
end

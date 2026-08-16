require "../../../spec_helper"
require "../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/PDImmutableRectangleTest.java
describe Pdfbox::Pdmodel::Common::PDImmutableRectangle do
  it "PDImmutableRectangleTest#testClass" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle::A4
    rect.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::A0.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::A1.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::A2.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::A3.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::A4.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::A5.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::A6.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::LEGAL.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
    Pdfbox::Pdmodel::Common::PDRectangle::LETTER.should be_a(Pdfbox::Pdmodel::Common::PDImmutableRectangle)
  end

  it "PDImmutableRectangleTest#testSetUpperRightY" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle::A4
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { rect.upper_right_y = 0 }
  end

  it "PDImmutableRectangleTest#testSetUpperRightX" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle::A4
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { rect.upper_right_x = 0 }
  end

  it "PDImmutableRectangleTest#testSetLowerLeftY" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle::A4
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { rect.lower_left_y = 0 }
  end

  it "PDImmutableRectangleTest#testSetLowerLeftX" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle::A4
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { rect.lower_left_x = 0 }
  end
end

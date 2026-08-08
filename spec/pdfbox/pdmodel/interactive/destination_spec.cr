require "../../../spec_helper"
require "../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination do
  it "creates a Fit destination from an array" do
    array = Pdfbox::Cos::Array.new
    array << Pdfbox::Cos::Dictionary.new
    array << Pdfbox::Cos::Name.new("Fit")

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(array)
    destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitDestination)
  end

  it "creates a FitB destination from an array" do
    array = Pdfbox::Cos::Array.new
    array << Pdfbox::Cos::Dictionary.new
    array << Pdfbox::Cos::Name.new("FitB")

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(array)
    destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitDestination)
    destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitDestination).fit_bounding_box?.should be_true
  end

  it "creates a FitH destination from an array" do
    array = Pdfbox::Cos::Array.new
    array << Pdfbox::Cos::Dictionary.new
    array << Pdfbox::Cos::Name.new("FitH")

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(array)
    destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitWidthDestination)
  end

  it "creates a FitV destination from an array" do
    array = Pdfbox::Cos::Array.new
    array << Pdfbox::Cos::Dictionary.new
    array << Pdfbox::Cos::Name.new("FitV")

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(array)
    destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitHeightDestination)
  end

  it "creates a FitR destination from an array" do
    array = Pdfbox::Cos::Array.new
    array << Pdfbox::Cos::Dictionary.new
    array << Pdfbox::Cos::Name.new("FitR")

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(array)
    destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitRectangleDestination)
  end

  it "creates an XYZ destination from an array" do
    array = Pdfbox::Cos::Array.new
    array << Pdfbox::Cos::Dictionary.new
    array << Pdfbox::Cos::Name.new("XYZ")

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(array)
    destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageXYZDestination)
  end

  it "creates a named destination from a string" do
    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(Pdfbox::Cos::String.new("MyDest"))
    destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination)
  end
end

describe Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageXYZDestination do
  it "initializes with the XYZ type name" do
    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageXYZDestination.new
    destination.cos_object[1].as(Pdfbox::Cos::Name).value.should eq("XYZ")
  end

  it "sets and gets left, top, and zoom" do
    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageXYZDestination.new
    destination.left = 100
    destination.top = 200
    destination.zoom = 2.5

    destination.left.should eq(100)
    destination.top.should eq(200)
    destination.zoom.should eq(2.5)
  end

  it "stores null for unspecified left, top, or zoom" do
    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageXYZDestination.new
    destination.left = -1
    destination.top = -1
    destination.zoom = -1.0

    destination.cos_object[2].should be_a(Pdfbox::Cos::Null)
    destination.cos_object[3].should be_a(Pdfbox::Cos::Null)
    destination.cos_object[4].should be_a(Pdfbox::Cos::Null)
    destination.left.should eq(-1)
    destination.top.should eq(-1)
    destination.zoom.should eq(-1.0)
  end
end

describe Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitDestination do
  it "toggles between Fit and FitB" do
    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitDestination.new
    destination.fit_bounding_box?.should be_false
    destination.cos_object[1].as(Pdfbox::Cos::Name).value.should eq("Fit")

    destination.fit_bounding_box = true
    destination.fit_bounding_box?.should be_true
    destination.cos_object[1].as(Pdfbox::Cos::Name).value.should eq("FitB")
  end
end

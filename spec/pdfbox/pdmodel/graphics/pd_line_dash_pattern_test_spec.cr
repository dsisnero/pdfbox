require "../../../spec_helper"
require "../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/PDLineDashPatternTest.java
describe Pdfbox::Pdmodel::Graphics::PDLineDashPattern do
  it "PDLineDashPatternTest#testGetCOSObject" do
    array = Pdfbox::Cos::Array.new
    array.add(Pdfbox::Cos::Integer.new(1))
    array.add(Pdfbox::Cos::Integer.new(2))
    dash = Pdfbox::Pdmodel::Graphics::PDLineDashPattern.new(array, 3)

    dash_base = dash.cos_object.as(Pdfbox::Cos::Array)
    dash_array = dash_base.get(0).as(Pdfbox::Cos::Array)

    dash_base.size.should eq(2)
    dash_array.size.should eq(2)
    dash_array.get(0).as(Pdfbox::Cos::Float).value.should eq(1.0)
    dash_array.get(1).as(Pdfbox::Cos::Float).value.should eq(2.0)
    dash_base.get(1).as(Pdfbox::Cos::Integer).value.should eq(3)
  end
end

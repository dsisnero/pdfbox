require "../spec_helper"

describe "Porting parity pdfbox-uzy" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/PDLineDashPatternTest.java
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/PDLineDashPattern.java
  it "returns COS object with converted float dash array and phase" do
    arr = Pdfbox::Cos::Array.new
    arr.add(Pdfbox::Cos::Integer::ONE)
    arr.add(Pdfbox::Cos::Integer::TWO)

    dash = Pdfbox::Pdmodel::Graphics::PDLineDashPattern.new(arr, 3)
    dash_base = dash.cos_object.as(Pdfbox::Cos::Array)
    dash_array = dash_base.get(0).as(Pdfbox::Cos::Array)

    dash_base.size.should eq(2)
    dash_array.size.should eq(2)

    first = dash_array.get(0)
    first.should be_a(Pdfbox::Cos::Float)
    first.as(Pdfbox::Cos::Float).value.should eq(1.0)

    second = dash_array.get(1)
    second.should be_a(Pdfbox::Cos::Float)
    second.as(Pdfbox::Cos::Float).value.should eq(2.0)

    dash_base.get(1).should eq(Pdfbox::Cos::Integer::THREE)
  end

  it "normalizes negative phase per PDFBox logic" do
    arr = Pdfbox::Cos::Array.new
    arr.add(Pdfbox::Cos::Integer::ONE)
    arr.add(Pdfbox::Cos::Integer::TWO)

    # sum2 = 2 * (1 + 2) = 6, phase -1 becomes 5.
    dash = Pdfbox::Pdmodel::Graphics::PDLineDashPattern.new(arr, -1)
    dash.phase.should eq(5)
  end
end

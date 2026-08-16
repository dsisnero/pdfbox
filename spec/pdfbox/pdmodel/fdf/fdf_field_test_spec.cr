require "../../../spec_helper"
require "../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/fdf/FDFFieldTest.java
describe Pdfbox::Pdmodel::Fdf::FDFField do
  it "FDFFieldTest#testCOSStringValue" do
    test_string = "Test value"
    test_cos_string = Pdfbox::Cos::String.new(test_string)

    field = Pdfbox::Pdmodel::Fdf::FDFField.new
    field.cos_value = test_cos_string

    field.cos_value.should eq(test_cos_string)
    field.value.should eq(test_string)
  end

  it "FDFFieldTest#testTextAsCOSStreamValue" do
    test_string = "Test value"
    stream = Pdfbox::Cos::Stream.new
    output = stream.create_output_stream(nil)
    output.write(test_string.to_slice)
    output.close

    field = Pdfbox::Pdmodel::Fdf::FDFField.new
    field.cos_value = stream

    field.value.should eq(test_string)
  end

  it "FDFFieldTest#testCOSNameValue" do
    test_string = "Yes"
    test_cos_name = Pdfbox::Cos::Name.new(test_string)

    field = Pdfbox::Pdmodel::Fdf::FDFField.new
    field.cos_value = test_cos_name

    field.cos_value.should eq(test_cos_name)
    field.value.should eq(test_string)
  end

  it "FDFFieldTest#testCOSArrayValue" do
    test_list = ["A", "B"]
    test_cos_array = Pdfbox::Cos::Array.new
    test_list.each { |value| test_cos_array.add(Pdfbox::Cos::String.new(value)) }

    field = Pdfbox::Pdmodel::Fdf::FDFField.new
    field.cos_value = test_cos_array

    field.cos_value.should eq(test_cos_array)
    field.value.should eq(test_list)
  end
end

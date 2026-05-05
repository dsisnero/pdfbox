require "../../spec_helper"

describe Pdfbox::Cos::Dictionary do
  describe "#==" do
    it "is not equal to stream with identical dictionary entries" do
      dictionary = Pdfbox::Cos::Dictionary.new
      stream = Pdfbox::Cos::Stream.new

      be_name = Pdfbox::Cos::Name.new("BE")
      length_name = Pdfbox::Cos::Name.new("Length")

      dictionary[be_name] = be_name
      dictionary[length_name] = Pdfbox::Cos::Integer.get(0_i64)
      stream[be_name] = be_name
      stream[length_name] = Pdfbox::Cos::Integer.get(0_i64)

      (dictionary == stream).should be_false
      (stream == dictionary).should be_false
    end
  end
end

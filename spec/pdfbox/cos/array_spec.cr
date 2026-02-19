require "../../spec_helper"

describe Pdfbox::Cos::Array do
  describe ".new" do
    it "creates an empty array by default" do
      array = Pdfbox::Cos::Array.new
      array.size.should eq(0)
    end

    it "creates an array from provided values" do
      array = Pdfbox::Cos::Array.new([
        Pdfbox::Cos::Name.new("A"),
        Pdfbox::Cos::Name.new("B"),
        Pdfbox::Cos::Name.new("C"),
      ])
      array.size.should eq(3)
      array.get(0).should eq(Pdfbox::Cos::Name.new("A"))
      array.get(1).should eq(Pdfbox::Cos::Name.new("B"))
      array.get(2).should eq(Pdfbox::Cos::Name.new("C"))
    end
  end

  describe "name conversion helpers" do
    it "converts name strings to COSName and back" do
      array = Pdfbox::Cos::Array.of_cos_names(["A", "B", "C"])
      array.size.should eq(3)
      array.get(0).should eq(Pdfbox::Cos::Name.new("A"))
      array.get(1).should eq(Pdfbox::Cos::Name.new("B"))
      array.get(2).should eq(Pdfbox::Cos::Name.new("C"))
      array.to_cos_name_string_list.should eq(["A", "B", "C"])
    end
  end

  describe "string conversion helpers" do
    it "converts strings to COSString and back" do
      array = Pdfbox::Cos::Array.of_cos_strings(["A", "B", "C"])
      array.size.should eq(3)
      array.get_string(0).should eq("A")
      array.get_string(1).should eq("B")
      array.get_string(2).should eq("C")
      array.to_cos_string_string_list.should eq(["A", "B", "C"])
    end
  end

  describe "integer conversion helpers" do
    it "converts integers to COSInteger and back" do
      array = Pdfbox::Cos::Array.of_cos_integers([1, 2, 3])
      array.size.should eq(3)
      array.get_int(0).should eq(1_i64)
      array.get_int(1).should eq(2_i64)
      array.get_int(2).should eq(3_i64)
      array.to_cos_number_integer_list.should eq([1_i64, 2_i64, 3_i64])
    end
  end

  describe "#to_list" do
    it "returns a list copy of items" do
      array = Pdfbox::Cos::Array.of_cos_integers([0, 1, 2, 3, 4, 5])
      list = array.to_list
      list.size.should eq(6)
      list.first.should eq(Pdfbox::Cos::Integer.get(0_i64))
      list.last.should eq(Pdfbox::Cos::Integer.get(5_i64))
    end
  end
end

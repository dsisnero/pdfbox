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

  describe "float conversion helpers" do
    it "converts float arrays to COSFloat and back" do
      start = [1.0_f64, 0.1_f64, 0.02_f64]
      array = Pdfbox::Cos::Array.new
      array.float_array = start

      array.size.should eq(3)
      array.get(0).should eq(Pdfbox::Cos::Float.new(1.0))
      array.get(1).should eq(Pdfbox::Cos::Float.new(0.1))
      array.get(2).should eq(Pdfbox::Cos::Float.new(0.02))

      float_list = array.to_cos_number_float_list
      float_list.should eq([1.0_f64, 0.1_f64, 0.02_f64])

      ending = array.to_float_array
      ending.should eq(start)
    end

    it "maps null-like placeholders to nil/zero in numeric conversions" do
      array = Pdfbox::Cos::Array.new([
        Pdfbox::Cos::Float.new(1.0),
        Pdfbox::Cos::Null.instance,
        Pdfbox::Cos::Float.new(0.02),
      ])

      float_list = array.to_cos_number_float_list
      float_list[0].should eq(1.0_f64)
      float_list[1].should be_nil
      float_list[2].should eq(0.02_f64)

      array.to_float_array.should eq([1.0_f64, 0.0_f64, 0.02_f64])
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

  describe "set/get helpers" do
    it "supports set/get name" do
      array = Pdfbox::Cos::Array.new
      array.grow_to_size(3)
      array.set_name(0, "A")
      array.set_name(1, "B")
      array.set_name(2, "C")

      array.get_name(0).should eq("A")
      array.get_name(1).should eq("B")
      array.get_name(2).should eq("C")
      array.get_name(3, "NULL").should eq("NULL")
      array.index_of(Pdfbox::Cos::Name.new("A")).should eq(0)
      array.index_of(Pdfbox::Cos::Name.new("D")).should eq(-1)
    end

    it "supports set/get int" do
      array = Pdfbox::Cos::Array.new
      array.grow_to_size(3)
      array.set_int(0, 0)
      array.set_int(1, 1)
      array.set_int(2, 2)

      array.get_int(0).should eq(0_i64)
      array.get_int(1).should eq(1_i64)
      array.get_int(2).should eq(2_i64)
      array.get_int(3, 0_i64).should eq(0_i64)
      array.index_of(Pdfbox::Cos::Integer.get(0_i64)).should eq(0)
      array.index_of(Pdfbox::Cos::Integer.get(3_i64)).should eq(-1)
    end

    it "supports set/get string" do
      array = Pdfbox::Cos::Array.new
      array.grow_to_size(3)
      array.set_string(0, "Test1")
      array.set_string(1, "Test2")
      array.set_string(2, "Test3")

      array.get_string(0).should eq("Test1")
      array.get_string(1).should eq("Test2")
      array.get_string(2).should eq("Test3")
      array.get_string(3, "NULL").should eq("NULL")
      array.index_of(Pdfbox::Cos::String.new("Test1")).should eq(0)
      array.index_of(Pdfbox::Cos::String.new("Test4")).should eq(-1)
    end
  end

  describe "remove operations" do
    it "supports clear, remove, remove_object, remove_all, and retain_all" do
      array = Pdfbox::Cos::Array.of_cos_integers([1, 2, 3, 4, 5, 6])
      array.clear
      array.size.should eq(0)

      array = Pdfbox::Cos::Array.of_cos_integers([1, 2, 3, 4, 5, 6])
      array.remove(2).should eq(Pdfbox::Cos::Integer.get(3_i64))
      array.size.should eq(5)
      array.get_int(0).should eq(1_i64)
      array.get_int(2).should eq(4_i64)

      array.remove_object(Pdfbox::Cos::Integer.get(5_i64)).should be_true
      array.size.should eq(4)
      array.get_int(3).should eq(6_i64)

      array = Pdfbox::Cos::Array.of_cos_integers([1, 2, 3, 4, 5, 6])
      array.remove_all([Pdfbox::Cos::Integer.get(3_i64), Pdfbox::Cos::Integer.get(4_i64)])
      array.size.should eq(4)
      array.get_int(1).should eq(2_i64)
      array.get_int(2).should eq(5_i64)

      array = Pdfbox::Cos::Array.of_cos_integers([1, 2, 3, 4, 5, 6])
      array.retain_all([Pdfbox::Cos::Integer.get(3_i64), Pdfbox::Cos::Integer.get(4_i64)])
      array.size.should eq(2)
      array.get_int(0).should eq(3_i64)
      array.get_int(1).should eq(4_i64)
    end
  end

  describe "#grow_to_size" do
    it "grows and fills with default or provided value" do
      array = Pdfbox::Cos::Array.new
      array.size.should eq(0)
      array.grow_to_size(2)
      array.size.should eq(2)

      array.grow_to_size(2, Pdfbox::Cos::Integer.get(0_i64))
      array.size.should eq(2)

      array.grow_to_size(4, Pdfbox::Cos::Integer.get(1_i64))
      array.size.should eq(4)
      list = array.to_cos_number_integer_list
      list.size.should eq(4)
      list[0].should be_nil
      list[2].should eq(1_i64)
      list[3].should eq(1_i64)
    end
  end
end

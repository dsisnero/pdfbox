require "../../../spec_helper"

module Pdfbox::Pdmodel::Common
  describe PDRange do
    it "creates default range 0..1" do
      range = PDRange.new
      range.min.should eq 0.0
      range.max.should eq 1.0
    end

    it "creates from array" do
      arr = Cos::Array.new
      arr.add(Cos::Float.new(2.5))
      arr.add(Cos::Float.new(5.5))
      range = PDRange.new(arr)
      range.min.should eq 2.5
      range.max.should eq 5.5
    end

    it "creates from array with index" do
      arr = Cos::Array.new
      # Multiple ranges: [0,1, 2,3, 4,5]
      arr.add(Cos::Float.new(0.0))
      arr.add(Cos::Float.new(1.0))
      arr.add(Cos::Float.new(2.0))
      arr.add(Cos::Float.new(3.0))
      arr.add(Cos::Float.new(4.0))
      arr.add(Cos::Float.new(5.0))

      range = PDRange.new(arr, 1) # Should represent 2.0..3.0
      range.min.should eq 2.0
      range.max.should eq 3.0
    end

    it "sets min and max" do
      range = PDRange.new
      range.min = 10.5
      range.max = 20.5
      range.min.should eq 10.5
      range.max.should eq 20.5
      # Check underlying array updated
      range.cos_array[0].as(Cos::Float).value.should eq 10.5
      range.cos_array[1].as(Cos::Float).value.should eq 20.5
    end

    it "handles integer values in array" do
      arr = Cos::Array.new
      arr.add(Cos::Integer.new(10_i64))
      arr.add(Cos::Integer.new(20_i64))
      range = PDRange.new(arr)
      range.min.should eq 10.0
      range.max.should eq 20.0
    end

    it "returns cos_object as array" do
      range = PDRange.new
      cos = range.cos_object
      cos.should be_a(Cos::Array)
    end

    it "has string representation" do
      range = PDRange.new
      range.min = 1.5
      range.max = 3.5
      range.to_s.should match(/PDRange\{1\.5, 3\.5\}/)
    end
  end
end
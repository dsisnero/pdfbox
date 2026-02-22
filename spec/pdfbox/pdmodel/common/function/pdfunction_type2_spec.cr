require "../../../../spec_helper"

module Pdfbox::Pdmodel::Common::Function
  describe PDFunctionType2 do
    it "creates exponential interpolation function with defaults" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      # C0 and C1 omitted -> defaults to [0] and [1]
      # N omitted -> defaults to 0

      func = PDFunctionType2.new(dict)
      func.function_type.should eq 2
      func.c0.size.should eq 1
      func.c0[0].as(Cos::Number).value.to_f32.should eq 0.0_f32
      func.c1.size.should eq 1
      func.c1[0].as(Cos::Number).value.to_f32.should eq 1.0_f32
      func.n.should eq 0.0_f32
    end

    it "evaluates exponential function with C0=[0], C1=[1], N=1" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("C0")] = Cos::Array.new([Cos::Float.new(0.0)])
      dict[Cos::Name.new("C1")] = Cos::Array.new([Cos::Float.new(1.0)])
      dict[Cos::Name.new("N")] = Cos::Float.new(1.0)

      func = PDFunctionType2.new(dict)
      result = func.eval([0.5_f32])
      result.size.should eq 1
      result[0].should be_close(0.5_f32, 0.0001_f32)
    end

    it "clips output to range" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(0.5_f32)]) # clip upper to 0.5
      dict[Cos::Name.new("C0")] = Cos::Array.new([Cos::Float.new(0.0)])
      dict[Cos::Name.new("C1")] = Cos::Array.new([Cos::Float.new(1.0)])
      dict[Cos::Name.new("N")] = Cos::Float.new(1.0)

      func = PDFunctionType2.new(dict)
      result = func.eval([0.8_f32]) # would be 0.8, but range max is 0.5
      result[0].should be_close(0.5_f32, 0.0001_f32)
    end

    it "handles multiple output components" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0), Cos::Float.new(0.0), Cos::Float.new(2.0)])
      dict[Cos::Name.new("C0")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(0.0)])
      dict[Cos::Name.new("C1")] = Cos::Array.new([Cos::Float.new(1.0), Cos::Float.new(3.0)])
      dict[Cos::Name.new("N")] = Cos::Float.new(2.0)

      func = PDFunctionType2.new(dict)
      result = func.eval([0.5_f32])
      result.size.should eq 2
      # x^2 = 0.25
      # component 1: 0 + 0.25*(1-0) = 0.25
      # component 2: 0 + 0.25*(3-0) = 0.75
      result[0].should be_close(0.25_f32, 0.0001_f32)
      result[1].should be_close(0.75_f32, 0.0001_f32)
    end
  end
end

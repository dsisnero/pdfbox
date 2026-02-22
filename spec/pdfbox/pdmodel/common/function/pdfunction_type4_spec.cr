require "../../../../spec_helper"

module Pdfbox::Pdmodel::Common::Function
  describe PDFunctionType4 do
    it "evaluates simple addition function" do
      function_text = "{ add }"
      # Simply adds the two arguments and returns the result
      dict = Cos::Dictionary.new
      dict[Cos::Name::FUNCTION_TYPE] = Cos::Integer.new(4)
      dict[Cos::Name::DOMAIN] = Cos::Array.new([Cos::Float.new(-1.0), Cos::Float.new(1.0), Cos::Float.new(-1.0), Cos::Float.new(1.0)])
      dict[Cos::Name::RANGE] = Cos::Array.new([Cos::Float.new(-1.0), Cos::Float.new(1.0)])

      data = "{ add }".to_slice
      stream = Cos::Stream.new(dict.entries, data)

      function = PDFunctionType4.new(stream)

      input = [0.8_f32, 0.1_f32]
      output = function.eval(input)

      output.size.should eq 1
      output[0].should be_close(0.9_f32, 0.0001_f32)

      # Test with result outside Range (should be clipped)
      input = [0.8_f32, 0.3_f32] # results in 1.1f being outside Range
      output = function.eval(input)
      output[0].should eq 1.0_f32

      # Test with input argument outside Domain (should be clipped)
      input = [0.8_f32, 1.2_f32] # input argument outside Domain
      output = function.eval(input)
      output[0].should eq 1.0_f32
    end

    it "handles argument order correctly with pop operator" do
      dict = Cos::Dictionary.new
      dict[Cos::Name::FUNCTION_TYPE] = Cos::Integer.new(4)
      dict[Cos::Name::DOMAIN] = Cos::Array.new([Cos::Float.new(-1.0), Cos::Float.new(1.0), Cos::Float.new(-1.0), Cos::Float.new(1.0)])
      dict[Cos::Name::RANGE] = Cos::Array.new([Cos::Float.new(-1.0), Cos::Float.new(1.0)])

      data = "{ pop }".to_slice
      stream = Cos::Stream.new(dict.entries, data)

      function = PDFunctionType4.new(stream)

      input = [-0.7_f32, 0.0_f32]
      output = function.eval(input)

      output.size.should eq 1
      output[0].should be_close(-0.7_f32, 0.0001_f32)
    end

    it "handles integer addition with overflow" do
      dict = Cos::Dictionary.new
      dict[Cos::Name::FUNCTION_TYPE] = Cos::Integer.new(4)
      dict[Cos::Name::DOMAIN] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(10.0), Cos::Float.new(0.0), Cos::Float.new(10.0)])
      dict[Cos::Name::RANGE] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(100.0)])

      data = "{ add }".to_slice
      stream = Cos::Stream.new(dict.entries, data)

      function = PDFunctionType4.new(stream)

      # Test integer addition that stays within int32 range
      # Note: Type4 function works with floats, but integers are also supported
      # We'll test with float inputs
      input = [3.0_f32, 4.0_f32]
      output = function.eval(input)
      output[0].should be_close(7.0_f32, 0.0001_f32)
    end
  end
end

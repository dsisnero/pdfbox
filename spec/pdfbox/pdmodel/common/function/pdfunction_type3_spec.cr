require "../../../../spec_helper"

module Pdfbox::Pdmodel::Common::Function
  describe PDFunctionType3 do
    it "creates stitching function with basic properties" do
      # Create a Type3 stitching function that stitches two Type2 functions
      # Domain: [0, 10]
      # Bounds: [5] (so two subdomains: [0,5] and [5,10])
      # Functions: two Type2 functions
      # Encode: [0, 1, 0, 1] (identity mapping for both subfunctions)
      
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(3)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(10.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(10.0)])
      
      # Bounds array
      dict[Cos::Name.new("Bounds")] = Cos::Array.new([Cos::Float.new(5.0)])
      
      # Create two Type2 functions
      func1_dict = Cos::Dictionary.new
      func1_dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
      func1_dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      func1_dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(5.0)])
      func1_dict[Cos::Name.new("N")] = Cos::Float.new(1.0) # linear
      
      func2_dict = Cos::Dictionary.new
      func2_dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
      func2_dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      func2_dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(5.0), Cos::Float.new(10.0)])
      func2_dict[Cos::Name.new("N")] = Cos::Float.new(1.0) # linear
      
      # Functions array
      functions_array = Cos::Array.new([func1_dict, func2_dict])
      dict[Cos::Name.new("Functions")] = functions_array
      
      # Encode array
      dict[Cos::Name.new("Encode")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0), Cos::Float.new(0.0), Cos::Float.new(1.0)])
      
      func = PDFunctionType3.new(dict)
      func.function_type.should eq 3
      func.functions.size.should eq 2
      func.bounds.size.should eq 1
      func.encode.size.should eq 4
    end

    it "evaluates stitching function with two linear subfunctions" do
      # Create a simple stitching function that stitches two identity functions
      # First subfunction: maps [0,5] -> [0,5] (identity)
      # Second subfunction: maps [5,10] -> [5,10] (identity)
      
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(3)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(10.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(10.0)])
      
      # Bounds array
      dict[Cos::Name.new("Bounds")] = Cos::Array.new([Cos::Float.new(5.0)])
      
      # Create two Type2 identity functions (N=1)
      # First function: maps [0,1] -> [0,5] with C0=[0], C1=[5]
      func1_dict = Cos::Dictionary.new
      func1_dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
      func1_dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      func1_dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(5.0)])
      func1_dict[Cos::Name.new("C0")] = Cos::Array.new([Cos::Float.new(0.0)])
      func1_dict[Cos::Name.new("C1")] = Cos::Array.new([Cos::Float.new(5.0)])
      func1_dict[Cos::Name.new("N")] = Cos::Float.new(1.0)
      
      # Second function: maps [0,1] -> [5,10] with C0=[5], C1=[10]
      func2_dict = Cos::Dictionary.new
      func2_dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
      func2_dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      func2_dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(5.0), Cos::Float.new(10.0)])
      func2_dict[Cos::Name.new("C0")] = Cos::Array.new([Cos::Float.new(5.0)])
      func2_dict[Cos::Name.new("C1")] = Cos::Array.new([Cos::Float.new(10.0)])
      func2_dict[Cos::Name.new("N")] = Cos::Float.new(1.0)
      
      functions_array = Cos::Array.new([func1_dict, func2_dict])
      dict[Cos::Name.new("Functions")] = functions_array
      
      # Encode: map [0,5] -> [0,1] and [5,10] -> [0,1]
      dict[Cos::Name.new("Encode")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0), Cos::Float.new(0.0), Cos::Float.new(1.0)])
      
      func = PDFunctionType3.new(dict)
      
      # Test at x=2.5 (in first subdomain)
      result = func.eval([2.5_f32])
      result.size.should eq 1
      # Should map through first function: 2.5 in [0,5] -> 0.5 in [0,1] -> 2.5 in [0,5]
      result[0].should be_close(2.5_f32, 0.001_f32)
      
      # Test at x=7.5 (in second subdomain)
      result = func.eval([7.5_f32])
      result.size.should eq 1
      # Should map through second function: 7.5 in [5,10] -> 0.5 in [0,1] -> 7.5 in [5,10]
      result[0].should be_close(7.5_f32, 0.001_f32)
      
      # Test at boundaries
      result = func.eval([0.0_f32])
      result[0].should be_close(0.0_f32, 0.001_f32)
      
      result = func.eval([5.0_f32])
      result[0].should be_close(5.0_f32, 0.001_f32)
      
      result = func.eval([10.0_f32])
      result[0].should be_close(10.0_f32, 0.001_f32)
    end
  end
end
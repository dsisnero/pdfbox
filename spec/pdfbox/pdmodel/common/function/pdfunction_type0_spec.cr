require "../../../../spec_helper"

module Pdfbox::Pdmodel::Common::Function
  describe PDFunctionType0 do
    it "creates sampled function with basic properties" do
      # Create a simple 1D sampled function with 2 samples
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(0)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Size")] = Cos::Array.new([Cos::Integer.new(2)])
      dict[Cos::Name.new("BitsPerSample")] = Cos::Integer.new(8)

      # Sample data: two samples [0, 255] representing 0.0 and 1.0
      data = Bytes[0_u8, 255_u8]
      stream = Cos::Stream.new(dict.entries, data)

      func = PDFunctionType0.new(stream)
      func.function_type.should eq 0
      func.size.size.should eq 1
      func.size[0].as(Cos::Integer).value.should eq 2
      func.bits_per_sample.should eq 8
      func.order.should eq 1 # default
    end

    it "evaluates 1D sampled function with linear interpolation" do
      # Simple test: two samples at x=0 and x=1 with values 0 and 255
      # After scaling (0..255 -> 0..1), sample values are 0.0 and 1.0
      # Interpolation should be linear
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(0)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Size")] = Cos::Array.new([Cos::Integer.new(2)])
      dict[Cos::Name.new("BitsPerSample")] = Cos::Integer.new(8)
      # Encode defaults to [0 (Size[0]-1)] = [0, 1]
      # Decode defaults to Range = [0, 1]

      data = Bytes[0_u8, 255_u8]
      stream = Cos::Stream.new(dict.entries, data)

      func = PDFunctionType0.new(stream)

      # Test at x=0.0 -> should be 0.0
      result = func.eval([0.0_f32])
      result.size.should eq 1
      result[0].should be_close(0.0_f32, 0.001_f32)

      # Test at x=1.0 -> should be 1.0
      result = func.eval([1.0_f32])
      result[0].should be_close(1.0_f32, 0.001_f32)

      # Test at x=0.5 -> should be 0.5 (linear interpolation between samples)
      result = func.eval([0.5_f32])
      result[0].should be_close(0.5_f32, 0.001_f32)
    end

    it "handles multiple output components" do
      # 1 input, 2 outputs, size=2 samples
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(0)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([
        Cos::Float.new(0.0), Cos::Float.new(1.0),
        Cos::Float.new(0.0), Cos::Float.new(2.0),
      ])
      dict[Cos::Name.new("Size")] = Cos::Array.new([Cos::Integer.new(2)])
      dict[Cos::Name.new("BitsPerSample")] = Cos::Integer.new(8)

      # Two samples, each with 2 output values
      # Sample 0: [0, 0]
      # Sample 1: [255, 510] (scaled to [1.0, 2.0])
      # But bits per sample is 8, max 255, so second component would overflow
      # Let's use smaller values
      # Actually we need 16 bits total per sample? No, each output component separate
      # BitsPerSample applies per component. With 8 bits, each component is 0-255
      # So we need to scale: for second component range [0,2], value 510 would be 255*2
      # But 510 > 255, can't represent. So adjust range or use higher bits.
      # Let's use BitsPerSample=16
      dict[Cos::Name.new("BitsPerSample")] = Cos::Integer.new(16)
      # Data: 2 samples * 2 components * 2 bytes each = 8 bytes
      # Sample 0: component1=0 (0x0000), component2=0 (0x0000)
      # Sample 1: component1=65535 (0xFFFF -> 1.0), component2=65535 (0xFFFF -> 2.0)
      data = Bytes[
        0x00, 0x00, 0x00, 0x00, # sample 0
        0xFF, 0xFF, 0xFF, 0xFF  # sample 1
      ]
      stream = Cos::Stream.new(dict.entries, data)

      func = PDFunctionType0.new(stream)
      func.bits_per_sample.should eq 16

      # Test interpolation
      result = func.eval([0.5_f32])
      result.size.should eq 2
      # component1: 0.5, component2: 1.0
      result[0].should be_close(0.5_f32, 0.001_f32)
      result[1].should be_close(1.0_f32, 0.001_f32)
    end

    it "clips input to domain" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(0)
      dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Range")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
      dict[Cos::Name.new("Size")] = Cos::Array.new([Cos::Integer.new(2)])
      dict[Cos::Name.new("BitsPerSample")] = Cos::Integer.new(8)
      data = Bytes[0_u8, 255_u8]
      stream = Cos::Stream.new(dict.entries, data)

      func = PDFunctionType0.new(stream)

      # Input below domain
      result = func.eval([-0.5_f32])
      result[0].should be_close(0.0_f32, 0.001_f32)

      # Input above domain
      result = func.eval([1.5_f32])
      result[0].should be_close(1.0_f32, 0.001_f32)
    end
  end
end

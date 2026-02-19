require "../../spec_helper"

describe Pdfbox::Cos::Float do
  describe "#write_pdf" do
    it "writes non-scientific values as-is" do
      io = IO::Memory.new
      Pdfbox::Cos::Float.new(1.25).write_pdf(io)
      io.to_s.should eq("1.25")
    end

    it "expands scientific notation to plain decimal for tiny values" do
      io = IO::Memory.new
      Pdfbox::Cos::Float.new(1e-33).write_pdf(io)
      io.to_s.should eq("0.000000000000000000000000000000001")
    end
  end

  describe "#to_s" do
    it "matches Java COSFloat wrapper format" do
      Pdfbox::Cos::Float.new(1.25).to_s.should eq("COSFloat{1.25}")
    end
  end

  describe "#==" do
    it "uses bitwise float comparison semantics" do
      Pdfbox::Cos::Float.new(-0.0).should_not eq(Pdfbox::Cos::Float.new(0.0))
    end
  end
end

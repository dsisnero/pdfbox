require "../../spec_helper"

describe Pdfbox::Cos::Integer do
  describe ".get" do
    it "returns cached instances for range -100..256" do
      (-100_i64..256_i64).step(50_i64).each do |i|
        Pdfbox::Cos::Integer.get(i).should be(Pdfbox::Cos::Integer.get(i))
      end
    end

    it "returns distinct instances outside cache range" do
      x = Pdfbox::Cos::Integer.get(-101_i64)
      y = Pdfbox::Cos::Integer.get(-101_i64)
      x.should_not be(y)
      x.should eq(y)
    end
  end

  describe "#==" do
    it "satisfies equality contract across a representative range" do
      (-1000_i64...3000_i64).step(200_i64) do |i|
        test1 = Pdfbox::Cos::Integer.get(i)
        test2 = Pdfbox::Cos::Integer.get(i)
        test3 = Pdfbox::Cos::Integer.get(i)

        (test1 == test1).should be_true
        (test2 == test1).should be_true
        (test1 == test2).should be_true
        (test1 == test2).should be_true
        (test2 == test3).should be_true
        (test1 == test3).should be_true

        test4 = Pdfbox::Cos::Integer.get(i + 1_i64)
        (test4 == test1).should be_false
      end
    end
  end

  describe "#hash" do
    it "is equal for equal values and different for neighboring values" do
      (-1000_i64...3000_i64).step(200_i64) do |i|
        test1 = Pdfbox::Cos::Integer.get(i)
        test2 = Pdfbox::Cos::Integer.get(i)
        test1.hash.should eq(test2.hash)

        test3 = Pdfbox::Cos::Integer.get(i + 1_i64)
        test3.hash.should_not eq(test1.hash)
      end
    end
  end

  describe "#value" do
    it "returns numeric values across range" do
      (-1000_i64...3000_i64).step(200_i64) do |i|
        Pdfbox::Cos::Integer.get(i).value.should eq(i)
      end
    end
  end

  describe "#to_s" do
    it "matches Java String.valueOf formatting" do
      (-1000_i64...3000_i64).step(200_i64) do |i|
        Pdfbox::Cos::Integer.get(i).to_s.should eq(i.to_s)
      end
    end
  end

  describe "#write_pdf" do
    it "writes integer text tokens exactly" do
      (-1000_i64...3000_i64).step(200_i64) do |i|
        io = IO::Memory.new
        Pdfbox::Cos::Integer.get(i).write_pdf(io)
        io.to_s.should eq(i.to_s)
      end
    end
  end
end

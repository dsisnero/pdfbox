require "../../spec_helper"

describe Pdfbox::Cos::ObjectKey do
  describe ".new" do
    it "rejects negative object numbers" do
      expect_raises(ArgumentError) do
        Pdfbox::Cos::ObjectKey.new(-1_i64, 0_i64)
      end
    end

    it "rejects negative generation numbers" do
      expect_raises(ArgumentError) do
        Pdfbox::Cos::ObjectKey.new(1_i64, -1_i64)
      end
    end
  end

  describe "#<=>" do
    it "returns zero for equal keys" do
      key = Pdfbox::Cos::ObjectKey.new(1_i64, 0_i64)
      other = Pdfbox::Cos::ObjectKey.new(1_i64, 0_i64)

      (key <=> other).should eq(0)
    end

    it "orders by object number first, then generation number" do
      key40 = Pdfbox::Cos::ObjectKey.new(4_i64, 0_i64)
      key41 = Pdfbox::Cos::ObjectKey.new(4_i64, 1_i64)
      key50 = Pdfbox::Cos::ObjectKey.new(5_i64, 0_i64)

      (key40 <=> key41).should eq(-1)
      (key40 <=> key50).should eq(-1)
      (key41 <=> key50).should eq(-1)
      (key50 <=> key41).should eq(1)
    end
  end

  describe "#==" do
    it "compares number and generation" do
      Pdfbox::Cos::ObjectKey.new(100_i64, 0_i64).should eq(Pdfbox::Cos::ObjectKey.new(100_i64, 0_i64))
      Pdfbox::Cos::ObjectKey.new(100_i64, 0_i64).should_not eq(Pdfbox::Cos::ObjectKey.new(101_i64, 0_i64))
    end
  end

  describe "internal representation" do
    it "preserves number and generation values" do
      key = Pdfbox::Cos::ObjectKey.new(100_i64, 0_i64)
      key.number.should eq(100_i64)
      key.generation.should eq(0_i64)

      key = Pdfbox::Cos::ObjectKey.new(200_i64, 4_i64)
      key.number.should eq(200_i64)
      key.generation.should eq(4_i64)

      key = Pdfbox::Cos::ObjectKey.new(200_000_i64, 0_i64)
      key.number.should eq(200_000_i64)
      key.generation.should eq(0_i64)

      key = Pdfbox::Cos::ObjectKey.new(87_654_321_i64, 123_i64)
      key.number.should eq(87_654_321_i64)
      key.generation.should eq(123_i64)
    end
  end

  describe "#hash" do
    it "matches for equivalent keys" do
      Pdfbox::Cos::ObjectKey.new(100_i64, 0_i64).hash.should eq(Pdfbox::Cos::ObjectKey.new(100_i64, 0_i64).hash)
    end

    it "differs for different object numbers" do
      Pdfbox::Cos::ObjectKey.new(100_i64, 0_i64).hash.should_not eq(Pdfbox::Cos::ObjectKey.new(200_i64, 0_i64).hash)
    end

    it "differs when number and generation differ even if sum is equal" do
      Pdfbox::Cos::ObjectKey.new(100_i64, 0_i64).hash.should_not eq(Pdfbox::Cos::ObjectKey.new(99_i64, 1_i64).hash)
    end
  end

  pending "preserves rendering across split documents (PDFBOX-5742)" do
    # Java TestCOSObjectKey#testPDFBox5742 depends on Splitter + PDFRenderer + image diff helpers.
    # This remains blocked until split/render parity is implemented in Crystal.
  end
end

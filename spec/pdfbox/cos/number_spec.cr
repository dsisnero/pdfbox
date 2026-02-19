require "../../spec_helper"

describe "COSNumber behavior" do
  describe ".get" do
    it "returns static single-digit integers and special one-char fallbacks" do
      Pdfbox::Cos::Number.get("0").should eq(Pdfbox::Cos::Integer::ZERO)
      Pdfbox::Cos::Number.get("-").should eq(Pdfbox::Cos::Integer::ZERO)
      Pdfbox::Cos::Number.get(".").should eq(Pdfbox::Cos::Integer::ZERO)
      Pdfbox::Cos::Number.get("1").should eq(Pdfbox::Cos::Integer::ONE)
      Pdfbox::Cos::Number.get("2").should eq(Pdfbox::Cos::Integer::TWO)
      Pdfbox::Cos::Number.get("3").should eq(Pdfbox::Cos::Integer::THREE)
    end

    it "parses integer and float strings" do
      Pdfbox::Cos::Number.get("100").should eq(Pdfbox::Cos::Integer.get(100_i64))
      Pdfbox::Cos::Number.get("+2000").should eq(Pdfbox::Cos::Integer.get(2000_i64))
      Pdfbox::Cos::Number.get("-1000").should eq(Pdfbox::Cos::Integer.get(-1000_i64))

      Pdfbox::Cos::Number.get("1.1").should eq(Pdfbox::Cos::Float.new(1.1))
      Pdfbox::Cos::Number.get("100.0").should eq(Pdfbox::Cos::Float.new(100.0))
      Pdfbox::Cos::Number.get("-100.001").should eq(Pdfbox::Cos::Float.new(-100.001))
      Pdfbox::Cos::Number.get("-2e-006").should be_a(Pdfbox::Cos::Float)
      Pdfbox::Cos::Number.get("-8e+05").should be_a(Pdfbox::Cos::Float)
    end

    it "raises on invalid number text" do
      expect_raises(Pdfbox::Cos::Error) { Pdfbox::Cos::Number.get("a") }
      expect_raises(Pdfbox::Cos::Error) { Pdfbox::Cos::Number.get("18446744073307F448448") }
    end
  end

  it "marks out-of-range integer values as invalid" do
    max = Pdfbox::Cos::Number.get("9223372036854775807")
    max.should be_a(Pdfbox::Cos::Integer)
    max.as(Pdfbox::Cos::Integer).valid?.should be_true

    min = Pdfbox::Cos::Number.get("-9223372036854775808")
    min.should be_a(Pdfbox::Cos::Integer)
    min.as(Pdfbox::Cos::Integer).valid?.should be_true

    out_max = Pdfbox::Cos::Number.get("18446744073307448448")
    out_max.should be_a(Pdfbox::Cos::Integer)
    out_max.as(Pdfbox::Cos::Integer).valid?.should be_false

    out_min = Pdfbox::Cos::Number.get("-18446744073307448448")
    out_min.should be_a(Pdfbox::Cos::Integer)
    out_min.as(Pdfbox::Cos::Integer).valid?.should be_false
  end
end

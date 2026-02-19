require "../../spec_helper"

describe Pdfbox::Cos::Boolean do
  describe ".get" do
    it "returns singleton instances" do
      Pdfbox::Cos::Boolean.get(true).should be(Pdfbox::Cos::Boolean::TRUE)
      Pdfbox::Cos::Boolean.get(false).should be(Pdfbox::Cos::Boolean::FALSE)
    end
  end

  describe "#value" do
    it "returns primitive value" do
      Pdfbox::Cos::Boolean::TRUE.value.should be_true
      Pdfbox::Cos::Boolean::FALSE.value.should be_false
    end
  end

  describe "#value_as_object" do
    it "returns value as object-compatible bool" do
      Pdfbox::Cos::Boolean::TRUE.value_as_object.should be_true
      Pdfbox::Cos::Boolean::FALSE.value_as_object.should be_false
    end
  end

  describe "#==" do
    it "is reflexive, symmetric, and transitive for singleton values" do
      test1 = Pdfbox::Cos::Boolean::TRUE
      test2 = Pdfbox::Cos::Boolean::TRUE
      test3 = Pdfbox::Cos::Boolean::TRUE

      (test1 == test1).should be_true
      (test2 == test1).should be_true
      (test1 == test2).should be_true
      (test1 == test2).should be_true
      (test2 == test3).should be_true
      (test1 == test3).should be_true
    end

    it "is not equal across true/false and different types" do
      (Pdfbox::Cos::Boolean::TRUE == Pdfbox::Cos::Boolean::FALSE).should be_false
      (Pdfbox::Cos::Boolean::TRUE == true).should be_false
      (Pdfbox::Cos::Boolean::FALSE == false).should be_false
    end
  end

  describe "#hash" do
    it "matches Java Boolean hash values used by PDFBox" do
      Pdfbox::Cos::Boolean::TRUE.hash.should eq(1231)
      Pdfbox::Cos::Boolean::FALSE.hash.should eq(1237)
    end
  end

  describe "#to_s" do
    it "returns lowercase PDF boolean literal" do
      Pdfbox::Cos::Boolean::TRUE.to_s.should eq("true")
      Pdfbox::Cos::Boolean::FALSE.to_s.should eq("false")
    end
  end

  describe "#write_pdf" do
    it "writes literal boolean tokens" do
      io = IO::Memory.new
      Pdfbox::Cos::Boolean::TRUE.write_pdf(io)
      io.to_s.should eq("true")

      io.clear
      Pdfbox::Cos::Boolean::FALSE.write_pdf(io)
      io.to_s.should eq("false")
    end
  end
end

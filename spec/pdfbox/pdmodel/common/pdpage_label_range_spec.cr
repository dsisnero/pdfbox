require "../../../spec_helper"

module Pdfbox::Pdmodel::Common
  describe PDPageLabelRange do
    it "creates empty range" do
      range = PDPageLabelRange.new
      range.style.should be_nil
      range.start.should eq 1
      range.prefix.should be_nil
    end

    it "sets and gets style" do
      range = PDPageLabelRange.new
      range.style = PDPageLabelRange::STYLE_DECIMAL
      range.style.should eq PDPageLabelRange::STYLE_DECIMAL
      range.style = nil
      range.style.should be_nil
    end

    it "sets and gets start" do
      range = PDPageLabelRange.new
      range.start = 5
      range.start.should eq 5
    end

    it "raises error for non-positive start" do
      range = PDPageLabelRange.new
      expect_raises(ArgumentError, "positive integer") do
        range.start = 0
      end
      expect_raises(ArgumentError, "positive integer") do
        range.start = -1
      end
    end

    it "sets and gets prefix" do
      range = PDPageLabelRange.new
      range.prefix = "Appendix "
      range.prefix.should eq "Appendix "
      range.prefix = nil
      range.prefix.should be_nil
    end

    it "initializes from dictionary" do
      dict = Cos::Dictionary.new
      dict.set_name(Cos::Name::S, PDPageLabelRange::STYLE_ROMAN_UPPER)
      dict.set_int(Cos::Name::ST, 10_i64)
      dict.set_string(Cos::Name::P, "Page ")

      range = PDPageLabelRange.new(dict)
      range.style.should eq PDPageLabelRange::STYLE_ROMAN_UPPER
      range.start.should eq 10
      range.prefix.should eq "Page "
    end
  end
end
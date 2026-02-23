require "../../../spec_helper"

module Pdfbox::Pdmodel::Common
  describe PDPageLabels do
    doc = Pdfbox::Pdmodel::Document.new

    it "creates empty page labels with default range" do
      labels = PDPageLabels.new(doc)
      labels.page_range_count.should eq 1
      default = labels.page_label_range(0)
      default.should_not be_nil
      default.not_nil!.style.should eq PDPageLabelRange::STYLE_DECIMAL
      default.not_nil!.start.should eq 1
    end

    it "sets and retrieves label range" do
      labels = PDPageLabels.new(doc)
      range = PDPageLabelRange.new
      range.style = PDPageLabelRange::STYLE_ROMAN_UPPER
      range.start = 5
      labels.set_label_item(3, range)
      labels.page_label_range(3).should eq range
      labels.page_range_count.should eq 2
    end

    it "rejects negative start page" do
      labels = PDPageLabels.new(doc)
      range = PDPageLabelRange.new
      expect_raises(ArgumentError, "startPage") do
        labels.set_label_item(-1, range)
      end
    end

    it "creates from dictionary" do
      dict = Cos::Dictionary.new
      nums = Cos::Array.new
      nums.add(Cos::Integer.new(0_i64))
      label_dict = Cos::Dictionary.new
      label_dict.set_name(Cos::Name::S, PDPageLabelRange::STYLE_LETTERS_UPPER)
      label_dict.set_int(Cos::Name::ST, 2_i64)
      nums.add(label_dict)
      dict.set_item(Cos::Name::NUMS, nums)

      labels = PDPageLabels.new(doc, dict)
      labels.page_range_count.should eq 1 # default replaced by dict entry
      range = labels.page_label_range(0)
      range.should_not be_nil
      range.not_nil!.style.should eq PDPageLabelRange::STYLE_LETTERS_UPPER
      range.not_nil!.start.should eq 2
    end

    it "creates cos object" do
      labels = PDPageLabels.new(doc)
      range = PDPageLabelRange.new
      range.style = PDPageLabelRange::STYLE_ROMAN_LOWER
      range.start = 10
      labels.set_label_item(5, range)

      cos = labels.cos_object
      cos.should be_a(Cos::Dictionary)
      nums = cos.as(Cos::Dictionary)[Cos::Name::NUMS].as?(Cos::Array)
      nums.should_not be_nil
      # Should contain both default (0) and our entry (5)
      nums.not_nil!.size.should eq 4
    end
  end
end

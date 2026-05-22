require "../../spec_helper"

describe Pdfbox::Text::PDFTextStripper do
  describe "#multiply_float" do
    it "multiplies and truncates to 3 decimal places (matches Java multiplyFloat)" do
      stripper = Pdfbox::Text::PDFTextStripper.new
      result = stripper.test_multiply_float(2.5_f32, 10.123_f32)
      result.should eq(25.308_f32)

      result = stripper.test_multiply_float(1.0_f32, 0.001_f32)
      result.should eq(0.001_f32)
    end
  end
end

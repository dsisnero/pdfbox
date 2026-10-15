require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/text/PDFTextStripper.java
#     get/setSpacingTolerance (.5f), get/setAverageCharTolerance (.3f),
#     get/setWordSeparator (" "), get/setAddMoreFormatting (false).
describe "PDFTextStripper formatting options" do
  it "exposes the defaults (Java getters)" do
    stripper = Pdfbox::Text::PDFTextStripper.new
    stripper.spacing_tolerance.should eq(0.5_f32)
    stripper.average_char_tolerance.should eq(0.3_f32)
    stripper.word_separator.should eq(" ")
    stripper.add_more_formatting?.should be_false
  end

  it "round-trips the formatting options (Java setters)" do
    stripper = Pdfbox::Text::PDFTextStripper.new
    stripper.spacing_tolerance = 1.25_f32
    stripper.spacing_tolerance.should eq(1.25_f32)

    stripper.average_char_tolerance = 0.75_f32
    stripper.average_char_tolerance.should eq(0.75_f32)

    stripper.word_separator = "\t"
    stripper.word_separator.should eq("\t")

    stripper.add_more_formatting = true
    stripper.add_more_formatting?.should be_true
  end
end

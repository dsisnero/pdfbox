require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/fontbox/src/main/java/org/apache/fontbox/cff/CFFFont.java
#     getData, getNumCharStrings and toString. Upstream has no dedicated test for
#     these accessors; this is a characterization spec.
module Fontbox::CFF
  describe CFFFont do
    font = CFFParser.new.parse(File.read("spec/resources/fonts/SourceSansProBold.otf").to_slice).first

    it "returns the raw CFF data" do
      font.data.should eq(font.source.not_nil!.bytes)
      font.data.size.should be > 0
    end

    it "returns the number of charstrings" do
      font.num_char_strings.should eq(font.char_strings.size)
    end

    it "stringifies like Java's CFFFont#toString" do
      text = font.to_s
      text.should start_with("CFFType1Font[name=#{font.name}")
      text.should contain(", topDict={")
      text.should contain(", charset=")
      text.should contain(", charStrings=[[")
      text.should end_with("]")

      # Java `Arrays.deepToString` renders each charstring as signed decimals.
      first_char_string = font.char_strings.first
      expected = "[" + first_char_string.map { |byte| byte < 128 ? byte.to_s : (byte.to_i32 - 256).to_s }.join(", ") + "]"
      text.should contain(expected)
    end
  end
end

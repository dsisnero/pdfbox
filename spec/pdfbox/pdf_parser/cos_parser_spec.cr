require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdfparser/TestCOSParser.java
describe Pdfbox::Pdfparser::COSParser do
  it "matches TestCOSParser#testCheckForEndOfString" do
    # (Test)
    buffer = Pdfbox::IO::RandomAccessReadBuffer.new(Bytes[40, 84, 101, 115, 116, 41])
    cos_parser = Pdfbox::Pdfparser::COSParser.new(buffer)
    cos_parser.parse_cos_literal_string.value.should eq("Test")

    output = "(Test"
    # The literal string ends when the next line starts with '/' or '>' after
    # LF / CR / CRLF; a lone ')' already ends the '(' string.
    cases = [
      Bytes[40, 40, 84, 101, 115, 116, 41, 10, 47, 32], # ((Test) + LF + "/ "
      Bytes[40, 40, 84, 101, 115, 116, 41, 13, 47, 32], # ((Test) + CR + "/ "
      Bytes[40, 40, 84, 101, 115, 116, 41, 13, 10, 47], # ((Test) + CR + LF + "/"
      Bytes[40, 40, 84, 101, 115, 116, 41, 10, 62, 32], # ((Test) + LF + "> "
      Bytes[40, 40, 84, 101, 115, 116, 41, 13, 62, 32], # ((Test) + CR + "> "
      Bytes[40, 40, 84, 101, 115, 116, 41, 13, 10, 62], # ((Test) + CR + LF + ">"
    ]

    cases.each do |bytes|
      random_access = Pdfbox::IO::RandomAccessReadBuffer.new(bytes)
      Pdfbox::Pdfparser::COSParser.new(random_access).parse_cos_literal_string.value.should eq(output)
    end
  end
end

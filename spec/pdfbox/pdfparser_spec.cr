require "../spec_helper"

describe Pdfbox::Pdfparser::COSParser do
  describe "#parse_cos_literal_string" do
    it "parses simple literal string (Test)" do
      # (Test) bytes: 40, 84, 101, 115, 116, 41
      bytes = Bytes[40, 84, 101, 115, 116, 41]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("Test")
    end

    it "parses literal string with nested parentheses and LF delimiter" do
      # ((Test) + LF + "/ "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 10, '/'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and CR delimiter" do
      # ((Test) + CR + "/ "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, '/'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and CRLF delimiter" do
      # ((Test) + CR + LF + "/ "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, 10, '/'.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and LF > delimiter" do
      # ((Test) + LF + "> "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 10, '>'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and CR > delimiter" do
      # ((Test) + CR + "> "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, '>'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end

    it "parses literal string with nested parentheses and CRLF > delimiter" do
      # ((Test) + CR + LF + "> "
      bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, 10, '>'.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end
  end
end

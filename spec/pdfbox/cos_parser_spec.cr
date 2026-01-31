require "../spec_helper"

describe Pdfbox::Pdfparser::COSParser do
  describe "#parse_cos_literal_string" do
    it "checks for end of string with following characters" do
      # (Test)
      input_bytes = Bytes[40, 84, 101, 115, 116, 41]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(input_bytes)
      cos_parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = cos_parser.parse_cos_literal_string
      cos_string.value.should eq("Test")

      # ((Test) + LF + "/ "
      input_bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 10, '/'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(input_bytes)
      cos_parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = cos_parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")

      # ((Test) + CR + "/ "
      input_bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, '/'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(input_bytes)
      cos_parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = cos_parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")

      # ((Test) + CR + LF + "/ "
      input_bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, 10, '/'.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(input_bytes)
      cos_parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = cos_parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")

      # ((Test) + LF + "> "
      input_bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 10, '>'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(input_bytes)
      cos_parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = cos_parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")

      # ((Test) + CR + "> "
      input_bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, '>'.ord, ' '.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(input_bytes)
      cos_parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = cos_parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")

      # ((Test) + CR + LF + "> "
      input_bytes = Bytes['('.ord, '('.ord, 'T'.ord, 'e'.ord, 's'.ord, 't'.ord, ')'.ord, 13, 10, '>'.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(input_bytes)
      cos_parser = Pdfbox::Pdfparser::COSParser.new(source)
      cos_string = cos_parser.parse_cos_literal_string
      cos_string.value.should eq("(Test")
    end
  end
end

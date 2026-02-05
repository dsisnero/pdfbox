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

class SpecCOSParser < Pdfbox::Pdfparser::COSParser
  def parse_stream_for_spec(dict : Pdfbox::Cos::Dictionary) : Pdfbox::Cos::Stream
    parse_cos_stream(dict)
  end
end

describe Pdfbox::Pdfparser::COSParser do
  describe "#parse_cos_stream" do
    it "reads stream keyword and data" do
      bytes = Bytes['s'.ord, 't'.ord, 'r'.ord, 'e'.ord, 'a'.ord, 'm'.ord, '\n'.ord,
        'a'.ord, 'b'.ord, 'c'.ord, '\n'.ord,
        'e'.ord, 'n'.ord, 'd'.ord, 's'.ord, 't'.ord, 'r'.ord, 'e'.ord, 'a'.ord, 'm'.ord]
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      parser = SpecCOSParser.new(source)
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("Length")] = Pdfbox::Cos::Integer.new(3_i64)

      stream = parser.parse_stream_for_spec(dict)
      stream.data.should eq(Bytes['a'.ord, 'b'.ord, 'c'.ord])
    end
  end
end

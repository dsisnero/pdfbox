require "../../spec_helper"

describe Pdfbox::Pdfparser::PDFObjectStreamParser do
  build_parser = -> do
    source = Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)
    Pdfbox::Pdfparser::Parser.new(source)
  end

  it "parses object number offsets and single objects (PDFObjectStreamParserTest#testOffsetParsing)" do
    stream = Pdfbox::Cos::Stream.new
    stream[Pdfbox::Cos::Name.new("N")] = Pdfbox::Cos::Integer.new(2)
    stream[Pdfbox::Cos::Name.new("First")] = Pdfbox::Cos::Integer.new(8)

    output = stream.create_output_stream
    output << "4 0 6 5 true false"
    output.close

    parser = build_parser.call
    object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
    object_numbers = object_stream_parser.read_object_numbers
    object_numbers.size.should eq(2)
    object_numbers[4_i64]?.should eq(0)
    object_numbers[6_i64]?.should eq(5)

    parser = build_parser.call
    object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
    object_stream_parser.parse_object(4).should eq(Pdfbox::Cos::Boolean::TRUE)

    parser = build_parser.call
    object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
    object_stream_parser.parse_object(6).should eq(Pdfbox::Cos::Boolean::FALSE)
  end

  it "parses all objects from object stream (PDFObjectStreamParserTest#testParseAllObjects)" do
    stream = Pdfbox::Cos::Stream.new
    stream[Pdfbox::Cos::Name.new("N")] = Pdfbox::Cos::Integer.new(2)
    stream[Pdfbox::Cos::Name.new("First")] = Pdfbox::Cos::Integer.new(8)

    output = stream.create_output_stream
    output << "6 0 4 5 true false"
    output.close

    parser = build_parser.call
    object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
    objects = object_stream_parser.parse_all_objects

    objects.size.should eq(2)
    objects[Pdfbox::Cos::ObjectKey.new(6, 0)]?.should eq(Pdfbox::Cos::Boolean::TRUE)
    objects[Pdfbox::Cos::ObjectKey.new(4, 0)]?.should eq(Pdfbox::Cos::Boolean::FALSE)
  end

  pending "parses indexed duplicate object numbers (PDFObjectStreamParserTest#testParseAllObjectsIndexed)" do
    # Blocked on parser/xref index-selection parity (Java test relies on COSDocument xref stream-index mapping).
  end

  pending "skips malformed index when object numbers are unique (PDFObjectStreamParserTest#testParseAllObjectsSkipMalformedIndex)" do
    # Blocked on parser/xref index-selection parity (Java test relies on COSDocument xref stream-index mapping).
  end

  pending "uses malformed index for duplicate object numbers (PDFObjectStreamParserTest#testParseAllObjectsUseMalformedIndex)" do
    # Blocked on parser/xref index-selection parity (Java test relies on COSDocument xref stream-index mapping).
  end
end

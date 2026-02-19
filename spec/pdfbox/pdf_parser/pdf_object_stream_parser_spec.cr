require "../../spec_helper"

describe Pdfbox::Pdfparser::PDFObjectStreamParser do
  build_parser = -> do
    source = Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)
    Pdfbox::Pdfparser::Parser.new(source)
  end

  build_parser_with_xref = ->(entries : Array(Pdfbox::Cos::ObjectKey)) do
    parser = build_parser.call
    xref = Pdfbox::Pdfparser::XRef.new
    entries.each { |key| xref[key] = -1_i64 }
    parser.xref = xref
    parser
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

  it "parses indexed duplicate object numbers (PDFObjectStreamParserTest#testParseAllObjectsIndexed)" do
    stream = Pdfbox::Cos::Stream.new
    stream[Pdfbox::Cos::Name.new("N")] = Pdfbox::Cos::Integer.new(3)
    stream[Pdfbox::Cos::Name.new("First")] = Pdfbox::Cos::Integer.new(13)

    output = stream.create_output_stream
    output << "6 0 4 5 4 11 true false true"
    output.close

    parser = build_parser_with_xref.call([
      Pdfbox::Cos::ObjectKey.new(6, 0, 0),
      Pdfbox::Cos::ObjectKey.new(4, 0, 2),
    ])

    object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
    objects = object_stream_parser.parse_all_objects
    objects.size.should eq(2)
    objects[Pdfbox::Cos::ObjectKey.new(6, 0)]?.should eq(Pdfbox::Cos::Boolean::TRUE)
    objects[Pdfbox::Cos::ObjectKey.new(4, 0)]?.should eq(Pdfbox::Cos::Boolean::TRUE)

    # Replace object 4 key to select the first duplicate object by stream index 1.
    parser = build_parser_with_xref.call([
      Pdfbox::Cos::ObjectKey.new(6, 0, 0),
      Pdfbox::Cos::ObjectKey.new(4, 0, 1),
    ])

    object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
    objects = object_stream_parser.parse_all_objects
    objects.size.should eq(2)
    objects[Pdfbox::Cos::ObjectKey.new(6, 0)]?.should eq(Pdfbox::Cos::Boolean::TRUE)
    objects[Pdfbox::Cos::ObjectKey.new(4, 0)]?.should eq(Pdfbox::Cos::Boolean::FALSE)
  end

  it "skips malformed index when object numbers are unique (PDFObjectStreamParserTest#testParseAllObjectsSkipMalformedIndex)" do
    stream = Pdfbox::Cos::Stream.new
    stream[Pdfbox::Cos::Name.new("N")] = Pdfbox::Cos::Integer.new(3)
    stream[Pdfbox::Cos::Name.new("First")] = Pdfbox::Cos::Integer.new(13)

    output = stream.create_output_stream
    output << "6 0 4 5 5 11 true false true"
    output.close

    parser = build_parser_with_xref.call([
      Pdfbox::Cos::ObjectKey.new(6, 0, 10),
      Pdfbox::Cos::ObjectKey.new(4, 0, 11),
      Pdfbox::Cos::ObjectKey.new(5, 0, 12),
    ])

    object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
    objects = object_stream_parser.parse_all_objects
    objects.size.should eq(3)
    objects[Pdfbox::Cos::ObjectKey.new(6, 0)]?.should eq(Pdfbox::Cos::Boolean::TRUE)
    objects[Pdfbox::Cos::ObjectKey.new(4, 0)]?.should eq(Pdfbox::Cos::Boolean::FALSE)
    objects[Pdfbox::Cos::ObjectKey.new(5, 0)]?.should eq(Pdfbox::Cos::Boolean::TRUE)
  end

  it "uses malformed index for duplicate object numbers (PDFObjectStreamParserTest#testParseAllObjectsUseMalformedIndex)" do
    stream = Pdfbox::Cos::Stream.new
    stream[Pdfbox::Cos::Name.new("N")] = Pdfbox::Cos::Integer.new(3)
    stream[Pdfbox::Cos::Name.new("First")] = Pdfbox::Cos::Integer.new(13)

    output = stream.create_output_stream
    output << "6 0 4 5 4 11 true false true"
    output.close

    parser = build_parser_with_xref.call([
      Pdfbox::Cos::ObjectKey.new(6, 0, 10),
      Pdfbox::Cos::ObjectKey.new(4, 0, 11),
    ])

    object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
    objects = object_stream_parser.parse_all_objects
    objects.size.should eq(0)
  end
end

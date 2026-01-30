require "../spec_helper"

describe Pdfbox::Pdfparser::PDFObjectStreamParser do
  describe "#read_object_numbers" do
    it "reads object numbers and offsets" do
      # Create a stream with N=2, First=8, data "4 0 6 5 true false"
      stream = Pdfbox::Cos::Stream.new
      stream[Pdfbox::Cos::Name.new("N")] = Pdfbox::Cos::Integer.new(2)
      stream[Pdfbox::Cos::Name.new("First")] = Pdfbox::Cos::Integer.new(8)
      stream.data = "4 0 6 5 true false".to_slice

      source = Pdfbox::IO::MemoryRandomAccessRead.new(Bytes.empty)
      parser = Pdfbox::Pdfparser::Parser.new(source)
      parser.lenient = true

      object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
      object_numbers = object_stream_parser.read_object_numbers
      object_numbers.size.should eq(2)
      object_numbers[4].should eq(0)
      object_numbers[6].should eq(5)
    end
  end

  describe "#parse_object" do
    it "parses object with given object number" do
      stream = Pdfbox::Cos::Stream.new
      stream[Pdfbox::Cos::Name.new("N")] = Pdfbox::Cos::Integer.new(2)
      stream[Pdfbox::Cos::Name.new("First")] = Pdfbox::Cos::Integer.new(8)
      stream.data = "4 0 6 5 true false".to_slice

      source = Pdfbox::IO::MemoryRandomAccessRead.new(Bytes.empty)
      parser = Pdfbox::Pdfparser::Parser.new(source)
      parser.lenient = true

      # Parse object 4 (should be true)
      object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
      obj = object_stream_parser.parse_object(4)
      obj.should be_a(Pdfbox::Cos::Boolean)
      obj.as(Pdfbox::Cos::Boolean).value.should be_true

      # Parse object 6 (should be false)
      object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
      obj = object_stream_parser.parse_object(6)
      obj.should be_a(Pdfbox::Cos::Boolean)
      obj.as(Pdfbox::Cos::Boolean).value.should be_false
    end
  end

  describe "#parse_all_objects" do
    it "parses all objects in stream" do
      stream = Pdfbox::Cos::Stream.new
      stream[Pdfbox::Cos::Name.new("N")] = Pdfbox::Cos::Integer.new(2)
      stream[Pdfbox::Cos::Name.new("First")] = Pdfbox::Cos::Integer.new(8)
      stream.data = "6 0 4 5 true false".to_slice

      source = Pdfbox::IO::MemoryRandomAccessRead.new(Bytes.empty)
      parser = Pdfbox::Pdfparser::Parser.new(source)
      parser.lenient = true

      object_stream_parser = Pdfbox::Pdfparser::PDFObjectStreamParser.new(stream, parser)
      all_objects = object_stream_parser.parse_all_objects
      all_objects.size.should eq(2)
      all_objects[Pdfbox::Cos::ObjectKey.new(6, 0)].should eq(Pdfbox::Cos::Boolean::TRUE)
      all_objects[Pdfbox::Cos::ObjectKey.new(4, 0)].should eq(Pdfbox::Cos::Boolean::FALSE)
    end
  end
end

require "../../spec_helper"
require "compress/zlib"

describe Pdfbox::Cos::Stream do
  it "encodes and decodes uncompressed streams" do
    input = "This is a test string to be used as input for TestCOSStream".to_slice
    stream = Pdfbox::Cos::Stream.new

    writer = stream.create_output_stream
    writer.write(input)
    writer.close

    String.new(stream.create_raw_input_stream.gets_to_end.to_slice).should eq(String.new(input))
    String.new(stream.create_input_stream.gets_to_end.to_slice).should eq(String.new(input))
  end

  it "encodes and decodes flate-compressed streams" do
    input = "This is a test string to be used as input for TestCOSStream".to_slice
    compressed = IO::Memory.new
    flate_writer = Compress::Zlib::Writer.new(compressed)
    flate_writer.write(input)
    flate_writer.close
    expected = compressed.to_slice
    stream = Pdfbox::Cos::Stream.new

    writer = stream.create_output_stream(Pdfbox::Cos::Name::FLATE_DECODE)
    writer.write(input)
    writer.close

    stream.data.should eq(expected)
    String.new(stream.create_input_stream.gets_to_end.to_slice).should eq(String.new(input))
  end

  it "decodes flate data written through raw output stream" do
    input = "This is a test string to be used as input for TestCOSStream".to_slice
    compressed = IO::Memory.new
    flate_writer = Compress::Zlib::Writer.new(compressed)
    flate_writer.write(input)
    flate_writer.close
    encoded = compressed.to_slice

    stream = Pdfbox::Cos::Stream.new
    raw = stream.create_raw_output_stream
    raw.write(encoded)
    raw.close
    stream.set_item(Pdfbox::Cos::Name::FILTER, Pdfbox::Cos::Name::FLATE_DECODE)

    String.new(stream.create_input_stream.gets_to_end.to_slice).should eq(String.new(input))
  end

  it "encodes and decodes streams with ASCII85 and Flate filters" do
    input = "This is a test string to be used as input for TestCOSStream".to_slice
    filters = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Name::ASCII85_DECODE,
      Pdfbox::Cos::Name::FLATE_DECODE,
    ])

    stream = Pdfbox::Cos::Stream.new
    writer = stream.create_output_stream(filters)
    writer.write(input)
    writer.close

    String.new(stream.create_input_stream.gets_to_end.to_slice).should eq(String.new(input))
  end

  it "applies array filters in the same order as PDFBox" do
    input = "This is a test string to be used as input for TestCOSStream".to_slice
    filters = Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Name::ASCII85_DECODE,
      Pdfbox::Cos::Name::FLATE_DECODE,
    ])

    flate_only = Pdfbox::Cos::Stream.new
    flate_out = flate_only.create_output_stream(Pdfbox::Cos::Name::FLATE_DECODE)
    flate_out.write(input)
    flate_out.close

    ascii85_only = Pdfbox::Cos::Stream.new
    ascii85_out = ascii85_only.create_output_stream(Pdfbox::Cos::Name::ASCII85_DECODE)
    ascii85_out.write(flate_only.data)
    ascii85_out.close

    combined = Pdfbox::Cos::Stream.new
    combined_out = combined.create_output_stream(filters)
    combined_out.write(input)
    combined_out.close

    combined.data.should eq(ascii85_only.data)
  end

  it "allows output streams to be closed multiple times" do
    input = "This is a test string to be used as input for TestCOSStream".to_slice
    compressed = IO::Memory.new
    flate_writer = Compress::Zlib::Writer.new(compressed)
    flate_writer.write(input)
    flate_writer.close
    expected = compressed.to_slice
    stream = Pdfbox::Cos::Stream.new

    output = stream.create_output_stream(Pdfbox::Cos::Name::FLATE_DECODE)
    output.write(input)
    output.close
    output.close

    stream.data.should eq(expected)
  end

  it "tracks whether stream data exists" do
    stream = Pdfbox::Cos::Stream.new
    stream.has_data?.should be_false
    expect_raises(IO::Error) { stream.create_input_stream }

    writer = stream.create_output_stream
    writer.write("This is a test string to be used as input for TestCOSStream".to_slice)
    writer.close

    stream.has_data?.should be_true
  end
end

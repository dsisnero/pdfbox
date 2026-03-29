require "../../../spec_helper"

describe Pdfbox::Pdmodel::Common::PDStream do
  it "PDStreamTest#testCreateInputStreamNullFilters" do
    data = Bytes[12, 34, 56, 78]
    doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
    input = IO::Memory.new(data)

    pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(doc, input, nil)
    pd_stream.filters.should be_empty

    stop_filters = ["DCTDecode", "DCT"]
    input_stream = pd_stream.create_input_stream(stop_filters)
    input_stream.read_byte.should eq(12)
    input_stream.read_byte.should eq(34)
    input_stream.read_byte.should eq(56)
    input_stream.read_byte.should eq(78)
    input_stream.read_byte.should be_nil
    doc.close
  end

  it "PDStreamTest#testCreateInputStreamEmptyFilters" do
    data = Bytes[12, 34, 56, 78]
    doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
    input = IO::Memory.new(data)

    empty_filters = Pdfbox::Cos::Array.new
    pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(doc, input, empty_filters)
    pd_stream.filters.size.should eq(0)

    stop_filters = ["DCTDecode", "DCT"]
    input_stream = pd_stream.create_input_stream(stop_filters)
    input_stream.read_byte.should eq(12)
    input_stream.read_byte.should eq(34)
    input_stream.read_byte.should eq(56)
    input_stream.read_byte.should eq(78)
    input_stream.read_byte.should be_nil
    doc.close
  end

  it "PDStreamTest#testCreateInputStreamNullStopFilters" do
    data = Bytes[12, 34, 56, 78]
    doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
    input = IO::Memory.new(data)

    empty_filters = Pdfbox::Cos::Array.new
    pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(doc, input, empty_filters)
    pd_stream.filters.size.should eq(0)

    input_stream = pd_stream.create_input_stream(nil)
    input_stream.read_byte.should eq(12)
    input_stream.read_byte.should eq(34)
    input_stream.read_byte.should eq(56)
    input_stream.read_byte.should eq(78)
    input_stream.read_byte.should be_nil
    doc.close
  end
end

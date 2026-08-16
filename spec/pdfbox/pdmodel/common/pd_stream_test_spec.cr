require "../../../spec_helper"
require "../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/common/PDStreamTest.java
private def read_all(io : ::IO) : Array(Int32)
  result = [] of Int32
  while (b = io.read_byte)
    result << b.to_i32
  end
  result
end

describe Pdfbox::Pdmodel::Common::PDStream do
  it "PDStreamTest#testCreateInputStreamNullFilters" do
    document = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
    begin
      data = ::IO::Memory.new(Bytes[12, 34, 56, 78])
      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(document, data, nil.as(Pdfbox::Cos::Base?))
      pd_stream.filters.should be_empty

      stop_filters = ["DCTDecode", "DCT"]
      is = pd_stream.create_input_stream(stop_filters)
      read_all(is).should eq([12, 34, 56, 78])
    ensure
      document.close
    end
  end

  it "PDStreamTest#testCreateInputStreamEmptyFilters" do
    document = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
    begin
      data = ::IO::Memory.new(Bytes[12, 34, 56, 78])
      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(document, data, Pdfbox::Cos::Array.new)
      pd_stream.filters.size.should eq(0)

      stop_filters = ["DCTDecode", "DCT"]
      is = pd_stream.create_input_stream(stop_filters)
      read_all(is).should eq([12, 34, 56, 78])
    ensure
      document.close
    end
  end

  it "PDStreamTest#testCreateInputStreamNullStopFilters" do
    document = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
    begin
      data = ::IO::Memory.new(Bytes[12, 34, 56, 78])
      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(document, data, Pdfbox::Cos::Array.new)
      pd_stream.filters.size.should eq(0)

      is = pd_stream.create_input_stream(nil.as(Array(String)?))
      read_all(is).should eq([12, 34, 56, 78])
    ensure
      document.close
    end
  end
end

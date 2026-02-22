require "../../../spec_helper"

describe Pdfbox::Pdmodel::Common::PDStream do
  # Test for null filter list (PDFBOX-2948)
  describe "#testCreateInputStreamNullFilters" do
    it "handles null filter list" do
      data = Bytes[12, 34, 56, 78]
      stream = Pdfbox::Cos::Stream.new
      stream.data = data

      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(stream)
      pd_stream.filters.should be_empty
    end
  end

  # Test for empty filter list
  describe "#testCreateInputStreamEmptyFilters" do
    it "handles empty filter list" do
      data = Bytes[12, 34, 56, 78]
      stream = Pdfbox::Cos::Stream.new
      stream.data = data
      stream[Pdfbox::Cos::Name::FILTER] = Pdfbox::Cos::Array.new

      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(stream)
      pd_stream.filters.size.should eq(0)
    end
  end

  # Test for null stop filters
  describe "#testCreateInputStreamNullStopFilters" do
    it "handles null stop filters" do
      data = Bytes[12, 34, 56, 78]
      stream = Pdfbox::Cos::Stream.new
      stream.data = data
      stream[Pdfbox::Cos::Name::FILTER] = Pdfbox::Cos::Array.new

      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(stream)
      pd_stream.filters.size.should eq(0)
    end
  end
end

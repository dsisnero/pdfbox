require "../../../spec_helper"

describe Pdfbox::Pdmodel::Common::PDStream do
  # Test for null filter list (PDFBOX-2948)
  # PDStreamTest#testCreateInputStreamNullFilters
  describe "#testCreateInputStreamNullFilters" do
    it "handles null filter list" do
      data = Bytes[12, 34, 56, 78]
      doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
      input = IO::Memory.new(data)

      # Create PDStream with null filters (third parameter nil)
      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(doc, input, nil)
      pd_stream.filters.should be_empty

      # Test reading back the data
      stop_filters = [] of String
      # Add DCTDecode and DCT as strings (matching Java test)
      stop_filters << "DCTDecode"
      stop_filters << "DCT"

      input_stream = pd_stream.create_input_stream(stop_filters)
      input_stream.read_byte.should eq(12)
      input_stream.read_byte.should eq(34)
      input_stream.read_byte.should eq(56)
      input_stream.read_byte.should eq(78)
      input_stream.read_byte.should be_nil # EOF
      doc.close
    end
  end

  # Test for empty filter list
  # PDStreamTest#testCreateInputStreamEmptyFilters
  describe "#testCreateInputStreamEmptyFilters" do
    it "handles empty filter list" do
      data = Bytes[12, 34, 56, 78]
      doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
      input = IO::Memory.new(data)

      # Create PDStream with empty filters array
      empty_filters = Pdfbox::Cos::Array.new
      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(doc, input, empty_filters)
      pd_stream.filters.size.should eq(0)

      # Test reading back the data
      stop_filters = [] of String
      stop_filters << "DCTDecode"
      stop_filters << "DCT"

      input_stream = pd_stream.create_input_stream(stop_filters)
      input_stream.read_byte.should eq(12)
      input_stream.read_byte.should eq(34)
      input_stream.read_byte.should eq(56)
      input_stream.read_byte.should eq(78)
      input_stream.read_byte.should be_nil # EOF
      doc.close
    end
  end

  # Test for null stop filters
  # PDStreamTest#testCreateInputStreamNullStopFilters
  describe "#testCreateInputStreamNullStopFilters" do
    it "handles null stop filters" do
      data = Bytes[12, 34, 56, 78]
      doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.empty)
      input = IO::Memory.new(data)

      # Create PDStream with empty filters array
      empty_filters = Pdfbox::Cos::Array.new
      pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(doc, input, empty_filters)
      pd_stream.filters.size.should eq(0)

      # Test reading back the data with null stop filters
      input_stream = pd_stream.create_input_stream(nil)
      input_stream.read_byte.should eq(12)
      input_stream.read_byte.should eq(34)
      input_stream.read_byte.should eq(56)
      input_stream.read_byte.should eq(78)
      input_stream.read_byte.should be_nil # EOF
      doc.close
    end
  end
end

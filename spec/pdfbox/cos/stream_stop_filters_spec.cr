require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/common/PDStream.java#createInputStream(List<String>)
#
# "This will get a stream with some filters applied but not others" — decoding
# stops before the first filter whose name is in stopFilters. Used e.g. to get
# the raw JPEG bytes of a Flate+DCT image.

private def zlib_encode(bytes : Bytes) : Bytes
  io = ::IO::Memory.new
  writer = Compress::Zlib::Writer.new(io)
  writer.write(bytes)
  writer.close
  io.to_slice
end

private def predictor_parms(colors : Int32, bpc : Int32, columns : Int32) : Pdfbox::Cos::Dictionary
  dict = Pdfbox::Cos::Dictionary.new
  dict.set_int(Pdfbox::Cos::Name.new("Predictor"), 15)
  dict.set_int(Pdfbox::Cos::Name.new("Colors"), colors)
  dict.set_int(Pdfbox::Cos::Name.new("BitsPerComponent"), bpc)
  dict.set_int(Pdfbox::Cos::Name.new("Columns"), columns)
  dict
end

private def filter_array(*names : String) : Pdfbox::Cos::Array
  array = Pdfbox::Cos::Array.new
  names.each { |name| array.add(Pdfbox::Cos::Name.new(name)) }
  array
end

describe "COSStream#create_input_stream(stop_filters)" do
  raw = Bytes[1_u8, 2_u8, 3_u8, 4_u8, 5_u8]
  flated = zlib_encode(raw)
  hex = Pdfbox::Filter::ASCIIHexFilter.new.encode(flated)

  it "decodes every filter when nothing is stopped" do
    stream = Pdfbox::Cos::Stream.new(data: hex)
    stream[Pdfbox::Cos::Name.new("Filter")] = filter_array("ASCIIHexDecode", "FlateDecode")

    stream.create_input_stream.gets_to_end.to_slice.should eq(raw)
  end

  it "stops before the first named filter" do
    stream = Pdfbox::Cos::Stream.new(data: hex)
    stream[Pdfbox::Cos::Name.new("Filter")] = filter_array("ASCIIHexDecode", "FlateDecode")

    stream.create_input_stream(["FlateDecode"]).gets_to_end.to_slice.should eq(flated)
  end

  it "returns the raw data when the first filter is stopped" do
    stream = Pdfbox::Cos::Stream.new(data: hex)
    stream[Pdfbox::Cos::Name.new("Filter")] = filter_array("ASCIIHexDecode", "FlateDecode")

    stream.create_input_stream(["ASCIIHexDecode"]).gets_to_end.to_slice.should eq(hex)
  end

  it "applies a predictor when not stopped and returns raw data when stopped" do
    predicted = Bytes[0_u8, 10_u8, 20_u8, 30_u8, 1_u8, 5_u8, 5_u8, 5_u8, 2_u8, 1_u8, 1_u8, 1_u8]
    expected = Bytes[10_u8, 20_u8, 30_u8, 5_u8, 10_u8, 15_u8, 6_u8, 11_u8, 16_u8]
    compressed = zlib_encode(predicted)

    stream = Pdfbox::Cos::Stream.new(data: compressed)
    stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("FlateDecode")
    stream[Pdfbox::Cos::Name.new("DecodeParms")] = predictor_parms(1, 8, 3)

    stream.create_input_stream.gets_to_end.to_slice.should eq(expected)
    # Stopping before FlateDecode leaves the raw, still-compressed data.
    stream.create_input_stream(["FlateDecode"]).gets_to_end.to_slice.should eq(compressed)
  end

  it "PDStream delegates the stop-filter decode" do
    stream = Pdfbox::Cos::Stream.new(data: hex)
    stream[Pdfbox::Cos::Name.new("Filter")] = filter_array("ASCIIHexDecode", "FlateDecode")
    pd_stream = Pdfbox::Pdmodel::Common::PDStream.new(stream)

    pd_stream.create_input_stream(["FlateDecode"]).gets_to_end.to_slice.should eq(flated)
  end

  it "PDImageXObject delegates the stop-filter decode" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("Filter")] = filter_array("ASCIIHexDecode", "FlateDecode")
      dict.set_int(Pdfbox::Cos::Name.new("Width"), 5)
      dict.set_int(Pdfbox::Cos::Name.new("Height"), 1)
      dict.set_int(Pdfbox::Cos::Name.new("BitsPerComponent"), 8)
      dict.set_name(Pdfbox::Cos::Name.new("ColorSpace"), "DeviceGray")
      stream = Pdfbox::Cos::Stream.new(dict.entries, hex)
      image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(doc, dict, stream)

      image.create_input_stream(["FlateDecode"]).gets_to_end.to_slice.should eq(flated)
    ensure
      doc.close
    end
  end
end

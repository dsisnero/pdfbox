require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/PDFXrefStreamParser.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSStream.java#createInputStream
#
# Xref streams are decoded through the parser's decode_stream_data. Java routes
# this through COSStream.createInputStream, which handles a filter *array* and
# DecodeParms (including predictors). The Crystal path previously raised on any
# filter array.
module ParserStreamDecodeSpec
  class ExposedParser < Pdfbox::Pdfparser::Parser
    def decode(stream : Pdfbox::Cos::Stream) : Bytes
      decode_stream_data(stream)
    end
  end

  def self.parser : ExposedParser
    ExposedParser.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.new(0)))
  end
end

private def zlib(bytes : Bytes) : Bytes
  io = ::IO::Memory.new
  writer = Compress::Zlib::Writer.new(io)
  writer.write(bytes)
  writer.close
  io.to_slice
end

private def predictor_decode_parms : Pdfbox::Cos::Dictionary
  dict = Pdfbox::Cos::Dictionary.new
  dict.set_int(Pdfbox::Cos::Name.new("Predictor"), 15)
  dict.set_int(Pdfbox::Cos::Name.new("Colors"), 1)
  dict.set_int(Pdfbox::Cos::Name.new("BitsPerComponent"), 8)
  dict.set_int(Pdfbox::Cos::Name.new("Columns"), 3)
  dict
end

describe "Parser#decode_stream_data" do
  predicted = Bytes[0_u8, 10_u8, 20_u8, 30_u8, 1_u8, 5_u8, 5_u8, 5_u8, 2_u8, 1_u8, 1_u8, 1_u8]
  raw = Bytes[10_u8, 20_u8, 30_u8, 5_u8, 10_u8, 15_u8, 6_u8, 11_u8, 16_u8]

  it "decodes a single FlateDecode filter with a predictor" do
    stream = Pdfbox::Cos::Stream.new(data: zlib(predicted))
    stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("FlateDecode")
    stream[Pdfbox::Cos::Name.new("DecodeParms")] = predictor_decode_parms

    ParserStreamDecodeSpec.parser.decode(stream).should eq(raw)
  end

  it "decodes a filter array ([/FlateDecode]) with a predictor" do
    filters = Pdfbox::Cos::Array.new
    filters.add(Pdfbox::Cos::Name.new("FlateDecode"))

    stream = Pdfbox::Cos::Stream.new(data: zlib(predicted))
    stream[Pdfbox::Cos::Name.new("Filter")] = filters
    stream[Pdfbox::Cos::Name.new("DecodeParms")] = predictor_decode_parms

    ParserStreamDecodeSpec.parser.decode(stream).should eq(raw)
  end

  it "decodes a stacked filter array ([/ASCIIHexDecode /FlateDecode])" do
    hex = Pdfbox::Filter::ASCIIHexFilter.new.encode(zlib(predicted))

    filters = Pdfbox::Cos::Array.new
    filters.add(Pdfbox::Cos::Name.new("ASCIIHexDecode"))
    filters.add(Pdfbox::Cos::Name.new("FlateDecode"))

    stream = Pdfbox::Cos::Stream.new(data: hex)
    stream[Pdfbox::Cos::Name.new("Filter")] = filters
    stream[Pdfbox::Cos::Name.new("DecodeParms")] = predictor_decode_parms

    ParserStreamDecodeSpec.parser.decode(stream).should eq(raw)
  end

  it "returns the raw data when there is no filter" do
    stream = Pdfbox::Cos::Stream.new(data: raw)
    ParserStreamDecodeSpec.parser.decode(stream).should eq(raw)
  end
end

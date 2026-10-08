require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/Predictor.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/filter/FlateFilter.java
#
# Java applies PNG/TIFF predictors in FlateFilter/LZWFilter decode via
# Predictor.wrapPredictor. These specs pin decodePredictorRow (all predictor
# modes) and the end-to-end Flate decode path.

private def predictor_params(predictor : Int32, colors : Int32, bpc : Int32, columns : Int32) : Pdfbox::Cos::Dictionary
  dict = Pdfbox::Cos::Dictionary.new
  dict.set_int(Pdfbox::Cos::Name.new("Predictor"), predictor)
  dict.set_int(Pdfbox::Cos::Name.new("Colors"), colors)
  dict.set_int(Pdfbox::Cos::Name.new("BitsPerComponent"), bpc)
  dict.set_int(Pdfbox::Cos::Name.new("Columns"), columns)
  dict
end

private def flate(bytes : Bytes) : Bytes
  io = ::IO::Memory.new
  writer = Compress::Zlib::Writer.new(io)
  writer.write(bytes)
  writer.close
  io.to_slice
end

describe Pdfbox::Filter::Predictor do
  it "returns the line unchanged for predictor 1" do
    line = Bytes[1_u8, 2_u8, 3_u8, 4_u8]
    last = Bytes.new(4)
    Pdfbox::Filter::Predictor.decode_predictor_row(1, 1, 8, 4, line, last)
    line.should eq(Bytes[1_u8, 2_u8, 3_u8, 4_u8])
  end

  it "decodes TIFF PRED SUB (predictor 2, 8 bpc)" do
    line = Bytes[10_u8, 5_u8, 5_u8, 5_u8]
    last = Bytes.new(4)
    Pdfbox::Filter::Predictor.decode_predictor_row(2, 1, 8, 4, line, last)
    line.should eq(Bytes[10_u8, 15_u8, 20_u8, 25_u8])
  end

  it "decodes PNG PRED SUB (predictor 11)" do
    line = Bytes[10_u8, 5_u8, 5_u8, 5_u8]
    last = Bytes.new(4)
    Pdfbox::Filter::Predictor.decode_predictor_row(11, 1, 8, 4, line, last)
    line.should eq(Bytes[10_u8, 15_u8, 20_u8, 25_u8])
  end

  it "decodes PNG PRED UP (predictor 12)" do
    line = Bytes[10_u8, 20_u8, 30_u8, 40_u8]
    last = Bytes[1_u8, 2_u8, 3_u8, 4_u8]
    Pdfbox::Filter::Predictor.decode_predictor_row(12, 1, 8, 4, line, last)
    line.should eq(Bytes[11_u8, 22_u8, 33_u8, 44_u8])
  end

  it "decodes PNG PRED AVG (predictor 13)" do
    line = Bytes[10_u8, 10_u8, 10_u8, 10_u8]
    last = Bytes.new(4)
    Pdfbox::Filter::Predictor.decode_predictor_row(13, 1, 8, 4, line, last)
    line.should eq(Bytes[10_u8, 15_u8, 17_u8, 18_u8])
  end

  it "decodes PNG PRED PAETH (predictor 14)" do
    line = Bytes[10_u8, 10_u8, 10_u8, 10_u8]
    last = Bytes.new(4)
    Pdfbox::Filter::Predictor.decode_predictor_row(14, 1, 8, 4, line, last)
    line.should eq(Bytes[10_u8, 20_u8, 30_u8, 40_u8])
  end

  it "decodes a per-row PNG predictor stream (predictor 15) through FlateFilter" do
    # rows: filter 0 / [10 20 30]; filter 1 (sub) / [5 5 5]; filter 2 (up) / [1 1 1]
    predicted = Bytes[0_u8, 10_u8, 20_u8, 30_u8,
      1_u8, 5_u8, 5_u8, 5_u8,
      2_u8, 1_u8, 1_u8, 1_u8]

    decoded = Pdfbox::Filter::FlateFilter.new.decode(flate(predicted), predictor_params(15, 1, 8, 3))
    decoded.should eq(Bytes[10_u8, 20_u8, 30_u8, 5_u8, 10_u8, 15_u8, 6_u8, 11_u8, 16_u8])
  end

  it "applies the predictor through Cos::Stream#create_input_stream" do
    predicted = Bytes[0_u8, 10_u8, 20_u8, 30_u8,
      1_u8, 5_u8, 5_u8, 5_u8,
      2_u8, 1_u8, 1_u8, 1_u8]

    stream = Pdfbox::Cos::Stream.new(data: flate(predicted))
    stream[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("FlateDecode")
    stream[Pdfbox::Cos::Name.new("DecodeParms")] = predictor_params(15, 1, 8, 3)

    stream.create_input_stream.gets_to_end.to_slice.should eq(
      Bytes[10_u8, 20_u8, 30_u8, 5_u8, 10_u8, 15_u8, 6_u8, 11_u8, 16_u8]
    )
  end
end

require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/common/PDStream.java
#     getDecodeParms (/DecodeParms, falling back to /DP), getFileDecodeParams
#     (/FDecodeParms), setDecodeParms, setFileDecodeParams and
#     internalGetDecodeParams (dict -> a one-element list; array -> list of maps).
private def pdstream_with(entry : Pdfbox::Cos::Name, value : Pdfbox::Cos::Base) : Pdfbox::Pdmodel::Common::PDStream
  stream = Pdfbox::Cos::Stream.new
  stream[entry] = value
  Pdfbox::Pdmodel::Common::PDStream.new(stream)
end

module Pdfbox::Pdmodel::Common
  describe PDStream do
    it "reads a single DecodeParms dictionary as a one-element list (Java getDecodeParms)" do
      dp = Pdfbox::Cos::Dictionary.new
      dp.set_int(Pdfbox::Cos::Name.new("Predictor"), 12)
      dp.set_int(Pdfbox::Cos::Name.new("Columns"), 4)

      parms = pdstream_with(Pdfbox::Cos::Name.new("DecodeParms"), dp).decode_parms
      parms.should_not be_nil
      parms.not_nil!.size.should eq(1)
      parms.not_nil![0]["Predictor"].should eq(12_i64)
      parms.not_nil![0]["Columns"].should eq(4_i64)
    end

    it "falls back to /DP when /DecodeParms is absent (Java getDecodeParms)" do
      dp = Pdfbox::Cos::Dictionary.new
      dp.set_int(Pdfbox::Cos::Name.new("Predictor"), 1)

      parms = pdstream_with(Pdfbox::Cos::Name.new("DP"), dp).decode_parms
      parms.should_not be_nil
      parms.not_nil![0]["Predictor"].should eq(1_i64)
    end

    it "reads an array of DecodeParms dictionaries (Java internalGetDecodeParams)" do
      first = Pdfbox::Cos::Dictionary.new
      first.set_int(Pdfbox::Cos::Name.new("Predictor"), 2)
      second = Pdfbox::Cos::Dictionary.new
      second.set_int(Pdfbox::Cos::Name.new("Predictor"), 15)
      array = Pdfbox::Cos::Array.new
      array.add(first)
      array.add(second)

      parms = pdstream_with(Pdfbox::Cos::Name.new("DecodeParms"), array).decode_parms
      parms.should_not be_nil
      parms.not_nil!.size.should eq(2)
      parms.not_nil![0]["Predictor"].should eq(2_i64)
      parms.not_nil![1]["Predictor"].should eq(15_i64)
    end

    it "returns nil when there is no DecodeParms (Java internalGetDecodeParams)" do
      PDStream.new(Pdfbox::Cos::Stream.new).decode_parms.should be_nil
    end

    it "round-trips decode params via the setter (Java setDecodeParms)" do
      pd = PDStream.new(Pdfbox::Cos::Stream.new)
      dp = Pdfbox::Cos::Dictionary.new
      dp.set_int(Pdfbox::Cos::Name.new("Predictor"), 12)
      map = COSDictionaryMap.convert_basic_types_to_map(dp).not_nil!

      pd.decode_parms = [map]
      parms = pd.decode_parms
      parms.should_not be_nil
      parms.not_nil![0]["Predictor"].should eq(12_i64)
    end
  end
end

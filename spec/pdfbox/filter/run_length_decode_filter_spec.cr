require "../../spec_helper"

describe Pdfbox::Filter::RunLengthDecodeFilter do
  it "roundtrips simple and corner cases from TestFilters#testRLE" do
    filter = Pdfbox::Filter::RunLengthDecodeFilter.new
    check_encode_decode = ->(original : Bytes) do
      encoded = filter.encode(original)
      decoded = filter.decode(encoded)
      decoded.should eq(original)
    end

    input0 = Bytes.empty
    check_encode_decode.call(input0)

    input1 = Bytes[1_u8, 2_u8, 3_u8, 4_u8, 5_u8, 128_u8, 140_u8, 180_u8, 255_u8]
    check_encode_decode.call(input1)

    input2 = Bytes.new(10, 0_u8)
    check_encode_decode.call(input2)

    input3 = Bytes.new(128, 0_u8)
    check_encode_decode.call(input3)

    input4 = Bytes.new(129, 0_u8)
    check_encode_decode.call(input4)

    input5 = Bytes.new(128 + 128, 0_u8)
    check_encode_decode.call(input5)

    input6 = Bytes.new(1, 0_u8)
    check_encode_decode.call(input6)

    input7 = Bytes[1_u8, 2_u8]
    check_encode_decode.call(input7)

    input8 = Bytes.new(2, 0_u8)
    check_encode_decode.call(input8)
  end
end

require "../../spec_helper"

describe Pdfbox::Filter::Predictor do
  it "get_bit_seq matches PredictorTest#getBitSeq vectors" do
    vectors = [
      {0b11111111, 0, 8, 0b11111111},
      {0b00000000, 0, 8, 0b00000000},
      {0b11111111, 0, 1, 0b1},
      {0b00000000, 0, 1, 0b0},
      {0b00110001, 0, 3, 0b001},
      {0b10101010, 0, 8, 0b10101010},
      {0b10101010, 0, 2, 0b10},
      {0b10101010, 1, 2, 0b01},
      {0b10101010, 2, 2, 0b10},
      {0b10101010, 3, 3, 0b101},
      {0b10101010, 1, 7, 0b1010101},
      {0b10101010, 3, 2, 0b01},
      {0b00110001, 0, 8, 0b00110001},
      {0b00110001, 0, 5, 0b10001},
      {0b00110001, 4, 4, 0b0011},
      {0b00110001, 3, 3, 0b110},
      {0b00110001, 6, 2, 0b00},
      {0b11110000, 4, 4, 0b1111},
      {0b11110000, 6, 2, 0b11},
      {0b11110000, 0, 4, 0b0000},
    ]

    vectors.each do |input, start_bit, bit_size, expected|
      Pdfbox::Filter::Predictor.get_bit_seq(input, start_bit, bit_size).should eq(expected)
    end
  end

  it "calc_set_bit_seq matches PredictorTest#calcSetBitSeq vectors" do
    vectors = [
      {0b11111111, 0, 8, 0, 0b00000000},
      {0b11111111, 0, 8, 1, 0b00000001},
      {0b11111111, 0, 1, 1, 0b11111111},
      {0b11111111, 0, 2, 1, 0b11111101},
      {0b11111111, 0, 3, 1, 0b11111001},
      {0b00000000, 0, 2, 1, 0b00000001},
      {0b11111111, 0, 4, 1, 0b11110001},
      {0b11111111, 1, 4, 1, 0b11100011},
      {0b00000000, 1, 1, 1, 0b00000010},
      {0b11111111, 7, 1, 1, 0b11111111},
      {0b11111111, 7, 1, 0, 0b01111111},
      {0b00000000, 7, 1, 1, 0b10000000},
      {0b00000000, 7, 1, 0, 0b00000000},
      {0b00000000, 6, 1, 1, 0b01000000},
      {0b00000000, 6, 1, 0, 0b00000000},
      {0b00000000, 3, 3, 6, 0b00110000},
      {0b00000000, 4, 3, 6, 0b01100000},
      {0b00000000, 5, 3, 6, 0b11000000},
      {0b00000000, 0, 8, 0xFF, 0b11111111},
      {0b11111111, 0, 8, 0xFF, 0b11111111},
      {0xA5, 0, 8, 0xD9 + 0xA5, 0x7E},
      {0b00000000, 1, 1, 3, 0b00000010},
    ]

    vectors.each do |input, start_bit, bit_size, value, expected|
      Pdfbox::Filter::Predictor.calc_set_bit_seq(input, start_bit, bit_size, value).should eq(expected)
    end
  end
end

require "../../spec_helper"

describe Pdfbox::IO::RandomAccessInputStream do
  it "matches RandomAccessInputStreamTest#testPositionSkip" do
    input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    stream = Pdfbox::IO::RandomAccessInputStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(IO::Memory.new(input_values)))

    stream.available.should eq(11)
    stream.skip(5).should eq(5)
    stream.read.should eq(5_u8)
    stream.available.should eq(5)
    stream.skip(-10).should eq(0)
  end

  it "matches RandomAccessInputStreamTest#testPositionRead" do
    input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    stream = Pdfbox::IO::RandomAccessInputStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(IO::Memory.new(input_values)))

    stream.available.should eq(11)
    stream.read.should eq(0_u8)
    stream.read.should eq(1_u8)
    stream.read.should eq(2_u8)
    stream.available.should eq(8)
  end

  it "matches RandomAccessInputStreamTest#testSeekEOF" do
    input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    stream = Pdfbox::IO::RandomAccessInputStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(IO::Memory.new(input_values)))

    stream.skip(input_values.size + 1).should eq(12)
    stream.available.should eq(0)
    stream.read.should be_nil

    buffer = Bytes.new(1)
    stream.read(buffer, 0, 1).should eq(-1)
  end

  it "matches RandomAccessInputStreamTest#testPositionReadBytes" do
    input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    stream = Pdfbox::IO::RandomAccessInputStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(IO::Memory.new(input_values)))

    stream.available.should eq(11)

    buffer = Bytes.new(4)
    stream.read(buffer).should eq(4)
    buffer[0].should eq(0_u8)
    buffer[3].should eq(3_u8)
    stream.available.should eq(7)

    stream.read(buffer, 1, 2).should eq(2)
    buffer[0].should eq(0_u8)
    buffer[1].should eq(4_u8)
    buffer[2].should eq(5_u8)
    buffer[3].should eq(3_u8)
    stream.available.should eq(5)
  end

  it "matches RandomAccessInputStreamTest#testEmptyBuffer" do
    stream = Pdfbox::IO::RandomAccessInputStream.new(Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty))

    stream.read.should be_nil
    buffer = Bytes.new(6)
    stream.read(buffer).should eq(-1)
    stream.available.should eq(0)
  end
end

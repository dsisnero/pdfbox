require "../../spec_helper"

describe Pdfbox::IO::RandomAccessReadWriteBuffer do
  it "matches RandomAccessReadWriteBufferTest#testClose" do
    buffer = Pdfbox::IO::RandomAccessReadWriteBuffer.new
    buffer.write(Bytes[1, 2, 3, 4])
    buffer.closed?.should be_false
    buffer.close
    buffer.closed?.should be_true
  end

  it "matches RandomAccessReadWriteBufferTest#testClear" do
    buffer = Pdfbox::IO::RandomAccessReadWriteBuffer.new(4)
    buffer.write(Bytes[1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    buffer.length.should eq(10)
    buffer.position.should eq(10)
    buffer.clear
    buffer.closed?.should be_false
    buffer.length.should eq(0)
    buffer.position.should eq(0)
    buffer.close
  end

  it "matches RandomAccessReadWriteBufferTest#testLengthWriteByte and #testLengthWriteBytes" do
    buffer = Pdfbox::IO::RandomAccessReadWriteBuffer.new
    buffer.length.should eq(0)
    buffer.write(1)
    buffer.write(2)
    buffer.write(3)
    buffer.length.should eq(3)

    buffer.write(Bytes[4, 5, 6, 7])
    buffer.length.should eq(7)

    buffer.write(Bytes[8, 9, 10, 11])
    buffer.length.should eq(11)
    buffer.close
  end

  it "matches RandomAccessReadWriteBufferTest#testRandomAccessRead" do
    buffer = Pdfbox::IO::RandomAccessReadWriteBuffer.new
    input = Bytes[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    buffer.write(input)
    buffer.length.should eq(11)

    buffer.seek(0)
    bytes_read = Bytes.new(11)
    buffer.read(bytes_read).should eq(11)
    bytes_read.should eq(input)

    buffer.close
  end

  it "matches RandomAccessReadWriteBufferTest#testBufferSeek #testBufferEOF #testAlreadyClose" do
    buffer = Pdfbox::IO::RandomAccessReadWriteBuffer.new
    bytes = Bytes.new(4096)
    buffer.write(bytes)

    expect_raises(Exception) { buffer.seek(-1) }

    buffer.seek(0)
    buffer.eof?.should be_false
    buffer.seek(4096)
    buffer.eof?.should be_true

    buffer.close
    expect_raises(Exception) { buffer.seek(0) }
  end
end

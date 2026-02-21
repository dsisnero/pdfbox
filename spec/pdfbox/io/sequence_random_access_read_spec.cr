require "../../spec_helper"

private def build_sequence
  input1 = "01234567890123456789"
  input2 = "abcdefghijklmnopqrst"
  r1 = Pdfbox::IO::RandomAccessReadBuffer.new(input1.to_slice)
  r2 = Pdfbox::IO::RandomAccessReadBuffer.new(input2.to_slice)
  {input1, input2, Pdfbox::IO::SequenceRandomAccessRead.new([r1, r2] of Pdfbox::IO::RandomAccessRead)}
end

describe Pdfbox::IO::SequenceRandomAccessRead do
  it "matches SequenceRandomAccessReadTest#TestCreateAndRead" do
    input1 = "This is a test string number 1"
    input2 = "This is a test string number 2"
    r1 = Pdfbox::IO::RandomAccessReadBuffer.new(input1.to_slice)
    r2 = Pdfbox::IO::RandomAccessReadBuffer.new(input2.to_slice)

    sequence = Pdfbox::IO::SequenceRandomAccessRead.new([r1, r2] of Pdfbox::IO::RandomAccessRead)

    expect_raises(IO::Error) { sequence.create_view(0, 10) }
    sequence.length.should eq(input1.size + input2.size)

    bytes = Bytes.new(input1.size + input2.size)
    sequence.read(bytes).should eq(bytes.size)
    String.new(bytes).should eq(input1 + input2)

    sequence.close

    expect_raises(ArgumentError) { Pdfbox::IO::SequenceRandomAccessRead.new([] of Pdfbox::IO::RandomAccessRead) }
    expect_raises(ArgumentError) { Pdfbox::IO::SequenceRandomAccessRead.new([r1, r2] of Pdfbox::IO::RandomAccessRead) }
  end

  it "matches SequenceRandomAccessReadTest#TestSeekPeekAndRewind and #TestBorderCases" do
    _input1, _input2, sequence = build_sequence

    sequence.seek(4)
    sequence.position.should eq(4)
    sequence.read.should eq('4'.ord.to_u8)
    sequence.position.should eq(5)
    sequence.rewind(1)
    sequence.position.should eq(4)
    sequence.read.should eq('4'.ord.to_u8)
    sequence.peek.should eq('5'.ord.to_u8)
    sequence.position.should eq(5)

    sequence.seek(24)
    sequence.read.should eq('e'.ord.to_u8)
    sequence.rewind(1)
    sequence.read.should eq('e'.ord.to_u8)
    sequence.peek.should eq('f'.ord.to_u8)
    sequence.read.should eq('f'.ord.to_u8)
    expect_raises(Exception) { sequence.seek(-1) }

    sequence.seek(19)
    sequence.read.should eq('9'.ord.to_u8)
    sequence.rewind(1)
    sequence.read.should eq('9'.ord.to_u8)
    sequence.peek.should eq('a'.ord.to_u8)
    sequence.read.should eq('a'.ord.to_u8)

    sequence.seek(17)
    bytes = Bytes.new(6)
    sequence.read(bytes).should eq(6)
    String.new(bytes).should eq("789abc")

    sequence.rewind(6)
    bytes = Bytes.new(6)
    sequence.read(bytes).should eq(6)
    String.new(bytes).should eq("789abc")
  end

  it "matches SequenceRandomAccessReadTest#TestEOF and #TestEmptyStream" do
    input1, input2, sequence = build_sequence
    overall_length = input1.size + input2.size

    sequence.seek(overall_length - 1)
    sequence.eof?.should be_false
    sequence.peek.should eq('t'.ord.to_u8)
    sequence.read.should eq('t'.ord.to_u8)
    sequence.eof?.should be_true
    sequence.read.should be_nil

    bytes = Bytes.new(1)
    sequence.read(bytes).should eq(0)

    sequence.rewind(5)
    sequence.eof?.should be_false
    tail = Bytes.new(5)
    sequence.read(tail).should eq(5)
    String.new(tail).should eq("pqrst")
    sequence.eof?.should be_true

    sequence.seek(overall_length + 10)
    sequence.eof?.should be_true
    sequence.position.should eq(overall_length)

    sequence.closed?.should be_false
    sequence.close
    sequence.closed?.should be_true

    expect_raises(IO::Error) { sequence.read }

    empty_buffer = Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)
    seq_with_empty = Pdfbox::IO::SequenceRandomAccessRead.new([
      Pdfbox::IO::RandomAccessReadBuffer.new(input1.to_slice),
      empty_buffer,
      Pdfbox::IO::RandomAccessReadBuffer.new(input2.to_slice),
    ] of Pdfbox::IO::RandomAccessRead)

    seq_with_empty.length.should eq(overall_length)
    seq_with_empty.seek(15)
    bytes = Bytes.new(10)
    seq_with_empty.read(bytes).should eq(10)
    String.new(bytes).should eq("56789abcde")
  end
end

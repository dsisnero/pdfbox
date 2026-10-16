require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/COSStandardOutputStream.java
# Upstream has no dedicated test; this is a characterization spec.
describe Pdfbox::Pdfwriter::COSStandardOutputStream do
  it "tracks the number of bytes written" do
    io = ::IO::Memory.new
    stream = Pdfbox::Pdfwriter::COSStandardOutputStream.new(io)

    stream.position.should eq(0)
    stream.write(Bytes[1, 2, 3])
    stream.position.should eq(3)
    stream.write_byte(4_u8)
    stream.position.should eq(4)
    io.to_slice.should eq(Bytes[1, 2, 3, 4])
  end

  it "honours an initial position" do
    io = ::IO::Memory.new
    stream = Pdfbox::Pdfwriter::COSStandardOutputStream.new(io, 100_i64)

    stream.position.should eq(100)
    stream.write_byte(1_u8)
    stream.position.should eq(101)
  end

  it "exposes the line-separator constants" do
    Pdfbox::Pdfwriter::COSStandardOutputStream::CRLF.should eq(Bytes[0x0D, 0x0A])
    Pdfbox::Pdfwriter::COSStandardOutputStream::LF.should eq(Bytes[0x0A])
    Pdfbox::Pdfwriter::COSStandardOutputStream::EOL.should eq(Bytes[0x0A])
  end

  it "writes CRLF and LF" do
    crlf_io = ::IO::Memory.new
    Pdfbox::Pdfwriter::COSStandardOutputStream.new(crlf_io).write_crlf
    crlf_io.to_slice.should eq(Bytes[0x0D, 0x0A])

    lf_io = ::IO::Memory.new
    Pdfbox::Pdfwriter::COSStandardOutputStream.new(lf_io).write_lf
    lf_io.to_slice.should eq(Bytes[0x0A])
  end

  it "avoids writing two newlines in sequence" do
    io = ::IO::Memory.new
    stream = Pdfbox::Pdfwriter::COSStandardOutputStream.new(io)

    stream.write_eol
    stream.write_eol
    io.to_slice.should eq(Bytes[0x0A])
    stream.on_new_line?.should be_true

    stream.write(Bytes[0x41])
    stream.on_new_line?.should be_false
    stream.write_eol
    io.to_slice.should eq(Bytes[0x0A, 0x41, 0x0A])
  end

  it "writes a slice range" do
    io = ::IO::Memory.new
    stream = Pdfbox::Pdfwriter::COSStandardOutputStream.new(io)

    stream.write(Bytes[9, 1, 2, 3, 9], 1, 3)
    io.to_slice.should eq(Bytes[1, 2, 3])
    stream.position.should eq(3)
  end
end

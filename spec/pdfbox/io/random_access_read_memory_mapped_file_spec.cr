require "../../spec_helper"

MM_RESOURCE_DIR    = File.join(__DIR__, "..", "..", "resources", "pdfbox", "io")
MM_FILE1_PATH      = File.join(MM_RESOURCE_DIR, "RandomAccessReadFile1.txt")
MM_EMPTY_FILE_PATH = File.join(MM_RESOURCE_DIR, "RandomAccessReadEmptyFile.txt")

describe Pdfbox::IO::RandomAccessReadMemoryMappedFile do
  it "matches RandomAccessReadMemoryMappedFileTest#testPositionSkip" do
    source = Pdfbox::IO::RandomAccessReadMemoryMappedFile.new(MM_FILE1_PATH)
    source.position.should eq(0)
    source.skip(5)
    source.read.should eq('5'.ord.to_u8)
    source.position.should eq(6)
    source.close
  end

  it "matches RandomAccessReadMemoryMappedFileTest#testPathConstructor" do
    source = Pdfbox::IO::RandomAccessReadMemoryMappedFile.new(Path.new(MM_FILE1_PATH))
    source.length.should eq(130)
    source.close
  end

  it "matches RandomAccessReadMemoryMappedFileTest#testSeekEOF" do
    source = Pdfbox::IO::RandomAccessReadMemoryMappedFile.new(MM_FILE1_PATH)

    source.seek(3)
    source.position.should eq(3)
    expect_raises(Exception) { source.seek(-1) }

    source.eof?.should be_false
    source.seek(source.length)
    source.eof?.should be_true
    source.read.should be_nil

    buffer = Bytes.new(1)
    source.read(buffer).should eq(0)

    source.close
    expect_raises(Exception) { source.read }
  end

  it "matches RandomAccessReadMemoryMappedFileTest#testView" do
    source = Pdfbox::IO::RandomAccessReadMemoryMappedFile.new(MM_FILE1_PATH)
    view = source.create_view(3, 10)

    view.position.should eq(0)
    view.read.should eq('3'.ord.to_u8)
    view.read.should eq('4'.ord.to_u8)
    view.read.should eq('5'.ord.to_u8)
    view.position.should eq(3)

    view.close
    source.close
  end

  it "matches RandomAccessReadMemoryMappedFileTest#testEmptyBuffer" do
    source = Pdfbox::IO::RandomAccessReadMemoryMappedFile.new(MM_EMPTY_FILE_PATH)

    source.read.should be_nil
    source.peek.should be_nil

    bytes = Bytes.new(6)
    source.read(bytes).should eq(0)

    source.seek(0)
    source.position.should eq(0)
    source.seek(6)
    source.position.should eq(0)
    source.eof?.should be_true
    expect_raises(Exception) { source.rewind(3) }

    source.close
  end
end

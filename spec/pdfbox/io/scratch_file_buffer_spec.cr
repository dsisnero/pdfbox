require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/io/src/test/java/org/apache/pdfbox/io/ScratchFileBufferTest.java
PAGE_SIZE      = 4096
NUM_ITERATIONS =    3

describe Pdfbox::IO::ScratchFileBuffer do
  it "matches ScratchFileBufferTest#testEOFBugInSeek" do
    scratch_file = Pdfbox::IO::ScratchFile.new(Pdfbox::IO::MemoryUsageSetting.setup_main_memory_only)
    begin
      buffer = scratch_file.create_buffer
      bytes = Bytes.new(PAGE_SIZE)
      NUM_ITERATIONS.times do |i|
        p0 = buffer.position
        buffer.write(bytes)
        p1 = buffer.position
        (p1 - p0).should eq(PAGE_SIZE)
        buffer.write(bytes)
        p2 = buffer.position
        (p2 - p1).should eq(PAGE_SIZE)
        buffer.seek(0)
        buffer.seek(i * 2 * PAGE_SIZE)
      end
    ensure
      scratch_file.close
    end
  end

  it "matches ScratchFileBufferTest#testBufferLength" do
    scratch_file = Pdfbox::IO::ScratchFile.new(Pdfbox::IO::MemoryUsageSetting.setup_main_memory_only)
    begin
      bytes = Bytes.new(PAGE_SIZE)
      buffer = scratch_file.create_buffer
      buffer.write(bytes)
      buffer.length.should eq(PAGE_SIZE)
    ensure
      scratch_file.close
    end
  end

  it "matches ScratchFileBufferTest#testBufferSeek" do
    scratch_file = Pdfbox::IO::ScratchFile.new(Pdfbox::IO::MemoryUsageSetting.setup_main_memory_only)
    begin
      bytes = Bytes.new(PAGE_SIZE)
      buffer = scratch_file.create_buffer
      buffer.write(bytes)
      expect_raises(::IO::Error) { buffer.seek(-1) }
      expect_raises(::IO::EOFError) { buffer.seek(PAGE_SIZE + 1) }
    ensure
      scratch_file.close
    end
  end

  it "matches ScratchFileBufferTest#testBufferEOF" do
    scratch_file = Pdfbox::IO::ScratchFile.new(Pdfbox::IO::MemoryUsageSetting.setup_main_memory_only)
    begin
      bytes = Bytes.new(PAGE_SIZE)
      buffer = scratch_file.create_buffer
      buffer.write(bytes)
      buffer.seek(0)
      buffer.eof?.should be_false
      buffer.seek(PAGE_SIZE)
      buffer.eof?.should be_true
    ensure
      scratch_file.close
    end
  end

  it "matches ScratchFileBufferTest#testAlreadyClose" do
    scratch_file = Pdfbox::IO::ScratchFile.new(Pdfbox::IO::MemoryUsageSetting.setup_main_memory_only)
    begin
      bytes = Bytes.new(PAGE_SIZE)
      buffer = scratch_file.create_buffer
      buffer.write(bytes)
      buffer.close
      expect_raises(::IO::Error) { buffer.seek(0) }
    ensure
      scratch_file.close
    end
  end

  it "matches ScratchFileBufferTest#testBuffersClosed" do
    scratch_file = Pdfbox::IO::ScratchFile.new(Pdfbox::IO::MemoryUsageSetting.setup_main_memory_only)
    begin
      bytes = Bytes.new(PAGE_SIZE)
      buffer1 = scratch_file.create_buffer
      buffer1.write(bytes)
      buffer2 = scratch_file.create_buffer
      buffer2.write(bytes)
      buffer3 = scratch_file.create_buffer
      buffer3.write(bytes)
      buffer4 = scratch_file.create_buffer
      buffer4.write(bytes)
      buffer1.close
      buffer3.close
      buffer1.closed?.should be_true
      buffer2.closed?.should be_false
      buffer3.closed?.should be_true
      buffer4.closed?.should be_false
      scratch_file.close
      buffer2.closed?.should be_true
      buffer4.closed?.should be_true
    ensure
      scratch_file.close
    end
  end

  it "matches ScratchFileBufferTest#testView" do
    scratch_file = Pdfbox::IO::ScratchFile.new(Pdfbox::IO::MemoryUsageSetting.setup_main_memory_only)
    begin
      buffer = scratch_file.create_buffer
      buffer.write(Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
      expect_raises(Pdfbox::Cos::UnsupportedOperationError) { buffer.create_view(0, 10) }
    ensure
      scratch_file.close
    end
  end
end

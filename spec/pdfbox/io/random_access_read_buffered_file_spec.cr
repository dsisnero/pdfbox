require "../../spec_helper"

RESOURCE_DIR    = File.join(__DIR__, "..", "..", "resources", "pdfbox", "io")
FILE1_PATH      = File.join(RESOURCE_DIR, "RandomAccessReadFile1.txt")
EMPTY_FILE_PATH = File.join(RESOURCE_DIR, "RandomAccessReadEmptyFile.txt")

describe Pdfbox::IO::RandomAccessReadBufferedFile do
  describe "#position and #skip" do
    it "testPositionSkip" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        random_access_source.position.should eq(0)
        random_access_source.skip(5)
        random_access_source.read.should eq('0'.ord.to_u8 + 5) # '5' is ASCII 53
        random_access_source.position.should eq(6)
      ensure
        random_access_source.close
      end
    end
  end

  describe "#position and #read" do
    it "testPositionRead" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      random_access_source.position.should eq(0)
      random_access_source.read.should eq('0'.ord.to_u8)
      random_access_source.read.should eq('1'.ord.to_u8)
      random_access_source.read.should eq('2'.ord.to_u8)
      random_access_source.position.should eq(3)

      random_access_source.closed?.should be_false
      random_access_source.close
      random_access_source.closed?.should be_true
    end
  end

  describe "#seek" do
    it "testSeekEOF" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        random_access_source.seek(3)
        random_access_source.position.should eq(3)

        expect_raises(Exception) do
          random_access_source.seek(-1)
        end

        random_access_source.eof?.should be_false
        random_access_source.seek(random_access_source.length)
        random_access_source.eof?.should be_true
        random_access_source.read.should be_nil
        buffer = Bytes.new(1)
        random_access_source.read(buffer).should eq(0)

        random_access_source.close
        expect_raises(Exception) do
          random_access_source.read
        end
      ensure
        random_access_source.close
      end
    end
  end

  describe "#position and #read with buffer" do
    it "testPositionReadBytes" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        random_access_source.position.should eq(0)
        buffer = Bytes.new(4)
        random_access_source.read(buffer).should eq(4)
        buffer[0].should eq('0'.ord.to_u8)
        buffer[3].should eq('3'.ord.to_u8)
        random_access_source.position.should eq(4)

        random_access_source.read(buffer, 1, 2).should eq(2)
        buffer[0].should eq('0'.ord.to_u8)
        buffer[1].should eq('4'.ord.to_u8)
        buffer[2].should eq('5'.ord.to_u8)
        buffer[3].should eq('3'.ord.to_u8)
        random_access_source.position.should eq(6)
      ensure
        random_access_source.close
      end
    end
  end

  describe "#position and #peek" do
    it "testPositionPeek" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        random_access_source.position.should eq(0)
        random_access_source.skip(6)
        random_access_source.position.should eq(6)

        random_access_source.peek.should eq('6'.ord.to_u8)
        random_access_source.position.should eq(6)
      ensure
        random_access_source.close
      end
    end
  end

  describe "#position and #rewind" do
    it "testPositionUnreadBytes" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        random_access_source.position.should eq(0)
        random_access_source.read
        random_access_source.read
        read_bytes = Bytes.new(6)
        random_access_source.read(read_bytes).should eq(6)
        random_access_source.position.should eq(8)
        random_access_source.rewind(6)
        random_access_source.position.should eq(2)
        random_access_source.read.should eq('2'.ord.to_u8)
        random_access_source.position.should eq(3)
        random_access_source.read(read_bytes, 2, 4).should eq(4)
        random_access_source.position.should eq(7)
        random_access_source.rewind(4)
        random_access_source.position.should eq(3)
      ensure
        random_access_source.close
      end
    end
  end

  describe "empty buffer" do
    it "testEmptyBuffer" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(EMPTY_FILE_PATH)
      begin
        random_access_source.read.should be_nil
        random_access_source.peek.should be_nil
        read_bytes = Bytes.new(6)
        random_access_source.read(read_bytes).should eq(0)
        random_access_source.seek(0)
        random_access_source.position.should eq(0)
        random_access_source.seek(6)
        random_access_source.position.should eq(0)
        random_access_source.eof?.should be_true
        expect_raises(Exception) do
          random_access_source.rewind(3)
        end
      ensure
        random_access_source.close
      end
    end
  end

  describe "#create_view" do
    it "testView" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      view = random_access_source.create_view(3, 10)
      begin
        view.position.should eq(0)
        view.read.should eq('3'.ord.to_u8)
        view.read.should eq('4'.ord.to_u8)
        view.read.should eq('5'.ord.to_u8)
        view.position.should eq(3)
      ensure
        view.close
        random_access_source.close
      end
    end
  end

  describe "#read_fully" do
    it "testReadFully1" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        buffer = Bytes.new(10)
        random_access_source.seek(1)
        random_access_source.read_fully(buffer)
        String.new(buffer).should eq("1234567890")
      ensure
        random_access_source.close
      end
    end

    it "testReadFully2" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        buffer = Bytes.new(10)
        random_access_source.read_fully(buffer, 2, 8)
        String.new(buffer[2, 8]).should eq("01234567")
        buffer[0].should eq(0)
        buffer[1].should eq(0)
      ensure
        random_access_source.close
      end
    end

    it "testReadFully3" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        buffer = Bytes.new(10)
        random_access_source.seek(random_access_source.length - buffer.size)
        random_access_source.read_fully(buffer)
        String.new(buffer).should eq("0123456789")
      ensure
        random_access_source.close
      end
    end

    it "testReadFullyEOF" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        buffer = Bytes.new(10)
        random_access_source.seek(random_access_source.length - buffer.size + 1)
        expect_raises(IO::EOFError) do
          random_access_source.read_fully(buffer)
        end
      ensure
        random_access_source.close
      end
    end

    it "testReadFullyExact" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        length = random_access_source.length.to_i32
        buffer = Bytes.new(length)
        random_access_source.read_fully(buffer)
        # Compare with file content
        file_content = File.read(FILE1_PATH)
        String.new(buffer).should eq(file_content)
      ensure
        random_access_source.close
      end
    end

    it "testReadFullyNothing" do
      random_access_source = Pdfbox::IO::RandomAccessReadBufferedFile.new(FILE1_PATH)
      begin
        random_access_source.position.should eq(0)
        buffer = Bytes.new(0)
        random_access_source.read_fully(buffer)
        random_access_source.position.should eq(0)
      ensure
        random_access_source.close
      end
    end
  end

  # testReadFullyAcrossBuffers requires a larger file; skip for now
  # testPathConstructor requires Path; skip for now
end

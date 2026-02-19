require "../../spec_helper"

describe Pdfbox::IO::RandomAccessReadBuffer do
  describe "#position and #skip" do
    it "testPositionSkip" do
      input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      bais = IO::Memory.new(input_values)
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(bais)
      begin
        random_access_source.position.should eq(0)
        random_access_source.skip(5)
        random_access_source.read.should eq(5_u8)
        random_access_source.position.should eq(6)
      ensure
        random_access_source.close
      end
    end
  end

  describe "#position and #read" do
    it "testPositionRead" do
      input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      bais = IO::Memory.new(input_values)
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(bais)
      random_access_source.position.should eq(0)
      random_access_source.read.should eq(0_u8)
      random_access_source.read.should eq(1_u8)
      random_access_source.read.should eq(2_u8)
      random_access_source.position.should eq(3)

      random_access_source.closed?.should be_false
      random_access_source.close
      random_access_source.closed?.should be_true
    end
  end

  describe "#seek" do
    it "testSeekEOF" do
      input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      bais = IO::Memory.new(input_values)
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(bais)
      begin
        random_access_source.seek(3)
        random_access_source.position.should eq(3)

        expect_raises(Exception) do
          random_access_source.seek(-1)
        end

        random_access_source.eof?.should be_false
        random_access_source.seek(20)
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
      input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      bais = IO::Memory.new(input_values)
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(bais)
      begin
        random_access_source.position.should eq(0)
        buffer = Bytes.new(4)
        random_access_source.read(buffer).should eq(4)
        buffer[0].should eq(0_u8)
        buffer[3].should eq(3_u8)
        random_access_source.position.should eq(4)

        random_access_source.read(buffer, 1, 2).should eq(2)
        buffer[0].should eq(0_u8)
        buffer[1].should eq(4_u8)
        buffer[2].should eq(5_u8)
        buffer[3].should eq(3_u8)
        random_access_source.position.should eq(6)
      ensure
        random_access_source.close
      end
    end
  end

  describe "#position and #peek" do
    it "testPositionPeek" do
      input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      bais = IO::Memory.new(input_values)
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(bais)
      begin
        random_access_source.position.should eq(0)
        random_access_source.skip(6)
        random_access_source.position.should eq(6)

        random_access_source.peek.should eq(6_u8)
        random_access_source.position.should eq(6)
      ensure
        random_access_source.close
      end
    end
  end

  describe "#position and #rewind" do
    it "testPositionUnreadBytes" do
      input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      bais = IO::Memory.new(input_values)
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(bais)
      begin
        random_access_source.position.should eq(0)
        random_access_source.read
        random_access_source.read
        read_bytes = Bytes.new(6)
        random_access_source.read(read_bytes).should eq(6)
        random_access_source.position.should eq(8)
        random_access_source.rewind(6)
        random_access_source.position.should eq(2)
        random_access_source.read.should eq(2_u8)
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
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(Bytes.empty)
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
      input_values = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      bais = IO::Memory.new(input_values)
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(bais)
      view = random_access_source.create_view(3, 5)
      begin
        view.position.should eq(0)
        view.read.should eq(3_u8)
        view.read.should eq(4_u8)
        view.read.should eq(5_u8)
        view.position.should eq(3)
      ensure
        view.close
        random_access_source.close
      end
    end
  end

  # testPDFBOX5111 requires network, skip for now
  # testPDFBOX5158 requires temp file, we'll implement later
  # testPDFBOX5161
  describe "PDFBOX-5161" do
    it "testPDFBOX5161" do
      random_access_source = Pdfbox::IO::RandomAccessReadBuffer.new(IO::Memory.new(Bytes.new(4099)))
      begin
        buffer = Bytes.new(4096)
        bytes_read = random_access_source.read(buffer)
        bytes_read.should eq(4096)
        bytes_read = random_access_source.read(buffer, 0, 3)
        bytes_read.should eq(3)
      ensure
        random_access_source.close
      end
    end
  end

  # testPDFBOX5764 requires ByteBuffer, not yet implemented
end

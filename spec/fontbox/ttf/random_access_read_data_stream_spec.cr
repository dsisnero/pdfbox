require "../../spec_helper"

module Fontbox::TTF
  describe RandomAccessReadDataStream do
    it "test_eof" do
      byte_array = Bytes.new(10)
      random_access_read_buffer = Pdfbox::IO::RandomAccessReadBuffer.new(byte_array)
      data_stream = RandomAccessReadDataStream.new(random_access_read_buffer)
      value = data_stream.read
      while value > -1
        value = data_stream.read
      end
      # Should not raise ArrayIndexOutOfBoundsException
      # In Crystal, we don't have ArrayIndexOutOfBoundsException, but IndexError
      # The test expects no exception
      data_stream.close
    end

    it "test_eof_unsigned_short" do
      byte_array = Bytes.new(3)
      random_access_read_buffer = Pdfbox::IO::RandomAccessReadBuffer.new(byte_array)
      data_stream = RandomAccessReadDataStream.new(random_access_read_buffer)
      data_stream.read_unsigned_short
      expect_raises(IO::EOFError) do
        data_stream.read_unsigned_short
      end
      data_stream.close
    end

    it "test_eof_unsigned_int" do
      byte_array = Bytes.new(5)
      random_access_read_buffer = Pdfbox::IO::RandomAccessReadBuffer.new(byte_array)
      data_stream = RandomAccessReadDataStream.new(random_access_read_buffer)
      data_stream.read_unsigned_int
      expect_raises(IO::EOFError) do
        data_stream.read_unsigned_int
      end
      data_stream.close
    end

    it "test_eof_unsigned_byte" do
      byte_array = Bytes.new(2)
      random_access_read_buffer = Pdfbox::IO::RandomAccessReadBuffer.new(byte_array)
      data_stream = RandomAccessReadDataStream.new(random_access_read_buffer)
      data_stream.read_unsigned_byte
      data_stream.read_unsigned_byte
      expect_raises(IO::EOFError) do
        data_stream.read_unsigned_byte
      end
      data_stream.close
    end

    it "test_double_close" do
      # TODO: Need RandomAccessReadBufferedFile equivalent
      # For now, use MemoryRandomAccessRead
      byte_array = Bytes.new(100)
      random_access_read = Pdfbox::IO::RandomAccessReadBuffer.new(byte_array)
      data_stream = RandomAccessReadDataStream.new(random_access_read)
      data_stream.close
      # Should not raise on double close
      data_stream.close
    end

    it "ensure_read_finishes" do
      content = "1234567890"
      byte_array = content.to_slice
      random_access_read = Pdfbox::IO::RandomAccessReadBuffer.new(byte_array)
      read_buffer = Bytes.new(2)
      data_stream = RandomAccessReadDataStream.new(random_access_read)
      amount_read = 0
      total_amount_read = 0
      while (amount_read = data_stream.read(read_buffer, 0, 2)) != -1
        total_amount_read += amount_read
      end
      total_amount_read.should eq 10
      data_stream.close
    end

    it "test_read_buffer" do
      content = "012345678A012345678B012345678C012345678D"
      byte_array = content.to_slice
      random_access_read = Pdfbox::IO::RandomAccessReadBuffer.new(byte_array)
      read_buffer = Bytes.new(40)
      data_stream = RandomAccessReadDataStream.new(random_access_read)

      count = 4
      bytes_read = data_stream.read(read_buffer, 0, count)
      data_stream.get_current_position.should eq 4
      bytes_read.should eq count
      String.new(read_buffer[0, count]).should eq "0123"

      count = 6
      bytes_read = data_stream.read(read_buffer, 0, count)
      data_stream.get_current_position.should eq 10
      bytes_read.should eq count
      String.new(read_buffer[0, count]).should eq "45678A"

      count = 10
      bytes_read = data_stream.read(read_buffer, 0, count)
      data_stream.get_current_position.should eq 20
      bytes_read.should eq count
      String.new(read_buffer[0, count]).should eq "012345678B"

      count = 10
      bytes_read = data_stream.read(read_buffer, 0, count)
      data_stream.get_current_position.should eq 30
      bytes_read.should eq count
      String.new(read_buffer[0, count]).should eq "012345678C"

      count = 10
      bytes_read = data_stream.read(read_buffer, 0, count)
      data_stream.get_current_position.should eq 40
      bytes_read.should eq count
      String.new(read_buffer[0, count]).should eq "012345678D"

      data_stream.read.should eq -1

      data_stream.seek(0)
      data_stream.read(read_buffer, 0, 7)
      data_stream.get_current_position.should eq 7

      count = 16
      bytes_read = data_stream.read(read_buffer, 0, count)
      data_stream.get_current_position.should eq 23
      bytes_read.should eq count
      String.new(read_buffer[0, count]).should eq "78A012345678B012"

      bytes_read = data_stream.read(read_buffer, 0, 99)
      data_stream.get_current_position.should eq 40
      bytes_read.should eq 17
      String.new(read_buffer[0, 17]).should eq "345678C012345678D"

      data_stream.read.should eq -1

      data_stream.seek(0)
      data_stream.read(read_buffer, 0, 7)
      data_stream.get_current_position.should eq 7

      count = 23
      bytes_read = data_stream.read(read_buffer, 0, count)
      data_stream.get_current_position.should eq 30
      bytes_read.should eq count
      String.new(read_buffer[0, count]).should eq "78A012345678B012345678C"

      data_stream.seek(0)
      data_stream.read(read_buffer, 0, 10)
      data_stream.get_current_position.should eq 10
      count = 23
      bytes_read = data_stream.read(read_buffer, 0, count)
      data_stream.get_current_position.should eq 33
      bytes_read.should eq count
      String.new(read_buffer[0, count]).should eq "012345678B012345678C012"

      data_stream.close
    end
  end
end

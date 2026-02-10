require "../../spec_helper"

module Fontbox::CFF
  describe DataInput do
    it "test_read_bytes" do
      data = Bytes[0, 255, 2, 253, 4, 251, 6, 249, 8, 247] # signed: 0, -1, 2, -3, 4, -5, 6, -7, 8, -9
      data_input = DataInputByteArray.new(data)
      expect_raises(Exception) { data_input.read_bytes(20) }
      data_input.read_bytes(1).should eq Bytes[0]
      data_input.read_bytes(3).should eq Bytes[255, 2, 253]
      data_input.position = 6
      data_input.read_bytes(3).should eq Bytes[6, 249, 8]
      expect_raises(Exception) { data_input.read_bytes(-1) }
      expect_raises(Exception) { data_input.read_bytes(5) }
    end

    it "test_read_byte" do
      data = Bytes[0, 255, 2, 253, 4, 251, 6, 249, 8, 247]
      data_input = DataInputByteArray.new(data)
      data_input.read_byte.should eq 0
      data_input.read_byte.should eq -1 # signed -1
      data_input.position = 6
      data_input.read_byte.should eq 6
      data_input.read_byte.should eq -7 # signed -7
      data_input.position = data_input.length - 1
      data_input.read_byte.should eq -9 # signed -9
      expect_raises(Exception) { data_input.read_byte }
    end

    it "test_read_unsigned_byte" do
      data = Bytes[0, 255, 2, 253, 4, 251, 6, 249, 8, 247]
      data_input = DataInputByteArray.new(data)
      data_input.read_unsigned_byte.should eq 0
      data_input.read_unsigned_byte.should eq 255
      data_input.position = 6
      data_input.read_unsigned_byte.should eq 6
      data_input.read_unsigned_byte.should eq 249
      data_input.position = data_input.length - 1
      data_input.read_unsigned_byte.should eq 247
      expect_raises(Exception) { data_input.read_unsigned_byte }
    end

    it "test_basics" do
      data = Bytes[0, 255, 2, 253, 4, 251, 6, 249, 8, 247]
      data_input = DataInputByteArray.new(data)
      data_input.length.should eq 10
      data_input.has_remaining?.should be_true
      expect_raises(Exception) { data_input.position = -1 }
      length = data_input.length
      expect_raises(Exception) { data_input.position = length }
    end

    it "test_peek" do
      data = Bytes[0, 255, 2, 253, 4, 251, 6, 249, 8, 247]
      data_input = DataInputByteArray.new(data)
      data_input.peek_unsigned_byte(0).should eq 0
      data_input.peek_unsigned_byte(5).should eq 251
      expect_raises(Exception) { data_input.peek_unsigned_byte(-1) }
      length = data_input.length
      expect_raises(Exception) { data_input.peek_unsigned_byte(length) }
    end

    it "test_read_short" do
      data = Bytes[0x00, 0x0F, 0xAA, 0, 0xFE, 0xFF]
      data_input = DataInputByteArray.new(data)
      data_input.read_short.should eq 0x000F
      data_input.read_short.should eq -22016 # 0xAA00 as signed short
      data_input.read_short.should eq -257   # 0xFEFF as signed short
      expect_raises(Exception) { data_input.read_short }
    end

    it "test_read_unsigned_short" do
      data = Bytes[0x00, 0x0F, 0xAA, 0, 0xFE, 0xFF]
      data_input = DataInputByteArray.new(data)
      data_input.read_unsigned_short.should eq 0x000F
      data_input.read_unsigned_short.should eq 0xAA00
      data_input.read_unsigned_short.should eq 0xFEFF
      expect_raises(Exception) { data_input.read_unsigned_short }

      data2 = Bytes[0x00]
      data_input2 = DataInputByteArray.new(data2)
      expect_raises(Exception) { data_input2.read_unsigned_short }
    end

    it "test_read_int" do
      data = Bytes[0x00, 0x0F, 0xAA, 0, 0xFE, 0xFF, 0x30, 0x50]
      data_input = DataInputByteArray.new(data)
      data_input.read_int.should eq 0x000FAA00
      data_input.read_int.should eq -16830384 # 0xFEFF3050 as signed int
      expect_raises(Exception) { data_input.read_int }

      data2 = Bytes[0x00, 0x0F, 0xAA]
      data_input2 = DataInputByteArray.new(data2)
      expect_raises(Exception) { data_input2.read_int }
    end
  end
end

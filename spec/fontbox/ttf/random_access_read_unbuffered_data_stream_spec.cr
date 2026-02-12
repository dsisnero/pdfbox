require "../../spec_helper"

module Fontbox::TTF
  describe RandomAccessReadUnbufferedDataStream do
    it "test_create_sub_view" do
      random_access_read = Pdfbox::IO::RandomAccessReadBuffer.new("0123456789".to_slice)
      data_stream = RandomAccessReadUnbufferedDataStream.new(random_access_read)
      data_stream.seek(2)

      sub_view = data_stream.create_sub_view(3)
      sub_view.should_not be_nil
      view = sub_view || raise "expected sub view"
      view.read.should eq('2'.ord.to_u8)
      view.read.should eq('3'.ord.to_u8)
      view.read.should eq('4'.ord.to_u8)
      view.read.should be_nil

      data_stream.current_position.should eq(2)
      data_stream.close
    end

    it "test_original_data" do
      random_access_read = Pdfbox::IO::RandomAccessReadBuffer.new("0123456789".to_slice)
      data_stream = RandomAccessReadUnbufferedDataStream.new(random_access_read)
      original = data_stream.original_data

      original.gets_to_end.should eq("0123456789")
      data_stream.close
    end
  end
end

require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/io/src/test/java/org/apache/pdfbox/io/TestIOUtils.java
describe Pdfbox::IO::Utils do
  it "matches TestIOUtils#testPopulateBuffer" do
    data = "Hello World!".to_slice
    buffer = Bytes.new(data.size)
    count = Pdfbox::IO::Utils.populate_buffer(::IO::Memory.new(data), buffer)
    count.should eq(12)

    # Buffer too small
    buffer = Bytes.new(data.size - 2)
    input = ::IO::Memory.new(data)
    count = Pdfbox::IO::Utils.populate_buffer(input, buffer)
    count.should eq(10)
    left_over = input.getb_to_end
    left_over.size.should eq(2)

    # Buffer too big
    buffer = Bytes.new(data.size + 2)
    input = ::IO::Memory.new(data)
    count = Pdfbox::IO::Utils.populate_buffer(input, buffer)
    count.should eq(12)
    input.read_byte.should be_nil # EOD reached
  end
end

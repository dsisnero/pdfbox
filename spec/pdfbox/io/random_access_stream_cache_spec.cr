require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/io/src/main/java/org/apache/pdfbox/io/RandomAccessWrite.java
#   vendor/pdfbox/io/src/main/java/org/apache/pdfbox/io/RandomAccessOutputStream.java
#   vendor/pdfbox/io/src/main/java/org/apache/pdfbox/io/RandomAccessStreamCache.java
#   vendor/pdfbox/io/src/main/java/org/apache/pdfbox/io/RandomAccessStreamCacheImpl.java
# Upstream has no dedicated tests; this is a characterization spec.
module Pdfbox
  module IO
    describe RandomAccessWrite do
      it "is implemented by RandomAccessReadWriteBuffer" do
        buffer = RandomAccessReadWriteBuffer.new
        writer = buffer.as(RandomAccessWrite)

        writer.write(1)
        writer.write(Bytes[2, 3])
        writer.write(Bytes[9, 4, 5], 1, 2)

        buffer.seek(0)
        bytes = Bytes.new(5)
        buffer.read(bytes).should eq(5)
        bytes.should eq(Bytes[1, 2, 3, 4, 5])

        writer.clear
        buffer.length.should eq(0)
      end
    end

    describe RandomAccessOutputStream do
      it "writes bytes to the underlying random access writer" do
        buffer = RandomAccessReadWriteBuffer.new
        stream = RandomAccessOutputStream.new(buffer)

        stream.write(Bytes[1, 2, 3])
        stream.write_byte(4_u8)

        buffer.seek(0)
        bytes = Bytes.new(4)
        buffer.read(bytes).should eq(4)
        bytes.should eq(Bytes[1, 2, 3, 4])
      end

      it "is write-only" do
        stream = RandomAccessOutputStream.new(RandomAccessReadWriteBuffer.new)
        expect_raises(::IO::Error) { stream.read(Bytes.new(1)) }
      end
    end

    describe RandomAccessStreamCacheImpl do
      it "creates memory-backed random access buffers" do
        cache = RandomAccessStreamCacheImpl.new
        buffer = cache.create_buffer

        buffer.should be_a(RandomAccessReadWriteBuffer)
        buffer.write(Bytes[1, 2, 3])
        buffer.length.should eq(3)

        cache.close
      end

      it "is produced by the stream cache create function" do
        create = RandomAccessStreamCache::StreamCacheCreateFunction.new do
          RandomAccessStreamCacheImpl.new
        end

        cache = create.call
        cache.should be_a(RandomAccessStreamCacheImpl)
        cache.create_buffer.should be_a(RandomAccessReadWriteBuffer)
      end
    end
  end
end

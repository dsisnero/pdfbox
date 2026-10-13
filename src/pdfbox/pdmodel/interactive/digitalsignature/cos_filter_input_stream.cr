module Pdfbox::Pdmodel::Interactive::DigitalSignature
  # A filtered stream that includes the bytes within the (begin, length) intervals
  # passed to the constructor. Corresponds to COSFilterInputStream in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/COSFilterInputStream.java
  class COSFilterInputStream < ::IO
    @ranges : Array(Tuple(Int32, Int32))
    @range : Int32
    @position : Int64

    # Wraps an InputStream, using the given even-sized array of (begin, length) pairs.
    def initialize(@source : ::IO, byte_range : ::Array(Int32))
      @ranges = Array(Tuple(Int32, Int32)).new(byte_range.size // 2)
      @range = -1
      @position = 0_i64
      i = 0
      while i < byte_range.size // 2
        start = byte_range[i * 2]
        @ranges << {start, start + byte_range[i * 2 + 1]}
        i += 1
      end
    end

    def initialize(source : Bytes, byte_range : ::Array(Int32))
      initialize(::IO::Memory.new(source), byte_range)
    end

    def read(slice : Bytes) : Int32
      return 0 if slice.empty?
      if (@range == -1 || remaining <= 0) && !next_range
        return 0 # EOF
      end

      length = Math.min(slice.size.to_i64, remaining).to_i32
      bytes_read = @source.read(slice[0, length])
      @position += bytes_read
      bytes_read
    end

    # Reads the whole filtered content into a byte array (Java toByteArray).
    def to_byte_array : Bytes
      io = ::IO::Memory.new
      ::IO.copy(self, io)
      io.to_slice
    end

    def write(slice : Bytes) : Nil
      raise ::IO::Error.new("Not writable")
    end

    private def remaining : Int64
      @ranges[@range][1].to_i64 - @position
    end

    private def next_range : Bool
      if @range + 1 < @ranges.size
        @range += 1
        while @position < @ranges[@range][0]
          length = Math.min(@ranges[@range][0] - @position, 8192_i64).to_i32
          buffer = Bytes.new(length)
          skipped = @source.read(buffer)
          if skipped == 0
            raise ::IO::Error.new("skip() returns 0, range: #{@ranges[@range]}")
          end
          @position += skipped
        end
        true
      else
        false
      end
    end
  end
end

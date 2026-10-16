module Pdfbox::Filter
  # Decodes data encoded in an ASCII base-85 representation, reproducing the
  # original binary data.
  # Port of org.apache.pdfbox.filter.ASCII85Filter.
  class ASCII85Filter < Filter
    def encode(input : Bytes) : Bytes
      output = ::IO::Memory.new
      os = ASCII85OutputStream.new(output)
      os.write(input)
      os.flush
      output.to_slice
    end

    def decode(encoded : Bytes) : Bytes
      output = ::IO::Memory.new
      is = ASCII85InputStream.new(::IO::Memory.new(encoded))
      ::IO.copy(is, output)
      output.to_slice
    end
  end

  # This class represents an ASCII85 output stream.
  # Port of org.apache.pdfbox.filter.ASCII85OutputStream.
  class ASCII85OutputStream < ::IO
    OFFSET   = '!'.ord.to_u8
    NEWLINE  = '\n'.ord.to_u8
    Z        = 'z'.ord.to_u8
    GREATER  = '>'.ord.to_u8
    TERM_MAX = 126
    TERM_MIN = 118

    @line_break : Int32
    @count : Int32
    @in_data : Bytes
    @out_data : Bytes
    @maxline : Int32
    @flushed : Bool
    @terminator : Char
    @out : ::IO

    def initialize(@out : ::IO)
      @line_break = 36 * 2
      @maxline = 36 * 2
      @count = 0
      @in_data = Bytes.new(4, 0_u8)
      @out_data = Bytes.new(5, 0_u8)
      @flushed = true
      @terminator = '~'
    end

    # Sets the terminating character.
    def terminator=(term : Char) : Char
      if term.ord < TERM_MIN || term.ord > TERM_MAX || term == 'z'
        raise ArgumentError.new("Terminator must be 118-126 excluding z")
      end
      @terminator = term
    end

    # Gets the terminating character.
    def terminator : Char
      @terminator
    end

    # Sets the line length that will be used.
    def line_length=(l : Int32) : Int32
      @line_break = l if @line_break > l
      @maxline = l
    end

    # Gets the length of the line.
    def line_length : Int32
      @maxline
    end

    def read(slice : Bytes) : Int32
      raise ::IO::Error.new("ASCII85OutputStream is write-only")
    end

    def write(slice : Bytes) : Nil
      slice.each { |byte| write_byte(byte) }
    end

    def write_byte(byte : UInt8) : Nil
      @flushed = false
      @in_data[@count] = byte
      @count += 1
      return if @count < 4

      transform_ascii85
      i = 0
      while i < 5
        break if @out_data[i] == 0

        @out.write_byte(@out_data[i])
        @line_break -= 1
        if @line_break == 0
          @out.write_byte(NEWLINE)
          @line_break = @maxline
        end
        i += 1
      end
      @count = 0
    end

    def flush : Nil
      return if @flushed

      if @count > 0
        i = @count
        while i < 4
          @in_data[i] = 0_u8
          i += 1
        end
        transform_ascii85
        if @out_data[0] == Z
          i = 0
          while i < 5 # expand 'z'
            @out_data[i] = OFFSET
            i += 1
          end
        end
        i = 0
        while i < @count + 1
          @out.write_byte(@out_data[i])
          @line_break -= 1
          if @line_break == 0
            @out.write_byte(NEWLINE)
            @line_break = @maxline
          end
          i += 1
        end
      end

      @line_break -= 1
      @out.write_byte(NEWLINE) if @line_break == 0
      @out.write_byte(@terminator.ord.to_u8)
      @out.write_byte(GREATER)
      @out.write_byte(NEWLINE)
      @count = 0
      @line_break = @maxline
      @flushed = true
    end

    def close : Nil
      flush
      @out.close
    end

    # Transforms the next four ascii bytes.
    private def transform_ascii85 : Nil
      word = ((((@in_data[0].to_i64 << 8) | @in_data[1].to_i64) << 16) |
              (@in_data[2].to_i64 << 8) | @in_data[3].to_i64) & 0xFFFFFFFF_i64

      if word == 0
        @out_data[0] = Z
        @out_data[1] = 0_u8
        return
      end

      x = word // (85_i64 * 85_i64 * 85_i64 * 85_i64)
      @out_data[0] = (x + OFFSET).to_u8
      word -= x * 85_i64 * 85_i64 * 85_i64 * 85_i64

      x = word // (85_i64 * 85_i64 * 85_i64)
      @out_data[1] = (x + OFFSET).to_u8
      word -= x * 85_i64 * 85_i64 * 85_i64

      x = word // (85_i64 * 85_i64)
      @out_data[2] = (x + OFFSET).to_u8
      word -= x * 85_i64 * 85_i64

      x = word // 85_i64
      @out_data[3] = (x + OFFSET).to_u8

      @out_data[4] = ((word % 85_i64) + OFFSET).to_u8
    end
  end

  # This class represents an ASCII85 input stream.
  # Port of org.apache.pdfbox.filter.ASCII85InputStream.
  class ASCII85InputStream < ::IO
    TERMINATOR = '~'.ord.to_u8
    OFFSET     = '!'.ord.to_u8
    NEWLINE    = '\n'.ord.to_u8
    RETURN     = '\r'.ord.to_u8
    SPACE      = ' '.ord.to_u8
    PADDING_U  = 'u'.ord.to_u8
    Z          = 'z'.ord.to_u8

    @index : Int32
    @n : Int32
    @eof : Bool
    @ascii : Bytes
    @b : Bytes
    @in : ::IO

    def initialize(@in : ::IO)
      @index = 0
      @n = 0
      @eof = false
      @ascii = Bytes.new(5, 0_u8)
      @b = Bytes.new(4, 0_u8)
    end

    def read(slice : Bytes) : Int32
      return 0 if @eof && @index >= @n

      i = 0
      while i < slice.size
        if @index < @n
          slice[i] = @b[@index]
          @index += 1
        else
          byte = read_byte
          return i if byte.nil?

          slice[i] = byte
        end
        i += 1
      end
      slice.size
    end

    def write(slice : Bytes) : Nil
      raise ::IO::Error.new("ASCII85InputStream is read-only")
    end

    # Java InputStream#skip is unsupported and does nothing.
    def skip(bytes_count : Int) : Nil
    end

    def close : Nil
      @eof = true
      @in.close
    end

    def read_byte : UInt8?
      if @index >= @n
        return nil if @eof

        @index = 0
        z = 0_u8
        loop do
          zz = @in.read_byte
          if zz.nil?
            @eof = true
            return nil
          end
          z = zz
          break unless z == NEWLINE || z == RETURN || z == SPACE
        end

        if z == TERMINATOR
          @eof = true
          @n = 0
          return nil
        elsif z == Z
          @b[0] = 0_u8
          @b[1] = 0_u8
          @b[2] = 0_u8
          @b[3] = 0_u8
          @n = 4
        else
          @ascii[0] = z # may be EOF here
          k = 1
          while k < 5
            loop do
              zz = @in.read_byte
              if zz.nil?
                @eof = true
                return nil
              end
              z = zz
              break unless z == NEWLINE || z == RETURN || z == SPACE
            end
            @ascii[k] = z
            if z == TERMINATOR
              # don't include ~ as padding byte
              @ascii[k] = PADDING_U
              break
            end
            k += 1
          end
          @n = k - 1
          if @n == 0
            @eof = true
            return nil
          end
          if k < 5
            k += 1
            while k < 5
              # use 'u' for padding
              @ascii[k] = PADDING_U
              k += 1
            end
            @eof = true
          end

          t = 0_i64
          k = 0
          while k < 5
            z = (@ascii[k].to_i32 - OFFSET.to_i32)
            if z < 0 || z > 93
              @n = 0
              @eof = true
              raise ::IO::Error.new("Invalid data in Ascii85 stream")
            end
            t = (t * 85_i64) + z
            k += 1
          end
          k = 3
          while k >= 0
            @b[k] = (t & 0xFF_i64).to_u8
            t >>= 8
            k -= 1
          end
        end
      end

      byte = @b[@index]
      @index += 1
      byte
    end
  end
end

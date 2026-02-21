# I/O utilities for PDFBox Crystal
#
# This module contains I/O utilities for PDF processing,
# corresponding to the io module in Apache PDFBox.
module Pdfbox::IO
  # I/O utility functions
  module Utils
    # Copy data from one IO to another
    def self.copy(input : ::IO, output : ::IO, buffer_size : Int = 8192) : Int64
      total = 0_i64
      buffer = Bytes.new(buffer_size)

      while (read = input.read(buffer)) > 0
        output.write(buffer[0, read])
        total += read
      end

      total
    end

    # Read all bytes from an IO
    def self.to_byte_array(io : ::IO) : Bytes
      io.rewind if io.responds_to?(:rewind)
      buffer = ::IO::Memory.new
      copy(io, buffer)
      buffer.to_slice
    end

    # Read all text from an IO with given encoding
    def self.to_string(io : ::IO, encoding : String = "UTF-8") : String
      io.rewind if io.responds_to?(:rewind)
      ::String.new(to_byte_array(io), encoding)
    end

    # Close an IO resource silently (ignore errors)
    def self.close_quietly(io : ::IO?) : Nil
      io.try(&.close)
    rescue
      # Ignore close errors
    end

    # Close multiple IO resources silently
    def self.close_quietly(ios : Enumerable(::IO?)) : Nil
      ios.each { |io| close_quietly(io) }
    end
  end

  # Random access read interface (similar to Java RandomAccessRead)
  abstract class RandomAccessRead
    @closed = false

    # Get current position
    abstract def position : Int64

    # Get total length
    abstract def length : Int64

    # Seek to position
    abstract def seek(position : Int64) : Nil

    # Skip forward n bytes (positive) or backward (negative)
    def skip(n : Int64) : Nil
      seek(position + n)
    end

    # Read byte at current position and advance
    abstract def read : UInt8?

    # Read bytes into buffer
    abstract def read(buffer : Bytes) : Int32

    # Read bytes into buffer at offset (similar to Java RandomAccessRead.read(byte[], int, int))
    def read(buffer : Bytes, offset : Int32, length : Int32) : Int32
      raise "Invalid offset #{offset} or length #{length} for buffer size #{buffer.size}" if offset < 0 || length < 0 || offset + length > buffer.size
      slice = buffer[offset, length]
      read(slice)
    end

    # Read fully into buffer, raising EOFError if not enough bytes
    def read_fully(buffer : Bytes) : Nil
      read_fully(buffer, 0, buffer.size)
    end

    # Read fully into buffer at offset, raising EOFError if not enough bytes
    def read_fully(buffer : Bytes, offset : Int32, length : Int32) : Nil
      raise "Invalid offset #{offset} or length #{length} for buffer size #{buffer.size}" if offset < 0 || length < 0 || offset + length > buffer.size
      total_read = 0
      while total_read < length
        slice = buffer[offset + total_read, length - total_read]
        bytes_read = read(slice)
        raise ::IO::EOFError.new if bytes_read == 0
        total_read += bytes_read
      end
    end

    # Read byte at position without advancing
    abstract def peek : UInt8?

    # Check if at end of stream
    abstract def eof? : Bool

    # Check if the resource is closed
    def closed? : Bool
      @closed
    end

    # Raise if the resource is closed
    protected def check_closed : Nil
      raise ::IO::Error.new("RandomAccessRead already closed") if closed?
    end

    # Close the resource (if needed)
    def close : Nil
      @closed = true
    end

    # Rewind to beginning
    def rewind : Nil
      seek(0)
    end

    # Seek backwards the given number of bytes
    def rewind(bytes : Int32) : Nil
      seek(position - bytes)
    end

    # Read all remaining bytes
    def read_all : Bytes
      buffer = Bytes.new(length - position)
      read(buffer)
      buffer
    end

    # Create a view of a portion of this RandomAccessRead
    def create_view(start_position : Int64, stream_length : Int64) : RandomAccessRead
      RandomAccessReadView.new(self, start_position, stream_length)
    end
  end

  # Random access read implementation using ::IO::Memory
  # Corresponds to RandomAccessReadBuffer in Apache PDFBox
  class RandomAccessReadBuffer < RandomAccessRead
    @io : ::IO::Memory

    def initialize(data : Bytes | String = Bytes.empty)
      @io = ::IO::Memory.new(data)
    end

    # Create a RandomAccessReadBuffer from an IO stream, reading all data into memory
    def initialize(io : ::IO)
      @io = ::IO::Memory.new(io.gets_to_end.to_slice)
    end

    # Create a RandomAccessReadBuffer from an IO stream (static factory method)
    def self.create_buffer_from_stream(io : ::IO) : RandomAccessReadBuffer
      new(io)
    end

    def position : Int64
      check_closed
      @io.pos.to_i64
    end

    def length : Int64
      check_closed
      @io.size.to_i64
    end

    def seek(position : Int64) : Nil
      check_closed
      if position < 0
        raise "Invalid position #{position}"
      end
      @io.pos = Math.min(position, length)
    end

    def read : UInt8?
      check_closed
      byte = @io.read_byte
      byte.nil? ? nil : byte
    end

    def read(buffer : Bytes) : Int32
      check_closed
      @io.read(buffer)
    end

    def peek : UInt8?
      check_closed
      slice = @io.peek
      slice.nil? ? nil : slice.first?
    end

    def eof? : Bool
      check_closed
      @io.pos >= @io.size
    end

    def close : Nil
      super
      @io.close
    end

    # Use an independent reader so view reads don't move this reader's cursor.
    def create_view(start_position : Int64, stream_length : Int64) : RandomAccessRead
      RandomAccessReadView.new(RandomAccessReadBuffer.new(@io.to_slice), start_position, stream_length)
    end
  end

  # Alias for backward compatibility
  alias MemoryRandomAccessRead = RandomAccessReadBuffer

  # Random access read implementation using ::File
  # Corresponds to RandomAccessReadBufferedFile in Apache PDFBox
  class RandomAccessReadBufferedFile < RandomAccessRead
    @file : ::File
    @filename : String

    def initialize(filename : String)
      @filename = filename
      @file = ::File.open(filename, "r")
    end

    def initialize(path : Path)
      initialize(path.to_s)
    end

    def position : Int64
      check_closed
      @file.pos.to_i64
    end

    def length : Int64
      check_closed
      @file.size.to_i64
    end

    def seek(position : Int64) : Nil
      check_closed
      if position < 0
        raise "Invalid position #{position}"
      end
      @file.pos = Math.min(position, length)
    end

    def read : UInt8?
      check_closed
      byte = @file.read_byte
      byte.nil? ? nil : byte
    end

    def read(buffer : Bytes) : Int32
      check_closed
      @file.read(buffer)
    end

    def peek : UInt8?
      check_closed
      current_pos = @file.pos
      byte = read
      @file.pos = current_pos
      byte
    end

    def eof? : Bool
      check_closed
      @file.pos >= @file.size
    end

    def close : Nil
      super
      @file.close
    end

    def finalize
      @file.close
    end

    # Use an independent file reader so view reads don't move this reader's cursor.
    def create_view(start_position : Int64, stream_length : Int64) : RandomAccessRead
      RandomAccessReadView.new(RandomAccessReadBufferedFile.new(@filename), start_position, stream_length)
    end
  end

  # Alias for backward compatibility
  alias FileRandomAccessRead = RandomAccessReadBufferedFile

  # Random access read view that provides a window into another RandomAccessRead
  # Similar to RandomAccessReadView in Apache PDFBox
  class RandomAccessReadView < RandomAccessRead
    @source : RandomAccessRead
    @start_position : Int64
    @stream_length : Int64
    @current_position : Int64 = 0

    def initialize(@source : RandomAccessRead, @start_position : Int64, @stream_length : Int64)
    end

    def position : Int64
      @current_position
    end

    def length : Int64
      @stream_length
    end

    def seek(position : Int64) : Nil
      check_closed
      if position < 0
        raise "Invalid position #{position}"
      end
      # Seek within the view bounds
      actual_position = @start_position + Math.min(position, @stream_length)
      @source.seek(actual_position)
      @current_position = Math.min(position, @stream_length)
    end

    def read : UInt8?
      check_closed
      if eof?
        return
      end
      # Ensure we're at the correct position in the source
      @source.seek(@start_position + @current_position)
      byte = @source.read
      if byte
        @current_position += 1
      end
      byte
    end

    def read(buffer : Bytes) : Int32
      check_closed
      if eof?
        return 0
      end
      # Calculate max bytes we can read
      max_bytes = (@stream_length - @current_position).to_i32
      return 0 if max_bytes <= 0

      bytes_to_read = Math.min(buffer.size, max_bytes)
      # Seek to correct position in source
      @source.seek(@start_position + @current_position)
      bytes_read = @source.read(buffer[0, bytes_to_read])
      @current_position += bytes_read if bytes_read > 0
      bytes_read
    end

    def peek : UInt8?
      check_closed
      if eof?
        return
      end
      @source.seek(@start_position + @current_position)
      @source.peek
    end

    def eof? : Bool
      check_closed
      @current_position >= @stream_length
    end

    def close : Nil
      super
    end
  end

  # Wrapper around RandomAccessRead that exposes an IO-like input stream.
  # This stream keeps an independent cursor from the wrapped reader.
  class RandomAccessInputStream
    @input : RandomAccessRead
    @position : Int64

    def initialize(@input : RandomAccessRead)
      @position = 0_i64
    end

    def available : Int32
      remaining = @input.length - @position
      return 0 if remaining <= 0
      max = Int32::MAX.to_i64
      Math.min(remaining, max).to_i32
    end

    def read : UInt8?
      restore_position
      return if @input.eof?
      byte = @input.read
      @position += 1_i64 if byte
      byte
    end

    def read(buffer : Bytes) : Int32
      read(buffer, 0, buffer.size)
    end

    def read(buffer : Bytes, offset : Int32, length : Int32) : Int32
      raise "Invalid offset #{offset} or length #{length} for buffer size #{buffer.size}" if offset < 0 || length < 0 || offset + length > buffer.size
      return 0 if length == 0

      restore_position
      return -1 if @input.eof?

      bytes_read = @input.read(buffer, offset, length)
      if bytes_read > 0
        @position += bytes_read
      end
      bytes_read
    end

    def skip(n : Int64) : Int64
      return 0_i64 if n <= 0
      restore_position
      @input.seek(@position + n)
      @position += n
      n
    end

    def close : Nil
      # Java RandomAccessInputStream does not close the wrapped RandomAccessRead.
    end

    private def restore_position : Nil
      @input.seek(@position)
    end
  end

  # Combines multiple RandomAccessRead instances into one logical input.
  class SequenceRandomAccessRead < RandomAccessRead
    @reader_list : Array(RandomAccessRead)
    @start_positions : Array(Int64)
    @end_positions : Array(Int64)
    @number_of_readers : Int32
    @current_index : Int32
    @current_position : Int64
    @total_length : Int64
    @current_reader : RandomAccessRead?

    def initialize(readers : Array(RandomAccessRead))
      raise ArgumentError.new("Missing input parameter") if readers.empty?

      reader_list = [] of RandomAccessRead
      begin
        reader_list = readers.select { |reader| reader.length > 0 }
      rescue ex
        raise ArgumentError.new("Problematic list")
      end
      raise ArgumentError.new("Empty list") if reader_list.empty?
      @reader_list = reader_list

      @number_of_readers = @reader_list.size
      @start_positions = Array(Int64).new(@number_of_readers, 0_i64)
      @end_positions = Array(Int64).new(@number_of_readers, 0_i64)
      @current_index = 0
      @current_position = 0_i64
      @total_length = 0_i64

      @number_of_readers.times do |i|
        @start_positions[i] = @total_length
        @total_length += @reader_list[i].length
        @end_positions[i] = @total_length - 1_i64
      end
      @current_reader = @reader_list[@current_index]
    end

    def position : Int64
      check_closed
      @current_position
    end

    def length : Int64
      check_closed
      @total_length
    end

    def seek(position : Int64) : Nil
      check_closed
      raise "Invalid position #{position}" if position < 0

      if position >= @total_length
        @current_index = @number_of_readers - 1
        @current_position = @total_length
      else
        increment = position < @current_position ? -1 : 1
        i = @current_index
        while i < @number_of_readers && i >= 0
          if position >= @start_positions[i] && position <= @end_positions[i]
            @current_index = i
            break
          end
          i += increment
        end
        @current_position = position
      end

      reader = @reader_list[@current_index]
      reader.seek(@current_position - @start_positions[@current_index])
      @current_reader = reader
    end

    def read : UInt8?
      check_closed
      reader = get_current_reader
      value = reader.read
      if value
        @current_position += 1_i64
      end
      value
    end

    def read(buffer : Bytes) : Int32
      check_closed
      return 0 if buffer.empty?

      max_available = Math.min(available, buffer.size)
      return 0 if max_available == 0

      reader = get_current_reader
      bytes_read = reader.read(buffer[0, max_available])
      while bytes_read > 0 && bytes_read < max_available
        reader = get_current_reader
        next_read = reader.read(buffer[bytes_read, max_available - bytes_read])
        break if next_read <= 0
        bytes_read += next_read
      end

      @current_position += bytes_read
      bytes_read
    end

    def peek : UInt8?
      check_closed
      return if eof?
      reader = get_current_reader
      reader.seek(@current_position - @start_positions[@current_index])
      reader.peek
    end

    def eof? : Bool
      check_closed
      @current_position >= @total_length
    end

    def close : Nil
      return if closed?
      @reader_list.each(&.close)
      @current_reader = nil
      super
    end

    def create_view(start_position : Int64, stream_length : Int64) : RandomAccessRead
      raise ::IO::Error.new("#{self.class.name}.create_view isn't supported.")
    end

    private def get_current_reader : RandomAccessRead
      reader = @current_reader
      raise ::IO::Error.new("RandomAccessBuffer already closed") if reader.nil?

      if reader.eof? && @current_index < @number_of_readers - 1
        @current_index += 1
        reader = @reader_list[@current_index]
        reader.seek(0_i64)
        @current_reader = reader
      end

      reader
    end

    private def available : Int32
      remaining = @total_length - @current_position
      return 0 if remaining <= 0
      max = Int32::MAX.to_i64
      Math.min(remaining, max).to_i32
    end
  end

  # Memory-mapped file reader API-compatible with Java class.
  # Current Crystal implementation delegates to buffered file access.
  class RandomAccessReadMemoryMappedFile < RandomAccessReadBufferedFile
  end

  # Random-access in-memory read/write buffer compatible with PDFBox API.
  class RandomAccessReadWriteBuffer < RandomAccessRead
    @io : ::IO::Memory
    @defined_chunk_size : Int32

    def initialize(defined_chunk_size : Int32 = 4096)
      @defined_chunk_size = defined_chunk_size
      @io = ::IO::Memory.new
    end

    def position : Int64
      check_closed
      @io.pos.to_i64
    end

    def length : Int64
      check_closed
      @io.size.to_i64
    end

    def seek(position : Int64) : Nil
      check_closed
      raise "Invalid position #{position}" if position < 0
      @io.pos = Math.min(position, length)
    end

    def read : UInt8?
      check_closed
      @io.read_byte
    end

    def read(buffer : Bytes) : Int32
      check_closed
      @io.read(buffer)
    end

    def peek : UInt8?
      check_closed
      slice = @io.peek
      slice.nil? ? nil : slice.first?
    end

    def eof? : Bool
      check_closed
      @io.pos >= @io.size
    end

    def write(value : Int32) : Nil
      check_closed
      @io.write_byte(value.to_u8)
    end

    def write(bytes : Bytes) : Nil
      check_closed
      @io.write(bytes)
    end

    def write(bytes : Bytes, offset : Int32, length : Int32) : Nil
      check_closed
      raise "Invalid offset #{offset} or length #{length} for buffer size #{bytes.size}" if offset < 0 || length < 0 || offset + length > bytes.size
      @io.write(bytes[offset, length])
    end

    def clear : Nil
      check_closed
      @io = ::IO::Memory.new
    end

    def close : Nil
      return if closed?
      super
      @io.close
    end
  end

  # RandomAccessRead implementation over a non-seekable stream with bounded rewind.
  class NonSeekableRandomAccessReadInputStream < RandomAccessRead
    BUFFER_SIZE = 4096
    CURRENT     =    0
    LAST        =    1
    NEXT        =    2

    @position : Int64 = 0_i64
    @current_buffer_pointer : Int32 = 0
    @size : Int64 = 0_i64
    @input : ::IO
    @buffers : Array(Bytes)
    @buffer_bytes : Array(Int32)
    @is_eof : Bool = false

    def initialize(@input : ::IO)
      @buffers = [Bytes.new(BUFFER_SIZE), Bytes.new(BUFFER_SIZE), Bytes.new(BUFFER_SIZE)]
      @buffer_bytes = [-1, -1, -1]
    end

    def position : Int64
      check_closed
      @position
    end

    def length : Int64
      check_closed
      @size
    end

    def seek(position : Int64) : Nil
      raise ::IO::Error.new("#{self.class.name}.seek isn't supported.")
    end

    def skip(n : Int64) : Nil
      return if n <= 0
      n.times { read }
    end

    def read : UInt8?
      check_closed
      return if eof?

      if @current_buffer_pointer >= @buffer_bytes[CURRENT] && !fetch
        @is_eof = true
        return
      end

      @position += 1_i64
      byte = @buffers[CURRENT][@current_buffer_pointer]
      @current_buffer_pointer += 1
      byte
    end

    def read(buffer : Bytes) : Int32
      check_closed
      return 0 if eof?

      number_of_bytes_read = 0
      requested_length = buffer.size
      while number_of_bytes_read < requested_length
        available = @buffer_bytes[CURRENT] - @current_buffer_pointer
        if available > 0
          bytes_to_copy = Math.min(requested_length - number_of_bytes_read, available)
          source = @buffers[CURRENT][@current_buffer_pointer, bytes_to_copy]
          destination = buffer[number_of_bytes_read, bytes_to_copy]
          destination.copy_from(source)
          @current_buffer_pointer += bytes_to_copy
          @position += bytes_to_copy
          number_of_bytes_read += bytes_to_copy
        elsif !fetch
          @is_eof = true
          break
        end
      end

      number_of_bytes_read
    end

    def peek : UInt8?
      check_closed
      return if eof?

      if @current_buffer_pointer >= @buffer_bytes[CURRENT] && !fetch
        @is_eof = true
        return
      end
      @buffers[CURRENT][@current_buffer_pointer]
    end

    def eof? : Bool
      check_closed
      @is_eof
    end

    def rewind(bytes : Int32) : Nil
      if @current_buffer_pointer >= bytes
        @current_buffer_pointer -= bytes
        @position -= bytes
      elsif @buffer_bytes[LAST] > 0
        remaining = bytes - @current_buffer_pointer
        switch_buffers(CURRENT, NEXT)
        switch_buffers(CURRENT, LAST)
        @buffer_bytes[LAST] = -1
        @current_buffer_pointer = @buffer_bytes[CURRENT] - remaining
        @position -= bytes
        @is_eof = false
      else
        raise ::IO::Error.new("not enough bytes available to perform the rewind operation")
      end
    end

    def create_view(start_position : Int64, stream_length : Int64) : RandomAccessRead
      raise ::IO::Error.new("#{self.class.name}.create_view isn't supported.")
    end

    def close : Nil
      return if closed?
      @input.close
      super
    end

    private def fetch : Bool
      check_closed
      @current_buffer_pointer = 0

      if @buffer_bytes[NEXT] > -1
        switch_buffers(CURRENT, LAST)
        switch_buffers(CURRENT, NEXT)
        @buffer_bytes[NEXT] = -1
        return true
      end

      if @buffer_bytes[LAST] == BUFFER_SIZE && @buffer_bytes[CURRENT] > 0 && @buffer_bytes[CURRENT] < BUFFER_SIZE
        current_bytes = @buffer_bytes[CURRENT]
        preserved_tail = Bytes.new(BUFFER_SIZE - current_bytes)
        preserved_tail.copy_from(@buffers[LAST][current_bytes, BUFFER_SIZE - current_bytes])
        @buffers[LAST][0, BUFFER_SIZE - current_bytes].copy_from(preserved_tail)
        @buffers[LAST][BUFFER_SIZE - current_bytes, current_bytes].copy_from(@buffers[CURRENT][0, current_bytes])
        @buffer_bytes[LAST] = BUFFER_SIZE
      else
        switch_buffers(CURRENT, LAST)
      end

      bytes_read = @input.read(@buffers[CURRENT])
      if bytes_read <= 0
        @buffer_bytes[CURRENT] = -1
        return false
      end
      @buffer_bytes[CURRENT] = bytes_read
      @size += bytes_read
      true
    end

    private def switch_buffers(first : Int32, second : Int32) : Nil
      tmp_buffer = @buffers[first]
      @buffers[first] = @buffers[second]
      @buffers[second] = tmp_buffer

      tmp_bytes = @buffer_bytes[first]
      @buffer_bytes[first] = @buffer_bytes[second]
      @buffer_bytes[second] = tmp_bytes
    end
  end
end

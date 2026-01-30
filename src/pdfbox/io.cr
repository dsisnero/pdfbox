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

    # Read byte at position without advancing
    abstract def peek : UInt8?

    # Check if at end of stream
    abstract def eof? : Bool

    # Close the resource (if needed)
    def close : Nil
      # Default implementation does nothing
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
  class MemoryRandomAccessRead < RandomAccessRead
    @io : ::IO::Memory

    def initialize(data : Bytes | String = Bytes.empty)
      @io = ::IO::Memory.new(data)
    end

    def position : Int64
      @io.pos.to_i64
    end

    def length : Int64
      @io.size.to_i64
    end

    def seek(position : Int64) : Nil
      @io.pos = position
    end

    def read : UInt8?
      byte = @io.read_byte
      byte.nil? ? nil : byte
    end

    def read(buffer : Bytes) : Int32
      @io.read(buffer)
    end

    def peek : UInt8?
      slice = @io.peek
      slice.nil? ? nil : slice.first?
    end

    def eof? : Bool
      @io.pos >= @io.size
    end

    def close : Nil
      @io.close
    end
  end

  # Random access read implementation using ::File
  class FileRandomAccessRead < RandomAccessRead
    @file : ::File

    def initialize(filename : String)
      @file = ::File.open(filename, "r")
    end

    def position : Int64
      @file.pos.to_i64
    end

    def length : Int64
      @file.size.to_i64
    end

    def seek(position : Int64) : Nil
      @file.pos = position
    end

    def read : UInt8?
      byte = @file.read_byte
      byte.nil? ? nil : byte
    end

    def read(buffer : Bytes) : Int32
      @file.read(buffer)
    end

    def peek : UInt8?
      current_pos = @file.pos
      byte = read
      @file.pos = current_pos
      byte
    end

    def eof? : Bool
      @file.pos >= @file.size
    end

    def close : Nil
      @file.close
    end

    def finalize
      @file.close
    end
  end

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
      if position < 0
        raise "Invalid position #{position}"
      end
      # Seek within the view bounds
      actual_position = @start_position + Math.min(position, @stream_length)
      @source.seek(actual_position)
      @current_position = Math.min(position, @stream_length)
    end

    def read : UInt8?
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
      if eof?
        return
      end
      @source.seek(@start_position + @current_position)
      @source.peek
    end

    def eof? : Bool
      @current_position >= @stream_length
    end
  end
end
